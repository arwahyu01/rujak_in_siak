<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('shift_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->string('order_number', 50);
            $table->string('status', 20)->default('draft')->index();
            $table->unsignedBigInteger('version')->default(1);
            $table->string('order_type', 20)->default('dine_in');
            $table->string('table_number', 20)->nullable()->index();
            $table->boolean('table_conflict')->default(false);
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('subtotal')->default(0);
            $table->unsignedBigInteger('item_discount_total')->default(0);
            $table->unsignedBigInteger('transaction_discount_total')->default(0);
            $table->unsignedBigInteger('discount_total')->default(0);
            $table->unsignedBigInteger('service_charge')->default(0);
            $table->unsignedBigInteger('tax_total')->default(0);
            $table->unsignedBigInteger('total')->default(0);
            $table->json('pricing_snapshot')->nullable();
            $table->timestamp('held_at')->nullable();
            $table->timestamp('resumed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->text('cancel_reason')->nullable();
            $table->timestamp('converted_at')->nullable();
            $table->timestamps();

            $table->unique(['business_id', 'order_number']);
            $table->index(['outlet_id', 'status', 'updated_at']);
            $table->index(['outlet_id', 'table_number', 'status']);
        });

        Schema::create('order_items', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->nullable()->constrained()->nullOnDelete();
            $table->uuid('product_uuid')->nullable();
            $table->string('sku', 60)->nullable();
            $table->string('product_name');
            $table->uuid('variant_uuid')->nullable();
            $table->string('variant_name')->nullable();
            $table->json('addons')->nullable();
            $table->unsignedBigInteger('unit_price');
            $table->unsignedInteger('quantity')->default(1);
            $table->unsignedBigInteger('item_discount')->default(0);
            $table->unsignedInteger('tax_rate_basis_points')->default(0);
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('line_subtotal');
            $table->unsignedBigInteger('line_total');
            $table->json('snapshot')->nullable();
            $table->timestamps();
        });

        Schema::create('order_item_modifiers', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('order_item_id')->constrained()->cascadeOnDelete();
            $table->string('type', 20);
            $table->uuid('modifier_uuid')->nullable();
            $table->string('name');
            $table->bigInteger('price')->default(0);
            $table->unsignedInteger('quantity')->default(1);
            $table->json('snapshot')->nullable();
            $table->timestamps();
        });

        Schema::create('order_status_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->string('from_status', 20)->nullable();
            $table->string('to_status', 20);
            $table->foreignId('actor_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('reason')->nullable();
            $table->unsignedBigInteger('version');
            $table->timestamp('created_at')->useCurrent();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('order_status_histories');
        Schema::dropIfExists('order_item_modifiers');
        Schema::dropIfExists('order_items');
        Schema::dropIfExists('orders');
    }
};
