<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\ShiftSyncCoordinator;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;

class ReconcileShift
{
    public function __construct(
        private readonly ShiftSyncCoordinator $coordinator,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(Shift $shift, array $data, User $actor): Shift
    {
        return DB::transaction(function () use ($shift, $data, $actor) {
            $shift = Shift::query()->lockForUpdate()->findOrFail($shift->id);

            if ((int) $shift->business_id !== (int) $actor->business_id) {
                throw ApiException::notFound('Shift tidak ditemukan.');
            }

            if (in_array($shift->status, [Shift::STATUS_OPEN, Shift::STATUS_CLOSING], true)) {
                throw ApiException::conflict('SHIFT_STILL_ACTIVE', 'Shift harus ditutup sebelum direkonsiliasi.');
            }

            if (! $shift->closingSnapshot()->exists()) {
                throw ApiException::conflict('SHIFT_SNAPSHOT_MISSING', 'Closing snapshot shift tidak ditemukan.');
            }

            if ($shift->status === Shift::STATUS_CLOSED_CONFIRMED) {
                throw ApiException::conflict('SHIFT_ALREADY_RECONCILED', 'Shift sudah berstatus closed confirmed.');
            }

            $force = (bool) ($data['force'] ?? false);
            $resolutionNote = trim((string) ($data['resolution_note'] ?? ''));
            if ($force && $resolutionNote === '') {
                throw new ApiException('RECONCILE_NOTE_REQUIRED', 'Catatan rekonsiliasi wajib diisi untuk override.', 422);
            }

            $unresolved = $this->coordinator->unresolvedAcrossParticipants($shift);

            if ($unresolved['count'] > 0 && ! $force) {
                throw ApiException::conflict(
                    'SHIFT_SYNC_DEPENDENCY_UNRESOLVED',
                    'Masih terdapat event sinkronisasi yang belum selesai pada shift ini. Selesaikan sinkronisasi atau gunakan override supervisor dengan catatan; override akan menandai shift sebagai closed_sync_exception, bukan closed_confirmed.',
                    [
                        'unresolved_events' => $unresolved['count'],
                        'events' => $unresolved['events'],
                    ],
                );
            }

            $from = $shift->status;
            $target = $force ? Shift::STATUS_CLOSED_SYNC_EXCEPTION : Shift::STATUS_CLOSED_CONFIRMED;

            $shift->forceFill([
                'status' => $target,
                'pending_sync_count' => $force ? $unresolved['count'] : 0,
                'closing_notes' => $resolutionNote !== ''
                    ? $resolutionNote
                    : $shift->closing_notes,
                'approved_by' => $actor->id,
                'approved_at' => now(),
            ])->save();

            $this->audit->record(
                'shift.reconciled',
                'shifts',
                'Rekonsiliasi shift '.$shift->uuid,
                $shift,
                ['status' => $from],
                [
                    'status' => $target,
                    'unresolved_events' => $unresolved['count'],
                    'forced' => $force,
                    'resolution_note' => $resolutionNote ?: null,
                ],
                $actor,
                $shift->business_id,
            );

            $this->sync->record(
                'shift.reconciled',
                'shift',
                $shift->uuid,
                [
                    'shift_uuid' => $shift->uuid,
                    'status' => $target,
                    'unresolved_events' => $unresolved['count'],
                    'forced' => $force,
                    'resolution_note' => $resolutionNote ?: null,
                    'approved_at' => $shift->approved_at?->toIso8601String(),
                ],
                $shift->business_id,
                $shift->outlet_id,
                $shift->closed_device_id ?? $shift->device_id,
                aggregateVersion: 3,
            );

            return $shift->refresh()->load([
                'cashier',
                'device',
                'outlet',
                'closedBy',
                'closedDevice',
                'closingRequestedBy',
                'closingRequestedDevice',
                'closingSnapshot',
                'cashMovements.createdBy',
                'participants.device',
                'participants.user',
            ]);
        });
    }
}
