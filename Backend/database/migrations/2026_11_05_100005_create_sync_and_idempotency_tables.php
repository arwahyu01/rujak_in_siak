<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('sync_events', function (Blueprint $table) {
            $table->char('payload_hash', 64)->nullable()->after('payload');
            $table->string('source', 20)->default('server')->after('payload_hash');
            $table->uuid('lease_uuid')->nullable()->after('source');
            $table->json('result')->nullable()->after('error_code');
            $table->boolean('retryable')->default(false)->after('result');

            $table->unique(['device_id', 'sequence']);
            $table->index(['business_id', 'outlet_id', 'id']);
        });

        Schema::create('sync_logs', function (Blueprint $table) {
            $table->id();
            $table->uuid('batch_id')->index();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('outlet_id')->constrained()->cascadeOnDelete();
            $table->foreignId('device_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedInteger('protocol_version')->default(1);
            $table->unsignedInteger('event_count')->default(0);
            $table->unsignedInteger('accepted_count')->default(0);
            $table->unsignedInteger('duplicate_count')->default(0);
            $table->unsignedInteger('rejected_count')->default(0);
            $table->unsignedInteger('conflict_count')->default(0);
            $table->unsignedInteger('blocked_count')->default(0);
            $table->json('result')->nullable();
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('received_at');
            $table->timestamps();
        });

        Schema::create('sync_cursors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('device_id')->unique()->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedBigInteger('last_event_id')->default(0);
            $table->timestamp('last_pulled_at')->nullable();
            $table->timestamps();
        });

        Schema::create('idempotency_keys', function (Blueprint $table) {
            $table->id();
            $table->foreignId('business_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('device_id')->nullable()->constrained()->nullOnDelete();
            $table->string('scope', 60);
            $table->string('key', 120);
            $table->char('request_hash', 64);
            $table->unsignedSmallInteger('response_status');
            $table->json('response_payload');
            $table->string('resource_type', 40)->nullable();
            $table->string('resource_uuid', 36)->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();

            $table->unique(['business_id', 'scope', 'key']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('idempotency_keys');
        Schema::dropIfExists('sync_cursors');
        Schema::dropIfExists('sync_logs');

        Schema::table('sync_events', function (Blueprint $table) {
            $table->dropUnique(['device_id', 'sequence']);
            $table->dropIndex(['business_id', 'outlet_id', 'id']);
            $table->dropColumn(['payload_hash', 'source', 'lease_uuid', 'result', 'retryable']);
        });
    }
};
