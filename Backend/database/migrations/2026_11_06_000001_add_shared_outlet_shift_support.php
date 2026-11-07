<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('shifts', function (Blueprint $table) {
            // open_slot is 1 while a shift is open/closing. The unique index
            // below makes a second concurrently active shift per outlet
            // impossible even if the application-level lock is bypassed.
            $table->unsignedTinyInteger('open_slot')->nullable()->after('status');
            $table->unsignedInteger('close_epoch')->default(0)->after('open_slot');
            $table->timestamp('closing_started_at')->nullable()->after('closed_at');
            $table->foreignId('closing_requested_by')->nullable()->after('closing_started_at')
                ->constrained('users')->nullOnDelete();
            $table->foreignId('closing_requested_device_id')->nullable()->after('closing_requested_by')
                ->constrained('devices')->nullOnDelete();
            $table->bigInteger('close_actual_cash')->nullable()->after('closing_requested_device_id');
            $table->foreignId('closed_by_user_id')->nullable()->after('closed_at')
                ->constrained('users')->nullOnDelete();
            $table->foreignId('closed_device_id')->nullable()->after('closed_by_user_id')
                ->constrained('devices')->nullOnDelete();

            $table->index(['outlet_id', 'status']);
        });

        Schema::table('shift_cash_movements', function (Blueprint $table) {
            $table->foreignId('device_id')->nullable()->after('created_by')
                ->constrained()->nullOnDelete();
        });

        Schema::table('shift_closing_snapshots', function (Blueprint $table) {
            $table->foreignId('closed_by_user_id')->nullable()->after('device_id')
                ->constrained('users')->nullOnDelete();
            $table->foreignId('closed_device_id')->nullable()->after('closed_by_user_id')
                ->constrained('devices')->nullOnDelete();
            $table->unsignedInteger('device_count')->default(0)->after('pending_sync_count');
            $table->unsignedInteger('synced_device_count')->default(0)->after('device_count');
            $table->unsignedInteger('checkpoint_epoch')->default(0)->after('synced_device_count');
            $table->timestamp('finalized_at')->nullable()->after('closed_at');
        });

        Schema::create('shift_devices', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('shift_id')->constrained()->cascadeOnDelete();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->boolean('requires_checkpoint')->default(true);
            $table->unsignedInteger('last_ack_epoch')->default(0);
            $table->unsignedBigInteger('last_sequence')->nullable();
            $table->unsignedInteger('checkpoint_outbox_pending')->nullable();
            $table->timestamp('acknowledged_at')->nullable();
            $table->timestamp('first_seen_at');
            $table->timestamp('last_seen_at');
            $table->timestamps();

            $table->unique(['shift_id', 'device_id']);
        });

        $this->deduplicateLegacyOpenShifts();
        $this->backfillParticipants();

        Schema::table('shifts', function (Blueprint $table) {
            $table->unique(['outlet_id', 'open_slot']);
        });
    }

    public function down(): void
    {
        Schema::table('shifts', function (Blueprint $table) {
            $table->dropUnique(['outlet_id', 'open_slot']);
            $table->dropIndex(['outlet_id', 'status']);
            $table->dropConstrainedForeignId('closing_requested_by');
            $table->dropConstrainedForeignId('closing_requested_device_id');
            $table->dropConstrainedForeignId('closed_by_user_id');
            $table->dropConstrainedForeignId('closed_device_id');
            $table->dropColumn([
                'open_slot',
                'close_epoch',
                'closing_started_at',
                'close_actual_cash',
            ]);
        });

        Schema::table('shift_cash_movements', function (Blueprint $table) {
            $table->dropConstrainedForeignId('device_id');
        });

        Schema::table('shift_closing_snapshots', function (Blueprint $table) {
            $table->dropConstrainedForeignId('closed_by_user_id');
            $table->dropConstrainedForeignId('closed_device_id');
            $table->dropColumn([
                'device_count',
                'synced_device_count',
                'checkpoint_epoch',
                'finalized_at',
            ]);
        });

        Schema::dropIfExists('shift_devices');
    }

    /**
     * Before the unique outlet/open_slot index exists we must resolve legacy
     * open shifts. Keep the newest shift per outlet and mark every other open
     * shift as a sync exception with an audit trail. No data is merged or
     * deleted, and historical rows stay readable.
     */
    private function deduplicateLegacyOpenShifts(): void
    {
        $openShifts = DB::table('shifts')
            ->where('status', 'open')
            ->orderBy('outlet_id')
            ->orderByDesc('opened_at')
            ->orderByDesc('id')
            ->get(['id', 'uuid', 'business_id', 'outlet_id', 'user_id', 'device_id', 'opened_at']);

        $grouped = $openShifts->groupBy('outlet_id');

        foreach ($grouped as $outletId => $shifts) {
            /** @var Collection $shifts */
            $keeper = $shifts->first();

            DB::table('shifts')->where('id', $keeper->id)->update(['open_slot' => 1]);

            foreach ($shifts->skip(1) as $duplicate) {
                $notes = sprintf(
                    'Ditandai sebagai pengecualian sinkronisasi oleh migrasi shift bersama pada %s. Shift aktif outlet dipertahankan: %s.',
                    now()->toIso8601String(),
                    $keeper->uuid,
                );

                DB::table('shifts')->where('id', $duplicate->id)->update([
                    'status' => 'closed_sync_exception',
                    'open_slot' => null,
                    'closed_at' => now(),
                    'closing_notes' => $notes,
                    'updated_at' => now(),
                ]);

                DB::table('audit_logs')->insert([
                    'business_id' => $duplicate->business_id,
                    'user_id' => null,
                    'action' => 'shift.migration_deduplicated',
                    'module' => 'shifts',
                    'auditable_type' => 'App\\Models\\Shift',
                    'auditable_id' => $duplicate->uuid,
                    'description' => 'Shift open ganda pada outlet yang sama ditandai closed_sync_exception saat migrasi shift bersama.',
                    'old_values' => json_encode([
                        'status' => 'open',
                        'outlet_id' => $outletId,
                        'device_id' => $duplicate->device_id,
                        'opened_at' => $duplicate->opened_at,
                    ]),
                    'new_values' => json_encode([
                        'status' => 'closed_sync_exception',
                        'retained_shift_uuid' => $keeper->uuid,
                        'note' => $notes,
                    ]),
                    'ip_address' => null,
                    'user_agent' => 'migration',
                    'created_at' => now(),
                ]);
            }
        }
    }

    private function backfillParticipants(): void
    {
        $now = now();

        $shifts = DB::table('shifts')
            ->whereIn('status', ['open', 'closing'])
            ->get(['id', 'business_id', 'outlet_id', 'device_id', 'user_id', 'opened_at']);

        foreach ($shifts as $shift) {
            $deviceIds = collect();

            if ($shift->device_id !== null) {
                $deviceIds->push($shift->device_id);
            }

            $deviceIds = $deviceIds
                ->merge(DB::table('orders')->where('shift_id', $shift->id)->whereNotNull('device_id')->pluck('device_id'))
                ->merge(DB::table('sales')->where('shift_id', $shift->id)->whereNotNull('device_id')->pluck('device_id'))
                ->merge(DB::table('shift_cash_movements')->where('shift_id', $shift->id)->pluck('device_id'))
                ->unique()
                ->filter();

            foreach ($deviceIds as $deviceId) {
                DB::table('shift_devices')->insertOrIgnore([
                    'uuid' => (string) Str::uuid(),
                    'shift_id' => $shift->id,
                    'business_id' => $shift->business_id,
                    'outlet_id' => $shift->outlet_id,
                    'device_id' => $deviceId,
                    'user_id' => $shift->user_id,
                    'requires_checkpoint' => true,
                    'last_ack_epoch' => 0,
                    'first_seen_at' => $shift->opened_at ?? $now,
                    'last_seen_at' => $now,
                    'created_at' => $now,
                    'updated_at' => $now,
                ]);
            }
        }
    }
};
