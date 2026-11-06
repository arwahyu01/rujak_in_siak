<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Shift;
use App\Models\SyncEvent;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;

class ReconcileShift
{
    public function __construct(
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

            if ($shift->status === Shift::STATUS_OPEN) {
                throw ApiException::conflict('SHIFT_STILL_OPEN', 'Shift harus ditutup sebelum direkonsiliasi.');
            }

            if (! $shift->closingSnapshot()->exists()) {
                throw ApiException::conflict('SHIFT_SNAPSHOT_MISSING', 'Closing snapshot shift tidak ditemukan.');
            }

            $unresolved = SyncEvent::query()
                ->where('device_id', $shift->device_id)
                ->whereIn('status', ['pending', 'blocked_dependency', 'conflict', 'rejected'])
                ->where(function ($query) use ($shift) {
                    $query->whereBetween('occurred_at', [$shift->opened_at, $shift->closed_at ?? now()])
                        ->orWhereNull('occurred_at');
                })
                ->count();

            $force = (bool) ($data['force'] ?? false);
            if ($unresolved > 0 && ! $force) {
                throw ApiException::conflict(
                    'SHIFT_SYNC_DEPENDENCY_UNRESOLVED',
                    'Masih terdapat event sinkronisasi yang belum selesai. Selesaikan terlebih dahulu atau gunakan override supervisor dengan catatan.',
                    ['unresolved_events' => $unresolved],
                );
            }

            if ($force && trim((string) ($data['resolution_note'] ?? '')) === '') {
                throw new ApiException('RECONCILE_NOTE_REQUIRED', 'Catatan rekonsiliasi wajib diisi untuk override.', 422);
            }

            if ($shift->status === Shift::STATUS_CLOSED_CONFIRMED && ! $force) {
                throw ApiException::conflict('SHIFT_ALREADY_RECONCILED', 'Shift sudah berstatus closed confirmed.');
            }

            $from = $shift->status;
            $shift->forceFill([
                'status' => Shift::STATUS_CLOSED_CONFIRMED,
                'pending_sync_count' => 0,
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
                    'status' => $shift->status,
                    'unresolved_events' => $unresolved,
                    'forced' => $force,
                    'resolution_note' => $data['resolution_note'] ?? null,
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
                    'status' => $shift->status,
                    'unresolved_events' => $unresolved,
                    'forced' => $force,
                    'resolution_note' => $data['resolution_note'] ?? null,
                    'approved_at' => $shift->approved_at?->toIso8601String(),
                ],
                $shift->business_id,
                $shift->outlet_id,
                $shift->device_id,
                aggregateVersion: 3,
            );

            return $shift->refresh()->load(['closingSnapshot', 'cashMovements', 'cashier', 'device', 'outlet']);
        });
    }
}
