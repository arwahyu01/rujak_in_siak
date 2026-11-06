<?php

namespace App\Services;

use App\Exceptions\ApiException;
use App\Models\Outlet;
use App\Models\ReceiptSequence;
use Illuminate\Database\QueryException;
use Illuminate\Support\Facades\DB;

class ReceiptNumberService
{
    public function next(Outlet $outlet, string $terminalCode): string
    {
        return DB::transaction(function () use ($outlet, $terminalCode) {
            $sequence = ReceiptSequence::query()
                ->where('outlet_id', $outlet->id)
                ->where('terminal_code', $terminalCode)
                ->lockForUpdate()
                ->first();

            if (! $sequence) {
                try {
                    $sequence = ReceiptSequence::create([
                        'outlet_id' => $outlet->id,
                        'terminal_code' => $terminalCode,
                        'last_sequence' => 0,
                    ]);
                    $sequence = ReceiptSequence::query()->lockForUpdate()->find($sequence->id);
                } catch (QueryException) {
                    $sequence = ReceiptSequence::query()
                        ->where('outlet_id', $outlet->id)
                        ->where('terminal_code', $terminalCode)
                        ->lockForUpdate()
                        ->firstOrFail();
                }
            }

            $sequence->increment('last_sequence');
            $number = (int) $sequence->fresh()->last_sequence;

            return sprintf('RJS-%s-%s-%010d', strtoupper($outlet->code), strtoupper($terminalCode), $number);
        });
    }

    public function registerExisting(string $receiptNumber, Outlet $outlet, string $terminalCode): void
    {
        if (! preg_match('/^RJS-[A-Z0-9]+-([A-Z0-9]+)-(\d{10})$/', strtoupper($receiptNumber), $matches)) {
            throw new ApiException('RECEIPT_NUMBER_INVALID', 'Format nomor struk tidak valid.', 422);
        }

        if ($matches[1] !== strtoupper($terminalCode) || ! str_starts_with(strtoupper($receiptNumber), 'RJS-'.strtoupper($outlet->code).'-')) {
            throw new ApiException('RECEIPT_TERMINAL_MISMATCH', 'Nomor struk tidak sesuai outlet/terminal perangkat.', 422);
        }

        ReceiptSequence::query()->updateOrCreate(
            ['outlet_id' => $outlet->id, 'terminal_code' => strtoupper($terminalCode)],
            [],
        );

        ReceiptSequence::query()
            ->where('outlet_id', $outlet->id)
            ->where('terminal_code', strtoupper($terminalCode))
            ->where('last_sequence', '<', (int) $matches[2])
            ->update(['last_sequence' => (int) $matches[2]]);
    }
}
