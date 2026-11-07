<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('businesses', function (Blueprint $table) {
            $table->boolean('non_cash_proof_required')->default(false)->after('tax_includes_service_charge');
        });

        Schema::table('sale_payments', function (Blueprint $table) {
            $table->boolean('proof_required')->default(false)->after('proof_path');
        });
    }

    public function down(): void
    {
        Schema::table('sale_payments', function (Blueprint $table) {
            $table->dropColumn('proof_required');
        });

        Schema::table('businesses', function (Blueprint $table) {
            $table->dropColumn('non_cash_proof_required');
        });
    }
};
