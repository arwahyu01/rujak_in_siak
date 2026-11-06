<?php

namespace Tests\Feature;

use App\Models\AuthorizationLease;
use App\Services\OfflineLeaseService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiAuthDeviceTest extends TestCase
{
    use CreatesApiContext;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->createApiContext();
    }

    public function test_login_issues_token_and_offline_lease(): void
    {
        $response = $this->postJson('/api/v1/auth/login', [
            'identifier' => 'owner@rujak.test',
            'password' => 'password',
            'device_uuid' => $this->device->uuid,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.user.uuid', $this->owner->uuid)
            ->assertJsonPath('data.device.uuid', $this->device->uuid)
            ->assertJsonPath('data.offline_lease.lease.device_id', $this->device->uuid);

        $this->assertNotEmpty($response->json('data.token'));
        $this->assertNotEmpty($response->json('data.offline_lease.token'));

        $this->assertDatabaseHas('authorization_leases', [
            'device_id' => $this->device->id,
            'revoked_at' => null,
        ]);

        $this->getJson('/api/v1/me', [
            'X-Device-Id' => $this->device->uuid,
            'Authorization' => 'Bearer '.$response->json('data.token'),
        ])->assertOk()->assertJsonPath('data.user.uuid', $this->owner->uuid);
    }

    public function test_login_rejects_invalid_credentials_and_locks_after_five_failures(): void
    {
        $this->postJson('/api/v1/auth/login', [
            'identifier' => 'owner@rujak.test',
            'password' => 'wrong-password',
        ])->assertStatus(401)->assertJsonPath('error.code', 'AUTH_INVALID_CREDENTIALS');

        for ($attempt = 0; $attempt < 4; $attempt++) {
            $this->postJson('/api/v1/auth/login', [
                'identifier' => 'owner@rujak.test',
                'password' => 'wrong-password',
            ])->assertStatus(401);
        }

        $this->owner->refresh();
        $this->assertNotNull($this->owner->locked_until);
        $this->assertTrue($this->owner->locked_until->isFuture());
    }

    public function test_register_device_and_reject_duplicate_terminal_code(): void
    {
        Sanctum::actingAs($this->owner, ['api']);

        $uuid = (string) Str::uuid();

        $this->postJson('/api/v1/devices/register', [
            'uuid' => $uuid,
            'name' => 'Terminal 2',
            'terminal_code' => 'T02',
            'platform' => 'android',
            'device_fingerprint' => 'fp-2',
        ], $this->headers($this->owner))
            ->assertCreated()
            ->assertJsonPath('data.device.uuid', $uuid)
            ->assertJsonPath('data.device.terminal_code', 'T02');

        $this->assertNotEmpty(
            $this->postJson('/api/v1/devices/register', [
                'uuid' => $uuid,
                'name' => 'Terminal 2',
                'terminal_code' => 'T02',
            ], $this->headers($this->owner))->json('data.offline_lease.token'),
        );

        $this->postJson('/api/v1/devices/register', [
            'uuid' => (string) Str::uuid(),
            'name' => 'Terminal Duplikat',
            'terminal_code' => 'T01',
        ], $this->headers($this->owner))
            ->assertStatus(409)
            ->assertJsonPath('error.code', 'TERMINAL_CODE_TAKEN');
    }

    public function test_device_registration_and_revocation_are_tenant_scoped(): void
    {
        [, , $otherUser] = $this->makeTenant('tenantb');

        Sanctum::actingAs($otherUser, ['api']);

        $this->postJson('/api/v1/devices/register', [
            'uuid' => $this->device->uuid,
            'name' => 'Hijack',
            'terminal_code' => 'H01',
        ])->assertStatus(403)->assertJsonPath('error.code', 'DEVICE_SCOPE_MISMATCH');

        $this->postJson('/api/v1/devices/'.$this->device->uuid.'/revoke')
            ->assertStatus(404);
    }

    public function test_revoked_device_cannot_authenticate_or_call_api(): void
    {
        Sanctum::actingAs($this->owner, ['api']);

        $this->postJson('/api/v1/devices/'.$this->device->uuid.'/revoke', [], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.status', 'revoked');

        $this->assertSame(
            0,
            AuthorizationLease::query()
                ->where('device_id', $this->device->id)
                ->whereNull('revoked_at')
                ->count(),
        );

        $this->getJson('/api/v1/products', $this->headers($this->owner))
            ->assertStatus(403)
            ->assertJsonPath('error.code', 'DEVICE_REVOKED');

        $this->postJson('/api/v1/auth/login', [
            'identifier' => 'owner@rujak.test',
            'password' => 'password',
            'device_uuid' => $this->device->uuid,
        ])->assertStatus(403)->assertJsonPath('error.code', 'DEVICE_REVOKED');
    }

    public function test_offline_lease_requires_pin_proof_once_pin_is_configured(): void
    {
        Sanctum::actingAs($this->owner, ['api']);

        $this->postJson('/api/v1/auth/offline-lease', [], $this->headers($this->owner))
            ->assertOk()
            ->assertJsonPath('data.lease.device_id', $this->device->uuid);

        $this->putJson('/api/v1/me/pin', [
            'current_password' => 'password',
            'pin' => '1234',
            'pin_confirmation' => '1234',
        ], $this->headers($this->owner))->assertOk();

        $this->postJson('/api/v1/auth/offline-lease', [], $this->headers($this->owner))
            ->assertStatus(422)
            ->assertJsonPath('error.code', 'AUTH_PROOF_REQUIRED');

        $this->postJson('/api/v1/auth/offline-lease', ['pin' => '9999'], $this->headers($this->owner))
            ->assertStatus(401)
            ->assertJsonPath('error.code', 'AUTH_PROOF_INVALID');

        $issued = $this->postJson('/api/v1/auth/offline-lease', ['pin' => '1234'], $this->headers($this->owner))
            ->assertOk();

        $verified = app(OfflineLeaseService::class)->verify(
            (string) $issued->json('data.token'),
            $this->device->fresh(),
        );

        $this->assertSame($this->owner->uuid, $verified['payload']['user_id']);
        $this->assertSame($this->device->uuid, $verified['payload']['device_id']);
    }
}
