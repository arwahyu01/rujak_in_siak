<?php

namespace App\Http\Controllers\Api\V1;

use App\Actions\Catalog\SaveProduct;
use App\Http\Controllers\Controller;
use App\Http\Requests\Catalog\ProductRequest;
use App\Http\Resources\CategoryResource;
use App\Http\Resources\ProductResource;
use App\Models\Category;
use App\Models\Product;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class CatalogController extends Controller
{
    public const OFFLINE_CATALOG_MAX_AGE_HOURS = 72;

    public function categories(Request $request): JsonResponse
    {
        // POS catalog access is granted through the products permission.
        $this->authorize('viewAny', Product::class);

        $businessId = $request->user()->business_id;
        $includeInactive = $request->boolean('include_inactive');
        $updatedSince = $this->updatedSince($request);

        $categories = Category::query()
            ->where('business_id', $businessId)
            ->withCount(['products' => fn ($query) => $query
                ->where('is_active', true)
                ->where('is_available', true)])
            ->when(! $includeInactive, fn ($query) => $query->where('is_active', true))
            ->when($updatedSince, fn ($query, $since) => $query->where('updated_at', '>', $since))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return ApiResponse::data(
            CategoryResource::collection($categories),
            meta: $this->catalogMeta($businessId),
        );
    }

    public function products(Request $request): JsonResponse
    {
        $this->authorize('viewAny', Product::class);

        $businessId = $request->user()->business_id;
        $includeInactive = $request->boolean('include_inactive');
        $search = trim((string) $request->query('q'));
        $perPage = min(max((int) $request->query('per_page', 100), 1), 200);
        $updatedSince = $this->updatedSince($request);

        $products = Product::query()
            ->where('business_id', $businessId)
            ->with(['category', 'variants', 'addons'])
            ->when(! $includeInactive, fn ($query) => $query->where('is_active', true))
            ->when(! $includeInactive && ! $request->boolean('include_unavailable'),
                fn ($query) => $query->where('is_available', true))
            ->when($request->filled('category_uuid'), fn ($query) => $query
                ->whereHas('category', fn ($category) => $category
                    ->where('uuid', $request->query('category_uuid'))
                    ->where('business_id', $businessId)))
            ->when($search !== '', fn ($query) => $query->where(function ($query) use ($search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('sku', 'like', "%{$search}%")
                    ->orWhere('barcode', 'like', "%{$search}%");
            }))
            ->when($updatedSince, fn ($query, $since) => $query->where('updated_at', '>', $since))
            ->orderBy('name')
            ->paginate($perPage)
            ->withQueryString();

        return ApiResponse::data(
            ProductResource::collection($products),
            meta: $this->catalogMeta($businessId) + [
                'pagination' => [
                    'current_page' => $products->currentPage(),
                    'per_page' => $products->perPage(),
                    'total' => $products->total(),
                    'last_page' => $products->lastPage(),
                ],
            ],
        );
    }

    public function storeProduct(ProductRequest $request, SaveProduct $action): JsonResponse
    {
        $this->authorize('create', Product::class);

        $product = $action->handle($request->validated(), $request->user()->business_id);

        return ApiResponse::data(
            new ProductResource($product->load(['category', 'variants', 'addons'])),
            201,
        );
    }

    public function updateProduct(ProductRequest $request, Product $product, SaveProduct $action): JsonResponse
    {
        $this->authorize('update', $product);

        $data = $request->validated();
        if (array_key_exists('is_active', $data) && $data['is_active'] === null) {
            $data['is_active'] = $product->is_active;
        }
        if (array_key_exists('is_available', $data) && $data['is_available'] === null) {
            $data['is_available'] = $product->is_available;
        }

        $product = $action->handle($data, $request->user()->business_id, $product);

        return ApiResponse::data(
            new ProductResource($product->load(['category', 'variants', 'addons'])),
        );
    }

    private function updatedSince(Request $request): ?Carbon
    {
        $value = $request->query('updated_since');
        if (! is_string($value) || trim($value) === '') {
            return null;
        }

        try {
            return Carbon::parse($value);
        } catch (\Throwable) {
            return null;
        }
    }

    private function catalogMeta(int $businessId): array
    {
        $productVersion = Product::query()->where('business_id', $businessId)->max('updated_at');
        $categoryVersion = Category::query()->where('business_id', $businessId)->max('updated_at');
        $latest = collect([$productVersion, $categoryVersion])->filter()->max();

        return [
            'generated_at' => now()->toIso8601String(),
            'catalog_version' => $latest ? Carbon::parse($latest)->toIso8601String() : null,
            'offline_catalog_max_age_hours' => self::OFFLINE_CATALOG_MAX_AGE_HOURS,
        ];
    }
}
