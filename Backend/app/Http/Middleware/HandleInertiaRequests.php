<?php

namespace App\Http\Middleware;

use App\Models\SalePayment;
use Illuminate\Foundation\Inspiring;
use Illuminate\Http\Request;
use Inertia\Middleware;

class HandleInertiaRequests extends Middleware
{
    protected $rootView = 'app';

    public function version(Request $request): ?string
    {
        return parent::version($request);
    }

    public function share(Request $request): array
    {
        $user = $request->user();

        return array_merge(parent::share($request), [
            'app' => [
                'name' => config('app.name', 'RUJAK.IN.SIAK POS'),
                'version' => '1.0.0',
            ],
            'auth' => fn () => $user ? [
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'username' => $user->username,
                    'phone' => $user->phone,
                ],
                'roles' => $user->roles->pluck('slug')->values()->all(),
                'permissions' => $user->permissionSlugs(),
            ] : null,
            'business' => fn () => $user?->business ? [
                'id' => $user->business->id,
                'name' => $user->business->name,
                'currency' => $user->business->currency,
                'timezone' => $user->business->timezone,
            ] : null,
            'outlet' => fn () => $user?->outlet ? [
                'id' => $user->outlet->id,
                'name' => $user->outlet->name,
                'code' => $user->outlet->code,
            ] : null,
            'flash' => [
                'success' => fn () => $request->session()->get('success'),
                'error' => fn () => $request->session()->get('error'),
            ],
            'pendingPaymentsCount' => fn () => $user && $user->hasPermission('payments.view_pending')
                ? SalePayment::query()
                    ->where('status', SalePayment::STATUS_AWAITING_VERIFICATION)
                    ->whereHas('sale', fn ($query) => $query->where('business_id', $user->business_id))
                    ->count()
                : 0,
            'inspiration' => fn () => app()->runningInConsole() ? null : Inspiring::quote(),
        ]);
    }
}
