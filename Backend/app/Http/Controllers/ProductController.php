<?php

namespace App\Http\Controllers;

use App\Actions\Catalog\SaveProduct;
use App\Actions\Catalog\ToggleProductAvailability;
use App\Http\Requests\Catalog\ProductRequest;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class ProductController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize('viewAny', Product::class);

        $businessId = $request->user()->business_id;
        $search = trim((string) $request->query('q'));
        $categoryId = $request->query('category_id');
        $status = (string) $request->query('status', 'all');
        $availability = (string) $request->query('availability', 'all');

        $products = Product::query()
            ->where('business_id', $businessId)
            ->with(['category:id,name', 'variants', 'addons'])
            ->withCount(['variants', 'addons'])
            ->when($search !== '', fn ($query) => $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('sku', 'like', "%{$search}%")
                    ->orWhere('barcode', 'like', "%{$search}%");
            }))
            ->when($categoryId, fn ($query) => $query->where('category_id', $categoryId))
            ->when($status === 'active', fn ($query) => $query->where('is_active', true))
            ->when($status === 'inactive', fn ($query) => $query->where('is_active', false))
            ->when($availability === 'available', fn ($query) => $query->where('is_available', true))
            ->when($availability === 'unavailable', fn ($query) => $query->where('is_available', false))
            ->orderBy('name')
            ->paginate(12)
            ->withQueryString();

        return Inertia::render('Products/Index', [
            'products' => $products,
            'categories' => Category::query()
                ->where('business_id', $businessId)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(['id', 'name', 'is_active']),
            'filters' => [
                'q' => $search,
                'category_id' => $categoryId,
                'status' => $status,
                'availability' => $availability,
            ],
            'canManage' => $request->user()->hasPermission('products.manage'),
        ]);
    }

    public function store(ProductRequest $request, SaveProduct $action): RedirectResponse
    {
        $this->authorize('create', Product::class);

        $action->handle($request->validated(), $request->user()->business_id);

        return back()->with('success', 'Produk berhasil dibuat.');
    }

    public function update(ProductRequest $request, Product $product, SaveProduct $action): RedirectResponse
    {
        $this->authorize('update', $product);

        $action->handle($request->validated(), $request->user()->business_id, $product);

        return back()->with('success', 'Produk berhasil diperbarui.');
    }

    public function toggle(Request $request, Product $product, string $field, ToggleProductAvailability $action): RedirectResponse
    {
        $this->authorize('update', $product);

        $action->handle($product, $field);

        return back()->with('success', 'Status produk diperbarui.');
    }
}
