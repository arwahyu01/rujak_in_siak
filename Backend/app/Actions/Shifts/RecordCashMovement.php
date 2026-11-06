<?php

namespace App\Actions\Shifts;

use App\Exceptions\ApiException;
use App\Models\Device;
use App\Models\Shift;
use App\Models\User;
use App\Services\AuditLogger;
use App\Services\ShiftSummaryService;
use App\Services\SyncRecorder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class RecordCashMovement
{
    public function __construct(
        private readonly ShiftSummaryService $summary,
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(Shift $shift, array $data, User $actor, Device $device): Shift
    {
        return DB::transaction(function () use ($shift, $data, $actor, $device) {
            $shift = Shift::query()->lockForUpdate()->findOrFail($shift->id);

            if ((int) $shift->business_id !== (int) $actor->business_id
                || (int) $shift->outlet_id !== (int) $device->outlet_id) {
                throw ApiException::notFound('Shift tidak ditemukan.');
            }

            if ($shift->status !== Shift::STATUS_OPEN) {
                throw ApiException::conflict('SHIFT_NOT_OPEN', 'Kas hanya dapat dicatat pada shift yang terbuka.');
            }

            $movement = $shift->cashMovements()->create([
                'uuid' => (string) Str::uuid(),
                'type' => $data['type'],
                'amount' => (int) $data['amount'],
                'reason' => $data['reason'] ?? null,
                'created_by' => $actor->id,
                'occurred_at' => now(),
            ]);

            $totals = $this->summary->calculate($shift);
            $shift->forceFill([
                'cash_in' => $totals['cash_in'],
                'cash_out' => $totals['cash_out'],
                'expected_cash' => $totals['expected_cash'],
            ])->save();

            $this->audit->record(
                'shift.cash_movement',
                'shifts',
                'Mencatat kas '.$movement->type.' pada shift '.$shift->uuid,
                $movement,
                [],
                $movement->only(['type', 'amount', 'reason']),
                $actor,
                $shift->business_id,
            );

            $this->sync->record(
                'shift.cash_movement',
                'shift_cash_movement',
                $movement->uuid,
                [
                    'shift_uuid' => $shift->uuid,
                    'movement_uuid' => $movement->uuid,
                    'type' => $movement->type,
                    'amount' => (int) $movement->amount,
                    'reason' => $movement->reason,
                    'occurred_at' => $movement->occurred_at?->toIso8601String(),
                    'expected_cash' => (int) $shift->expected_cash,
                ],
                $shift->business_id,
                $shift->outlet_id,
                $device->id,
            );

            return $shift->refresh()->load(['closingSnapshot', 'cashMovements', 'cashier', 'device', 'outlet']);
        });
    }
}
