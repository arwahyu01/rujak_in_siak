<?php

namespace App\Actions\Catalog;

use App\Models\Category;
use App\Services\AuditLogger;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class DeleteCategory
{
    public function __construct(private readonly AuditLogger $audit)
    {
    }

    public function handle(Category $category): void
    {
        if ($category->products()->exists()) {
            throw ValidationException::withMessages([
                'category' => 'Kategori masih memiliki produk. Nonaktifkan kategori atau pindahkan produk terlebih dahulu.',
            ]);
        }

        DB::transaction(function () use ($category): void {
            $category->update(['is_active' => false]);
            $this->audit->record(
                'category.deactivated',
                'categories',
                'Menonaktifkan kategori '.$category->name,
                $category,
                ['is_active' => true],
                ['is_active' => false],
                businessId: $category->business_id,
            );
        });
    }
}
