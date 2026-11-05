<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shifts', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status', 30)->default('open')->index();
            $table->unsignedBigInteger('opening_cash')->default(0);
            $table->unsignedBigInteger('cash_tendered')->default(0);
            $table->unsignedBigInteger('cash_change')->default(0);
            $table->unsignedBigInteger('cash_in')->default(0);
            $table->unsignedBigInteger('cash_out')->default(0);
            $table->unsignedBigInteger('cash_refund')->default(0);
            $table->bigInteger('expected_cash')->default(0);
            $table->bigInteger('actual_cash')->nullable();
            $table->bigInteger('variance')->nullable();
            $table->unsignedBigInteger('confirmed_noncash')->default(0);
            $table->unsignedBigInteger('awaiting_verification_amount')->default(0);
            $table->unsignedInteger('local_transaction_count')->default(0);
            $table->unsignedInteger('pending_sync_count')->default(0);
            $table->text('opening_notes')->nullable();
            $table->text('closing_notes')->nullable();
            $table->timestamp('opened_at');
            $table->timestamp('closed_at')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('shift_cash_movements', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('shift_id')->constrained()->cascadeOnDelete();
            $table->string('type', 20);
            $table->unsignedBigInteger('amount');
            $table->string('reason')->nullable();
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamp('occurred_at');
            $table->timestamps();
        });

        Schema::create('audit_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('action', 100)->index();
            $table->string('module', 50)->index();
            $table->string('auditable_type')->nullable();
            $table->string('auditable_id')->nullable();
            $table->string('description');
            $table->json('old_values')->nullable();
            $table->json('new_values')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 255)->nullable();
            $table->timestamp('created_at')->useCurrent();

            $table->index(['auditable_type', 'auditable_id']);
        });

        Schema::create('sync_events', function (Blueprint $table) {
            $table->id();
            $table->uuid('event_id')->unique();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('event_type', 80)->index();
            $table->string('aggregate_type', 40);
            $table->string('aggregate_id', 64);
            $table->unsignedBigInteger('aggregate_version')->nullable();
            $table->unsignedBigInteger('base_version')->nullable();
            $table->unsignedBigInteger('sequence')->nullable();
            $table->unsignedInteger('schema_version')->default(1);
            $table->string('status', 30)->default('pending')->index();
            $table->json('payload')->nullable();
            $table->string('error_code', 80)->nullable();
            $table->timestamp('occurred_at')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->index(['outlet_id', 'status']);
            $table->index(['aggregate_type', 'aggregate_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sync_events');
        Schema::dropIfExists('audit_logs');
        Schema::dropIfExists('shift_cash_movements');
        Schema::dropIfExists('shifts');
    }
};
