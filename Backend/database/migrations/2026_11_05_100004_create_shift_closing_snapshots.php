<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shift_closing_snapshots', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('shift_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedBigInteger('opening_cash');
            $table->unsignedBigInteger('cash_tendered');
            $table->unsignedBigInteger('cash_change');
            $table->unsignedBigInteger('cash_in');
            $table->unsignedBigInteger('cash_out');
            $table->unsignedBigInteger('cash_refund');
            $table->bigInteger('expected_cash');
            $table->bigInteger('actual_cash');
            $table->bigInteger('variance');
            $table->unsignedBigInteger('confirmed_noncash');
            $table->unsignedBigInteger('awaiting_verification_amount');
            $table->unsignedInteger('local_transaction_count');
            $table->unsignedInteger('pending_sync_count');
            $table->unsignedBigInteger('local_event_sequence')->nullable();
            $table->text('closing_notes')->nullable();
            $table->json('snapshot');
            $table->timestamp('closed_at');
            $table->timestamps();
        });

        Schema::table('shifts', function (Blueprint $table) {
            $table->unsignedBigInteger('local_event_sequence')->nullable()->after('pending_sync_count');
        });
    }

    public function down(): void
    {
        Schema::table('shifts', function (Blueprint $table) {
            $table->dropColumn('local_event_sequence');
        });

        Schema::dropIfExists('shift_closing_snapshots');
    }
};
