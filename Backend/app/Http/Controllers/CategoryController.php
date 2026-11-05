<?php

namespace App\Http\Controllers;

use App\Actions\Catalog\DeleteCategory;
use App\Actions\Catalog\SaveCategory;
use App\Http\Requests\Catalog\CategoryRequest;
use App\Models\Category;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class CategoryController extends Controller
{
    public function index(Request $request): Response
    {
        $this->authorize('viewAny', Category::class);

        $search = trim((string) $request->query('q'));
        $status = (string) $request->query('status', 'all');

        $categories = Category::query()
            ->where('business_id', $request->user()->business_id)
            ->withCount('products')
            ->when($search !== '', fn ($query) => $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('description', 'like', "%{$search}%");
            }))
            ->when($status === 'active', fn ($query) => $query->where('is_active', true))
            ->when($status === 'inactive', fn ($query) => $query->where('is_active', false))
            ->orderBy('sort_order')
            ->orderBy('name')
            ->paginate(15)
            ->withQueryString();

        return Inertia::render('Categories/Index', [
            'categories' => $categories,
            'filters' => [
                'q' => $search,
                'status' => $status,
            ],
            'canManage' => $request->user()->hasPermission('categories.manage'),
        ]);
    }

    public function store(CategoryRequest $request, SaveCategory $action): RedirectResponse
    {
        $this->authorize('create', Category::class);

        $action->handle($request->validated(), $request->user()->business_id);

        return back()->with('success', 'Kategori berhasil dibuat.');
    }

    public function update(CategoryRequest $request, Category $category, SaveCategory $action): RedirectResponse
    {
        $this->authorize('update', $category);

        $action->handle($request->validated(), $request->user()->business_id, $category);

        return back()->with('success', 'Kategori berhasil diperbarui.');
    }

    public function destroy(Request $request, Category $category, DeleteCategory $action): RedirectResponse
    {
        $this->authorize('delete', $category);

        $action->handle($category);

        return back()->with('success', 'Kategori dinonaktifkan.');
    }
}
