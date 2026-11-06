<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('pin_hash')->nullable()->after('password');
            $table->timestamp('pin_updated_at')->nullable()->after('pin_hash');
            $table->unsignedBigInteger('auth_version')->default(1)->after('pin_updated_at');
            $table->unsignedInteger('failed_login_attempts')->default(0)->after('auth_version');
            $table->timestamp('locked_until')->nullable()->after('failed_login_attempts');
        });

        Schema::table('devices', function (Blueprint $table) {
            $table->string('app_version', 40)->nullable()->after('platform');
            $table->string('device_fingerprint', 191)->nullable()->after('app_version');
            $table->unsignedBigInteger('last_sequence')->default(0)->after('device_fingerprint');
            $table->timestamp('activated_at')->nullable()->after('last_seen_at');
        });

        Schema::create('user_sessions', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedBigInteger('personal_access_token_id')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->string('user_agent', 255)->nullable();
            $table->timestamp('logged_in_at');
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('revoked_at')->nullable();
            $table->string('revoked_reason')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'logged_in_at']);
            $table->index(['device_id', 'revoked_at']);
        });

        Schema::create('authorization_leases', function (Blueprint $table) {
            $table->id();
            $table->uuid('uuid')->unique();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->unsignedBigInteger('auth_version');
            $table->json('roles');
            $table->json('permissions');
            $table->string('signature_hash', 64);
            $table->timestamp('issued_at');
            $table->timestamp('expires_at')->index();
            $table->timestamp('revoked_at')->nullable();
            $table->string('revoked_reason')->nullable();
            $table->timestamps();

            $table->index(['device_id', 'expires_at']);
        });

        Schema::create('receipt_sequences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->string('terminal_code', 20);
            $table->unsignedBigInteger('last_sequence')->default(0);
            $table->timestamps();

            $table->unique(['outlet_id', 'terminal_code']);
        });

        Schema::table('categories', function (Blueprint $table) {
            $table->unsignedInteger('tax_rate_basis_points')->nullable()->after('sort_order');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->unsignedInteger('tax_rate_basis_points')->nullable()->after('production_cost');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('tax_rate_basis_points');
        });

        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('tax_rate_basis_points');
        });

        Schema::dropIfExists('receipt_sequences');
        Schema::dropIfExists('authorization_leases');
        Schema::dropIfExists('user_sessions');

        Schema::table('devices', function (Blueprint $table) {
            $table->dropColumn(['app_version', 'device_fingerprint', 'last_sequence', 'activated_at']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['pin_hash', 'pin_updated_at', 'auth_version', 'failed_login_attempts', 'locked_until']);
        });
    }
};
