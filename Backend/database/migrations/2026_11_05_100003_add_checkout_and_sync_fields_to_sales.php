<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sales', function (Blueprint $table) {
            $table->foreignId('source_order_id')->nullable()->unique()->after('device_id')
                ->constrained('orders')->nullOnDelete();
            $table->unsignedBigInteger('source_order_version')->nullable()->after('source_order_id');
            $table->string('origin', 20)->default('online')->after('source_order_version');
            $table->json('pricing_snapshot')->nullable()->after('notes');
            $table->timestamp('client_created_at')->nullable()->after('transacted_at');
        });

        Schema::table('sale_items', function (Blueprint $table) {
            $table->uuid('product_uuid')->nullable()->after('product_id');
            $table->uuid('variant_uuid')->nullable()->after('variant_name');
            $table->unsignedInteger('tax_rate_basis_points')->default(0)->after('discount_amount');
            $table->foreignId('source_order_item_id')->nullable()->after('sale_id')
                ->constrained('order_items')->nullOnDelete();
        });

        Schema::table('sale_payments', function (Blueprint $table) {
            $table->unsignedBigInteger('tendered_amount')->nullable()->after('amount');
            $table->unsignedBigInteger('change_amount')->default(0)->after('tendered_amount');
            $table->string('idempotency_key', 120)->nullable()->after('uuid');
            $table->string('origin', 20)->default('online')->after('proof_path');
        });

        Schema::table('refunds', function (Blueprint $table) {
            $table->string('method', 30)->default('cash')->after('amount');
            $table->string('idempotency_key', 120)->nullable()->after('uuid');

            $table->unique(['sale_id', 'idempotency_key']);
        });
    }

    public function down(): void
    {
        Schema::table('refunds', function (Blueprint $table) {
            $table->dropUnique(['sale_id', 'idempotency_key']);
            $table->dropColumn(['method', 'idempotency_key']);
        });

        Schema::table('sale_payments', function (Blueprint $table) {
            $table->dropColumn(['tendered_amount', 'change_amount', 'idempotency_key', 'origin']);
        });

        Schema::table('sale_items', function (Blueprint $table) {
            $table->dropConstrainedForeignId('source_order_item_id');
            $table->dropColumn(['product_uuid', 'variant_uuid', 'tax_rate_basis_points']);
        });

        Schema::table('sales', function (Blueprint $table) {
            $table->dropConstrainedForeignId('source_order_id');
            $table->dropColumn(['source_order_version', 'origin', 'pricing_snapshot', 'client_created_at']);
        });
    }
};
