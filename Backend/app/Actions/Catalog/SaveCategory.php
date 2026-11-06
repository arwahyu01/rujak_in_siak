<?php

namespace App\Actions\Catalog;

use App\Models\Category;
use App\Services\AuditLogger;
use App\Services\SyncRecorder;
use Illuminate\Support\Str;

class SaveCategory
{
    public function __construct(
        private readonly AuditLogger $audit,
        private readonly SyncRecorder $sync,
    ) {}

    public function handle(array $data, int $businessId, ?Category $category = null): Category
    {
        $old = $category ? $category->only(['name', 'slug', 'description', 'sort_order', 'tax_rate_basis_points', 'is_active']) : [];

        $slug = Str::slug($data['name']);
        $base = $slug;
        $counter = 1;
        while (Category::query()
            ->where('business_id', $businessId)
            ->where('slug', $slug)
            ->when($category, fn ($query) => $query->whereKeyNot($category->id))
            ->exists()) {
            $slug = $base.'-'.$counter++;
        }

        $payload = [
            'business_id' => $businessId,
            'name' => $data['name'],
            'slug' => $slug,
            'description' => $data['description'] ?? null,
            'sort_order' => (int) ($data['sort_order'] ?? 0),
            'tax_rate_basis_points' => isset($data['tax_rate_basis_points']) && $data['tax_rate_basis_points'] !== ''
                ? (int) $data['tax_rate_basis_points']
                : null,
            'is_active' => (bool) ($data['is_active'] ?? true),
        ];

        if ($category) {
            $category->update($payload);
        } else {
            $category = Category::create($payload);
        }

        $created = $category->wasRecentlyCreated;

        $this->audit->record(
            $created ? 'category.created' : 'category.updated',
            'categories',
            ($created ? 'Membuat' : 'Memperbarui').' kategori '.$category->name,
            $category,
            $old,
            $category->only(['name', 'slug', 'description', 'sort_order', 'tax_rate_basis_points', 'is_active']),
            businessId: $businessId,
        );

        $fresh = $category->refresh();

        $this->sync->record(
            $created ? 'category.created' : 'category.updated',
            'category',
            $fresh->uuid,
            $this->payload($fresh),
            $businessId,
        );

        return $fresh;
    }

    private function payload(Category $category): array
    {
        return [
            'uuid' => $category->uuid,
            'name' => $category->name,
            'slug' => $category->slug,
            'description' => $category->description,
            'sort_order' => (int) $category->sort_order,
            'tax_rate_basis_points' => $category->tax_rate_basis_points,
            'is_active' => (bool) $category->is_active,
            'updated_at' => $category->updated_at?->toIso8601String(),
        ];
    }
}
