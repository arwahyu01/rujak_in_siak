<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\CatalogController;
use App\Http\Controllers\Api\V1\DeviceController;
use App\Http\Controllers\Api\V1\OrderController;
use App\Http\Controllers\Api\V1\PaymentController;
use App\Http\Controllers\Api\V1\ReportController;
use App\Http\Controllers\Api\V1\SaleController;
use App\Http\Controllers\Api\V1\ShiftController;
use App\Http\Controllers\Api\V1\SyncController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login'])->middleware('throttle:login');

    Route::middleware(['auth:sanctum', 'api.active'])->group(function () {
        Route::post('/auth/logout', [AuthController::class, 'logout']);
        Route::post('/auth/refresh', [AuthController::class, 'refresh']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/me/pin', [AuthController::class, 'updatePin'])->middleware('device.context');

        Route::post('/devices/register', [DeviceController::class, 'register']);
        Route::get('/devices', [DeviceController::class, 'index'])->middleware('permission:devices.view');
        Route::post('/devices/{device:uuid}/revoke', [DeviceController::class, 'revoke'])
            ->middleware('permission:devices.manage');

        Route::post('/auth/offline-lease', [AuthController::class, 'offlineLease'])
            ->middleware('device.context');

        Route::middleware(['device.context', 'throttle:api'])->group(function () {
            Route::get('/categories', [CatalogController::class, 'categories'])->middleware('permission:products.view');
            Route::get('/products', [CatalogController::class, 'products'])->middleware('permission:products.view');
            Route::post('/products', [CatalogController::class, 'storeProduct'])->middleware('permission:products.manage');
            Route::put('/products/{product:uuid}', [CatalogController::class, 'updateProduct'])->middleware('permission:products.manage');

            Route::get('/orders', [OrderController::class, 'index'])->middleware('permission:orders.view');
            Route::post('/orders', [OrderController::class, 'store'])->middleware('permission:orders.manage');
            Route::get('/orders/{order:uuid}', [OrderController::class, 'show'])->middleware('permission:orders.view');
            Route::put('/orders/{order:uuid}', [OrderController::class, 'update'])->middleware('permission:orders.manage');
            Route::post('/orders/{order:uuid}/hold', [OrderController::class, 'hold'])->middleware('permission:orders.manage');
            Route::post('/orders/{order:uuid}/resume', [OrderController::class, 'resume'])->middleware('permission:orders.manage');
            Route::post('/orders/{order:uuid}/cancel', [OrderController::class, 'cancel'])->middleware('permission:orders.manage');

            Route::get('/sales', [SaleController::class, 'index'])->middleware('permission:sales.view');
            Route::post('/sales/checkout', [SaleController::class, 'checkout'])->middleware('permission:sales.checkout');
            Route::get('/sales/{sale:uuid}', [SaleController::class, 'show'])->middleware('permission:sales.view');
            Route::post('/sales/{sale:uuid}/void', [SaleController::class, 'void'])->middleware('permission:sales.void');
            Route::post('/sales/{sale:uuid}/refund', [SaleController::class, 'refund'])->middleware('permission:sales.refund');
            Route::post('/sales/{sale:uuid}/payments', [SaleController::class, 'recordPayment'])->middleware('permission:payments.record');

            Route::get('/payments/pending-verification', [PaymentController::class, 'pending'])->middleware('permission:payments.view_pending');
            Route::get('/payments/{payment:uuid}', [PaymentController::class, 'show'])->middleware('permission:payments.view_pending');
            Route::post('/payments/{payment:uuid}/verify', [PaymentController::class, 'verify'])->middleware('permission:payments.verify');
            Route::post('/payments/{payment:uuid}/reject', [PaymentController::class, 'reject'])->middleware('permission:payments.reject');

            Route::get('/shifts', [ShiftController::class, 'index'])->middleware('permission:shifts.view');
            Route::post('/shifts/open', [ShiftController::class, 'open'])->middleware('permission:shifts.manage');
            Route::post('/shifts/close', [ShiftController::class, 'close'])->middleware('permission:shifts.manage');
            Route::get('/shifts/{shift:uuid}', [ShiftController::class, 'show'])->middleware('permission:shifts.view');
            Route::post('/shifts/{shift:uuid}/cash-movements', [ShiftController::class, 'cashMovement'])->middleware('permission:shifts.manage');
            Route::post('/shifts/{shift:uuid}/reconcile', [ShiftController::class, 'reconcile'])->middleware('permission:shifts.reconcile');

            Route::post('/sync/push', [SyncController::class, 'push'])->middleware('throttle:sync-push');
            Route::get('/sync/pull', [SyncController::class, 'pull']);
            Route::get('/sync/bootstrap', [SyncController::class, 'bootstrap']);
            Route::get('/sync/status', [SyncController::class, 'status']);

            Route::get('/reports/sales', [ReportController::class, 'sales'])->middleware('permission:reports.view');
            Route::get('/reports/payments', [ReportController::class, 'payments'])->middleware('permission:reports.view');
            Route::get('/reports/products', [ReportController::class, 'products'])->middleware('permission:reports.view');
            Route::get('/reports/shifts', [ReportController::class, 'shifts'])->middleware('permission:reports.view');
        });
    });
});
