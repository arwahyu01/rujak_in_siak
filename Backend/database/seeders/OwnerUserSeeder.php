<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Outlet;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class OwnerUserSeeder extends Seeder
{
    public function run(): void
    {
        $business = Business::query()->firstOrFail();
        $outlet = Outlet::query()->where('business_id', $business->id)->first();

        $owner = User::query()->firstOrCreate(
            ['email' => env('ADMIN_EMAIL', 'owner@rujakinsiak.test')],
            [
                'uuid' => (string) Str::uuid(),
                'name' => env('ADMIN_NAME', 'Owner Rujak In Siak'),
                'username' => 'owner',
                'phone' => null,
                'password' => env('ADMIN_PASSWORD', 'password'),
                'business_id' => $business->id,
                'outlet_id' => $outlet?->id,
                'is_active' => true,
                'email_verified_at' => now(),
            ],
        );

        $ownerRole = Role::query()->where('slug', 'owner')->firstOrFail();
        $owner->roles()->syncWithoutDetaching([$ownerRole->id]);
    }
}
