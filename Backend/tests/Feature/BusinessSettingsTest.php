<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class BusinessSettingsTest extends TestCase
{
    use CreatesApiContext, RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->createApiContext();
    }

    public function test_owner_can_view_and_update_proof_setting(): void
    {
        $this->actingAs($this->owner)
            ->get('/settings/business')
            ->assertOk()
            ->assertInertia(fn ($page) => $page
                ->component('Settings/Business')
                ->where('settings.non_cash_proof_required', false));

        $this->actingAs($this->owner)
            ->put('/settings/business', ['non_cash_proof_required' => true])
            ->assertRedirect();

        $this->assertTrue($this->business->refresh()->non_cash_proof_required);
    }

    public function test_admin_cannot_access_business_settings(): void
    {
        $admin = $this->makeUser('admin@rujak.test', 'admin', 'admin');

        $this->actingAs($admin)
            ->get('/settings/business')
            ->assertForbidden();

        $this->actingAs($admin)
            ->put('/settings/business', ['non_cash_proof_required' => true])
            ->assertForbidden();

        $this->assertFalse($this->business->refresh()->non_cash_proof_required);
    }
}
