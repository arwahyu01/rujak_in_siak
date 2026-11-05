<?php

namespace App\Actions\Catalog;

use App\Models\Category;
use App\Services\AuditLogger;
use Illuminate\Support\Str;

class SaveCategory
{
    public function __construct(private readonly AuditLogger $audit)
    {
    }

    public function handle(array $data, int $businessId, ?Category $category = null): Category
    {
        $old = $category ? $category->only(['name', 'slug', 'description', 'sort_order', 'is_active']) : [];

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
            'is_active' => (bool) ($data['is_active'] ?? true),
        ];

        if ($category) {
            $category->update($payload);
        } else {
            $category = Category::create($payload);
        }

        $this->audit->record(
            $category->wasRecentlyCreated ? 'category.created' : 'category.updated',
            'categories',
            ($category->wasRecentlyCreated ? 'Membuat' : 'Memperbarui').' kategori '.$category->name,
            $category,
            $old,
            $category->only(['name', 'slug', 'description', 'sort_order', 'is_active']),
            businessId: $businessId,
        );

        return $category->refresh();
    }
}
