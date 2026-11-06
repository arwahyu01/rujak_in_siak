<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\Concerns\CreatesApiContext;
use Tests\TestCase;

class ApiCatalogTest extends TestCase
{
    use CreatesApiContext;
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->createApiContext();
        Sanctum::actingAs($this->owner, ['api']);
    }

    public function test_catalog_only_returns_active_and_available_products_by_default(): void
    {
        $available = $this->makeProduct(10000);
        $this->makeProduct(11000, ['is_active' => false]);
        $this->makeProduct(12000, ['is_available' => false]);

        $response = $this->getJson('/api/v1/products', $this->headers($this->owner))
            ->assertOk();

        $uuids = collect($response->json('data'))->pluck('uuid');

        $this->assertTrue($uuids->contains($available->uuid));
        $this->assertSame(1, $response->json('meta.pagination.total'));

        $all = $this->getJson(
            '/api/v1/products?include_inactive=1&include_unavailable=1',
            $this->headers($this->owner),
        )->assertOk();

        $this->assertSame(3, $all->json('meta.pagination.total'));
    }

    public function test_catalog_supports_category_search_and_updated_since_filters(): void
    {
        $category = $this->makeCategory();
        $matching = $this->makeProduct(9000, [
            'category_id' => $category->id,
            'name' => 'Rujak Mangga',
            'sku' => 'RJ-MANGGA',
        ]);
        $this->makeProduct(8000, ['name' => 'Es Teh', 'sku' => 'MINUM-1']);

        $byCategory = $this->getJson(
            '/api/v1/products?category_uuid='.$category->uuid,
            $this->headers($this->owner),
        )->assertOk();

        $this->assertSame(1, $byCategory->json('meta.pagination.total'));
        $this->assertSame($matching->uuid, $byCategory->json('data.0.uuid'));

        $bySearch = $this->getJson('/api/v1/products?q=MANGGA', $this->headers($this->owner))
            ->assertOk();

        $this->assertSame(1, $bySearch->json('meta.pagination.total'));

        $future = $this->getJson(
            '/api/v1/products?updated_since='.urlencode(now()->addMinute()->toIso8601String()),
            $this->headers($this->owner),
        )->assertOk();

        $this->assertSame(0, $future->json('meta.pagination.total'));
    }

    public function test_catalog_is_tenant_isolated(): void
    {
        [, , $otherUser, $otherDevice] = $this->makeTenant('tenantc');

        $this->makeProduct(10000);

        $ownerList = $this->getJson('/api/v1/products', $this->headers($this->owner))->assertOk();
        $this->assertSame(1, $ownerList->json('meta.pagination.total'));

        Sanctum::actingAs($otherUser, ['api']);

        $created = $this->postJson('/api/v1/products', [
            'name' => 'Produk Tenant Lain',
            'sku' => 'OTHER-1',
            'price' => 7000,
        ], $this->headers($otherUser, $otherDevice))->assertCreated();

        $otherList = $this->getJson('/api/v1/products', $this->headers($otherUser, $otherDevice))->assertOk();
        $this->assertSame(1, $otherList->json('meta.pagination.total'));
        $this->assertSame($created->json('data.uuid'), $otherList->json('data.0.uuid'));
    }

    public function test_product_changes_are_published_to_sync_pull(): void
    {
        $created = $this->postJson('/api/v1/products', [
            'name' => 'Produk Baru',
            'sku' => 'NEW-1',
            'price' => 9000,
            'is_available' => true,
        ], $this->headers($this->owner))->assertCreated();

        $uuid = $created->json('data.uuid');

        $this->assertDatabaseHas('sync_events', [
            'event_type' => 'product.created',
            'aggregate_id' => $uuid,
            'status' => 'accepted',
        ]);

        $pull = $this->getJson('/api/v1/sync/pull', $this->headers($this->owner))->assertOk();

        $this->assertContains(
            'product.created',
            collect($pull->json('data.changes'))->pluck('event_type')->all(),
        );
    }
}
