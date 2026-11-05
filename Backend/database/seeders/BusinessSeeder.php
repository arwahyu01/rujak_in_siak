<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Outlet;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class BusinessSeeder extends Seeder
{
    public function run(): void
    {
        $business = Business::firstOrCreate(
            ['name' => 'Rujak In Siak'],
            [
                'uuid' => (string) Str::uuid(),
                'address' => null,
                'phone' => null,
                'email' => null,
                'currency' => 'IDR',
                'timezone' => 'Asia/Jakarta',
                'tax_enabled' => false,
                'service_charge_enabled' => false,
                'is_active' => true,
            ],
        );

        Outlet::firstOrCreate(
            ['business_id' => $business->id, 'code' => 'PUSAT'],
            [
                'uuid' => (string) Str::uuid(),
                'name' => 'Rujak In Siak Pusat',
                'address' => null,
                'phone' => null,
                'is_active' => true,
            ],
        );
    }
}
