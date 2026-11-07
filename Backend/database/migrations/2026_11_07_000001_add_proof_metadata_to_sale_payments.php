<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sale_payments', function (Blueprint $table) {
            $table->foreignId('proof_uploaded_by')->nullable()->after('proof_path')->constrained('users')->nullOnDelete();
            $table->timestamp('proof_uploaded_at')->nullable()->after('proof_uploaded_by');
        });
    }

    public function down(): void
    {
        Schema::table('sale_payments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('proof_uploaded_by');
            $table->dropColumn('proof_uploaded_at');
        });
    }
};
