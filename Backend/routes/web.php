<?php

use App\Http\Controllers\AuditLogController;
use App\Http\Controllers\Auth\AuthController;
use App\Http\Controllers\BusinessSettingsController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\RoleController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\ShiftController;
use App\Http\Controllers\SyncController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

Route::middleware('guest')->group(function () {
    Route::get('/login', [AuthController::class, 'create'])->name('login');
    Route::post('/login', [AuthController::class, 'store'])->name('login.store');
});

Route::middleware(['auth', 'permission:admin.access'])->group(function () {
    Route::post('/logout', [AuthController::class, 'destroy'])->name('logout');
    Route::get('/', fn () => redirect()->route('dashboard'))->name('home');

    Route::get('/dashboard', DashboardController::class)
        ->middleware('permission:dashboard.view')
        ->name('dashboard');

    Route::get('/categories', [CategoryController::class, 'index'])
        ->middleware('permission:categories.view')
        ->name('categories.index');
    Route::post('/categories', [CategoryController::class, 'store'])
        ->middleware('permission:categories.manage')
        ->name('categories.store');
    Route::put('/categories/{category}', [CategoryController::class, 'update'])
        ->middleware('permission:categories.manage')
        ->name('categories.update');
    Route::delete('/categories/{category}', [CategoryController::class, 'destroy'])
        ->middleware('permission:categories.manage')
        ->name('categories.destroy');

    Route::get('/products', [ProductController::class, 'index'])
        ->middleware('permission:products.view')
        ->name('products.index');
    Route::post('/products', [ProductController::class, 'store'])
        ->middleware('permission:products.manage')
        ->name('products.store');
    Route::post('/products/{product}', [ProductController::class, 'update'])
        ->middleware('permission:products.manage')
        ->name('products.update');
    Route::patch('/products/{product}/toggle/{field}', [ProductController::class, 'toggle'])
        ->where('field', 'is_active|is_available')
        ->middleware('permission:products.manage')
        ->name('products.toggle');

    Route::get('/sales', [SaleController::class, 'index'])
        ->middleware('permission:sales.view')
        ->name('sales.index');
    Route::get('/sales/{sale}', [SaleController::class, 'show'])
        ->middleware('permission:sales.view')
        ->name('sales.show');
    Route::post('/sales/{sale}/void', [SaleController::class, 'void'])
        ->middleware('permission:sales.void')
        ->name('sales.void');
    Route::post('/sales/{sale}/refund', [SaleController::class, 'refund'])
        ->middleware('permission:sales.refund')
        ->name('sales.refund');

    Route::get('/payments/pending', [PaymentController::class, 'pending'])
        ->middleware('permission:payments.view_pending')
        ->name('payments.pending');
    Route::get('/payments/{payment}/proof', [PaymentController::class, 'proof'])
        ->middleware('permission:payments.view_pending')
        ->name('payments.proof');
    Route::post('/payments/{payment}/verify', [PaymentController::class, 'verify'])
        ->middleware('permission:payments.verify')
        ->name('payments.verify');
    Route::post('/payments/{payment}/reject', [PaymentController::class, 'reject'])
        ->middleware('permission:payments.reject')
        ->name('payments.reject');

    Route::get('/shifts', [ShiftController::class, 'index'])
        ->middleware('permission:shifts.view')
        ->name('shifts.index');
    Route::get('/shifts/{shift}', [ShiftController::class, 'show'])
        ->middleware('permission:shifts.view')
        ->name('shifts.show');

    Route::get('/reports', [ReportController::class, 'index'])
        ->middleware('permission:reports.view')
        ->name('reports.index');
    Route::get('/reports/export', [ReportController::class, 'export'])
        ->middleware('permission:reports.export')
        ->name('reports.export');

    Route::get('/users', [UserController::class, 'index'])
        ->middleware('permission:users.view')
        ->name('users.index');
    Route::post('/users', [UserController::class, 'store'])
        ->middleware('permission:users.manage')
        ->name('users.store');
    Route::put('/users/{user}', [UserController::class, 'update'])
        ->middleware('permission:users.manage')
        ->name('users.update');

    Route::get('/roles', [RoleController::class, 'index'])
        ->middleware('permission:roles.manage')
        ->name('roles.index');
    Route::put('/roles/{role}', [RoleController::class, 'update'])
        ->middleware('permission:roles.manage')
        ->name('roles.update');

    Route::get('/audit-logs', [AuditLogController::class, 'index'])
        ->middleware('permission:audit.view')
        ->name('audit.index');

    Route::get('/settings/business', [BusinessSettingsController::class, 'edit'])
        ->middleware('permission:settings.manage')
        ->name('settings.business.edit');
    Route::put('/settings/business', [BusinessSettingsController::class, 'update'])
        ->middleware('permission:settings.manage')
        ->name('settings.business.update');

    Route::get('/sync', [SyncController::class, 'index'])
        ->middleware('permission:sync.view')
        ->name('sync.index');
});
