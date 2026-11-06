<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Outlet;
use Illuminate\Support\Str;

class OrderNumberService
{
    public function next(int $businessId, Outlet $outlet): string
    {
        do {
            $number = sprintf(
                'ORD-%s-%s-%s',
                strtoupper($outlet->code),
                now()->format('ymd'),
                strtoupper(Str::random(6)),
            );
        } while (Order::query()->where('business_id', $businessId)->where('order_number', $number)->exists());

        return $number;
    }
}
