<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Seeder;

class ProductCatalogSeeder extends Seeder
{
    /**
     * Seed the launch menu. Prices are integer rupiah; the Basreng price was
     * not supplied, so that product stays inactive until its price is set.
     *
     * @var array<int, array{name: string, slug: string, products: array<int, array<string, mixed>>}>
     */
    private const CATEGORIES = [
        [
            'name' => 'The Fresh Series',
            'slug' => 'the-fresh-series',
            'products' => [
                ['sku' => 'FRESH-001', 'name' => 'Salad Buah', 'price' => 10000],
                ['sku' => 'FRESH-002', 'name' => 'Rujak Mix', 'price' => 15000],
                ['sku' => 'FRESH-003', 'name' => 'Ximilu Creamy', 'price' => 15000],
                ['sku' => 'FRESH-004', 'name' => 'Sop Durian', 'price' => 20000],
                ['sku' => 'FRESH-005', 'name' => 'Manisan Buah', 'price' => 20000],
                ['sku' => 'FRESH-006', 'name' => 'Asinan Pedas', 'price' => 20000],
                ['sku' => 'FRESH-007', 'name' => 'Asinan Kiamboy', 'price' => 20000],
                ['sku' => 'FRESH-008', 'name' => 'Asinan Kiamboy Premium', 'price' => 35000],
                ['sku' => 'FRESH-009', 'name' => 'Asinan Pindang', 'price' => 20000],
                ['sku' => 'FRESH-010', 'name' => 'Rujak Nampah Birthday', 'price' => 85000],
            ],
        ],
        [
            'name' => 'Fresh & Ice',
            'slug' => 'fresh-and-ice',
            'products' => [
                ['sku' => 'DRINK-001', 'name' => 'Air Mineral', 'price' => 5000, 'unit' => 'botol'],
                ['sku' => 'DRINK-002', 'name' => 'Es Teh', 'price' => 5000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-003', 'name' => 'Es Sirup Merah', 'price' => 5000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-004', 'name' => 'Es Teh Leci', 'price' => 8000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-005', 'name' => 'Es Kopi', 'price' => 10000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-006', 'name' => 'Lemonade', 'price' => 10000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-007', 'name' => 'Blue Ocean', 'price' => 10000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-008', 'name' => 'Es Cokelat', 'price' => 15000, 'unit' => 'gelas'],
                [
                    'sku' => 'DRINK-009',
                    'name' => 'Matcha / Seasalt',
                    'price' => 15000,
                    'unit' => 'gelas',
                    'variants' => [
                        ['name' => 'Matcha - Reguler', 'price_delta' => 0],
                        ['name' => 'Matcha - Large', 'price_delta' => 3000],
                        ['name' => 'Seasalt - Reguler', 'price_delta' => 0],
                        ['name' => 'Seasalt - Large', 'price_delta' => 3000],
                    ],
                ],
                [
                    'sku' => 'DRINK-010',
                    'name' => 'Thaitea / Seasalt',
                    'price' => 15000,
                    'unit' => 'gelas',
                    'variants' => [
                        ['name' => 'Thaitea - Reguler', 'price_delta' => 0],
                        ['name' => 'Thaitea - Large', 'price_delta' => 3000],
                        ['name' => 'Seasalt - Reguler', 'price_delta' => 0],
                        ['name' => 'Seasalt - Large', 'price_delta' => 3000],
                    ],
                ],
                ['sku' => 'DRINK-011', 'name' => 'Kopi Susu', 'price' => 13000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-012', 'name' => 'Kopi Susu Aren', 'price' => 15000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-013', 'name' => 'Butterscotch Aren', 'price' => 15000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-014', 'name' => 'Butterscotch Seasalt', 'price' => 20000, 'unit' => 'gelas'],
                ['sku' => 'DRINK-015', 'name' => 'Salted Caramel', 'price' => 20000, 'unit' => 'gelas'],
            ],
        ],
        [
            'name' => 'The Comfort Series',
            'slug' => 'the-comfort-series',
            'products' => [
                ['sku' => 'COMFORT-001', 'name' => 'Roti Bakar Keju', 'price' => 10000],
                ['sku' => 'COMFORT-002', 'name' => 'Roti Bakar Chococrunch', 'price' => 10000],
                ['sku' => 'COMFORT-003', 'name' => 'Roti Bakar Caramel', 'price' => 10000],
                [
                    'sku' => 'COMFORT-004',
                    'name' => 'Miso Medan',
                    'price' => 15000,
                    'description' => 'Pilihan mie: Mihun atau Mi Kuning Indomie.',
                    'variants' => [
                        ['name' => 'Mihun', 'price_delta' => 0],
                        ['name' => 'Mi Kuning Indomie', 'price_delta' => 0],
                    ],
                ],
                [
                    'sku' => 'COMFORT-005',
                    'name' => 'Soto Medan',
                    'price' => 15000,
                    'description' => 'Pilihan mie: Mihun atau Mi Kuning Indomie.',
                    'variants' => [
                        ['name' => 'Mihun', 'price_delta' => 0],
                        ['name' => 'Mi Kuning Indomie', 'price_delta' => 0],
                    ],
                ],
                ['sku' => 'COMFORT-006', 'name' => 'Pisang Bakar Santan', 'price' => 15000],
                ['sku' => 'COMFORT-007', 'name' => 'Roti Pisang Bakar Santan', 'price' => 15000],
                ['sku' => 'COMFORT-008', 'name' => 'Ketan Keju', 'price' => 15000],
                ['sku' => 'COMFORT-009', 'name' => 'Ketan Chococrunch', 'price' => 15000],
                ['sku' => 'COMFORT-010', 'name' => 'Mango Sticky Rice', 'price' => 20000],
                [
                    'sku' => 'COMFORT-011',
                    'name' => 'Basreng Tempura Prasmanan',
                    'price' => 0,
                    'description' => 'Harga belum ditetapkan; produk dinonaktifkan sampai harga dikonfirmasi.',
                    'is_active' => false,
                    'is_available' => false,
                ],
                [
                    'sku' => 'COMFORT-012',
                    'name' => 'Sate Rendang Kerang (3 Tusuk)',
                    'price' => 10000,
                    'unit' => 'porsi',
                    'description' => 'Harga untuk 1 porsi berisi 3 tusuk.',
                ],
                ['sku' => 'COMFORT-013', 'name' => 'Sate Rendang Telur Puyuh', 'price' => 5000],
            ],
        ],
    ];

    public function run(): void
    {
        $business = Business::query()
            ->where('name', 'Rujak In Siak')
            ->firstOrFail();

        foreach (self::CATEGORIES as $sortOrder => $categoryData) {
            $category = Category::updateOrCreate(
                [
                    'business_id' => $business->id,
                    'slug' => $categoryData['slug'],
                ],
                [
                    'name' => $categoryData['name'],
                    'description' => null,
                    'sort_order' => $sortOrder + 1,
                    'is_active' => true,
                ],
            );

            foreach ($categoryData['products'] as $productData) {
                $product = Product::updateOrCreate(
                    [
                        'business_id' => $business->id,
                        'sku' => $productData['sku'],
                    ],
                    [
                        'category_id' => $category->id,
                        'barcode' => null,
                        'name' => $productData['name'],
                        'description' => $productData['description'] ?? null,
                        'unit' => $productData['unit'] ?? 'porsi',
                        'price' => $productData['price'],
                        'production_cost' => null,
                        'tax_rate_basis_points' => null,
                        'is_active' => $productData['is_active'] ?? true,
                        'is_available' => $productData['is_available'] ?? true,
                    ],
                );

                foreach ($productData['variants'] ?? [] as $variantData) {
                    $product->variants()->updateOrCreate(
                        ['name' => $variantData['name']],
                        [
                            'sku' => null,
                            'price_delta' => $variantData['price_delta'],
                            'is_active' => true,
                        ],
                    );
                }
            }
        }
    }
}
