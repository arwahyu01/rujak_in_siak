<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('sales', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('shift_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('receipt_number', 80)->unique();
            $table->string('order_type', 20)->default('dine_in');
            $table->string('table_number', 20)->nullable();
            $table->string('lifecycle_status', 20)->default('finalized')->index();
            $table->string('payment_status', 30)->default('unpaid')->index();
            $table->unsignedBigInteger('subtotal')->default(0);
            $table->unsignedBigInteger('item_discount_total')->default(0);
            $table->unsignedBigInteger('transaction_discount_total')->default(0);
            $table->unsignedBigInteger('discount_total')->default(0);
            $table->unsignedBigInteger('service_charge')->default(0);
            $table->unsignedBigInteger('tax_total')->default(0);
            $table->unsignedBigInteger('total')->default(0);
            $table->unsignedBigInteger('confirmed_amount')->default(0);
            $table->unsignedBigInteger('awaiting_verification_amount')->default(0);
            $table->unsignedBigInteger('outstanding_amount')->default(0);
            $table->unsignedBigInteger('refunded_amount')->default(0);
            $table->text('notes')->nullable();
            $table->string('source_order_uuid', 36)->nullable();
            $table->timestamp('transacted_at')->index();
            $table->timestamp('voided_at')->nullable();
            $table->foreignId('voided_by')->nullable()->constrained('users')->nullOnDelete();
            $table->text('void_reason')->nullable();
            $table->timestamps();

            $table->index(['business_id', 'outlet_id', 'transacted_at']);
            $table->index(['payment_status', 'transacted_at']);
        });

        Schema::create('sale_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->nullable()->constrained()->nullOnDelete();
            $table->string('sku', 60)->nullable();
            $table->string('product_name');
            $table->string('variant_name')->nullable();
            $table->text('addon_summary')->nullable();
            $table->unsignedBigInteger('unit_price');
            $table->unsignedInteger('quantity')->default(1);
            $table->unsignedBigInteger('discount_amount')->default(0);
            $table->unsignedBigInteger('tax_amount')->default(0);
            $table->unsignedBigInteger('service_charge_amount')->default(0);
            $table->unsignedBigInteger('subtotal');
            $table->unsignedBigInteger('total');
            $table->json('snapshot')->nullable();
            $table->timestamps();
        });

        Schema::create('sale_payments', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('sale_id')->constrained()->cascadeOnDelete();
            $table->string('method', 30)->index();
            $table->unsignedBigInteger('amount');
            $table->unsignedBigInteger('verified_amount')->nullable();
            $table->string('status', 30)->default('recorded')->index();
            $table->string('provider_reference')->nullable();
            $table->text('notes')->nullable();
            $table->string('proof_path')->nullable();
            $table->foreignId('recorded_by')->constrained('users')->cascadeOnDelete();
            $table->timestamp('recorded_at');
            $table->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('verified_at')->nullable();
            $table->foreignId('rejected_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('rejected_at')->nullable();
            $table->text('rejection_reason')->nullable();
            $table->timestamps();
        });

        Schema::create('payment_verification_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('sale_payment_id')->constrained()->cascadeOnDelete();
            $table->string('action', 30);
            $table->foreignId('actor_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedBigInteger('recorded_amount');
            $table->unsignedBigInteger('verified_amount')->nullable();
            $table->text('reason')->nullable();
            $table->string('provider_reference')->nullable();
            $table->text('notes')->nullable();
            $table->timestamp('created_at')->useCurrent();
        });

        Schema::create('refunds', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('sale_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('amount');
            $table->text('reason');
            $table->foreignId('created_by')->constrained('users')->cascadeOnDelete();
            $table->timestamp('refunded_at');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('refunds');
        Schema::dropIfExists('payment_verification_logs');
        Schema::dropIfExists('sale_payments');
        Schema::dropIfExists('sale_items');
        Schema::dropIfExists('sales');
    }
};
