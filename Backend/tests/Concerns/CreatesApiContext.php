<?php

namespace Tests\Concerns;

use App\Models\Business;
use App\Models\Category;
use App\Models\Device;
use App\Models\Outlet;
use App\Models\Product;
use App\Models\Role;
use App\Models\Shift;
use App\Models\User;
use Database\Seeders\PermissionSeeder;
use Database\Seeders\RoleSeeder;
use Illuminate\Support\Str;

trait CreatesApiContext
{
    protected Business $business;

    protected Outlet $outlet;

    protected User $owner;

    protected Device $device;

    protected function createApiContext(): void
    {
        $this->seed([PermissionSeeder::class, RoleSeeder::class]);

        $this->business = Business::create([
            'uuid' => (string) Str::uuid(),
            'name' => 'Rujak In Siak',
            'currency' => 'IDR',
            'timezone' => 'Asia/Jakarta',
            'tax_enabled' => false,
            'tax_rate_basis_points' => 0,
            'service_charge_enabled' => false,
            'service_charge_rate_basis_points' => 0,
            'tax_includes_service_charge' => false,
            'is_active' => true,
        ]);

        $this->outlet = Outlet::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'name' => 'Pusat',
            'code' => 'PUSAT',
            'is_active' => true,
        ]);

        $this->owner = $this->makeUser('owner@rujak.test', 'owner', 'owner');
        $this->device = Device::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'outlet_id' => $this->outlet->id,
            'name' => 'Terminal 1',
            'terminal_code' => 'T01',
            'platform' => 'android',
            'status' => Device::STATUS_ACTIVE,
            'last_sequence' => 0,
            'last_seen_at' => now(),
            'activated_at' => now(),
        ]);
    }

    protected function makeUser(string $email, string $username, string $role = 'kasir'): User
    {
        $user = User::create([
            'uuid' => (string) Str::uuid(),
            'name' => ucfirst($username),
            'email' => $email,
            'username' => $username,
            'password' => 'password',
            'business_id' => $this->business->id,
            'outlet_id' => $this->outlet->id,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        $user->roles()->attach(Role::query()->where('slug', $role)->firstOrFail());

        return $user;
    }

    protected function headers(User $user, ?Device $device = null): array
    {
        return [
            'X-Device-Id' => ($device ?? $this->device)->uuid,
        ];
    }

    protected function makeDevice(string $terminalCode, ?int $outletId = null): Device
    {
        return Device::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'outlet_id' => $outletId ?? $this->outlet->id,
            'name' => 'Terminal '.$terminalCode,
            'terminal_code' => $terminalCode,
            'platform' => 'android',
            'status' => Device::STATUS_ACTIVE,
            'last_sequence' => 0,
            'last_seen_at' => now(),
            'activated_at' => now(),
        ]);
    }

    /**
     * @return array{0: Business, 1: Outlet, 2: User, 3: Device}
     */
    protected function makeTenant(string $suffix): array
    {
        $business = Business::create([
            'uuid' => (string) Str::uuid(),
            'name' => 'Tenant '.$suffix,
            'currency' => 'IDR',
            'timezone' => 'Asia/Jakarta',
            'tax_enabled' => false,
            'tax_rate_basis_points' => 0,
            'service_charge_enabled' => false,
            'service_charge_rate_basis_points' => 0,
            'tax_includes_service_charge' => false,
            'is_active' => true,
        ]);

        $outlet = Outlet::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $business->id,
            'name' => 'Outlet '.$suffix,
            'code' => strtoupper($suffix),
            'is_active' => true,
        ]);

        $user = User::create([
            'uuid' => (string) Str::uuid(),
            'name' => 'Owner '.$suffix,
            'email' => $suffix.'@rujak.test',
            'username' => $suffix,
            'password' => 'password',
            'business_id' => $business->id,
            'outlet_id' => $outlet->id,
            'is_active' => true,
            'email_verified_at' => now(),
        ]);
        $user->roles()->attach(Role::query()->where('slug', 'owner')->firstOrFail());

        $device = Device::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $business->id,
            'outlet_id' => $outlet->id,
            'name' => 'Terminal '.$suffix,
            'terminal_code' => strtoupper(substr($suffix, 0, 10)),
            'platform' => 'android',
            'status' => Device::STATUS_ACTIVE,
            'last_sequence' => 0,
            'last_seen_at' => now(),
            'activated_at' => now(),
        ]);

        return [$business, $outlet, $user, $device];
    }

    protected function openShift(User $user): Shift
    {
        return Shift::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'outlet_id' => $this->outlet->id,
            'user_id' => $user->id,
            'device_id' => $this->device->id,
            'status' => Shift::STATUS_OPEN,
            'opening_cash' => 100000,
            'expected_cash' => 100000,
            'opened_at' => now(),
        ]);
    }

    protected function makeProduct(int $price = 10000, array $attributes = []): Product
    {
        static $sequence = 0;
        $sequence++;

        return Product::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'sku' => 'SKU-'.$sequence,
            'name' => 'Rujak '.$sequence,
            'unit' => 'porsi',
            'price' => $price,
            'is_active' => true,
            'is_available' => true,
            ...$attributes,
        ]);
    }

    protected function makeCategory(array $attributes = []): Category
    {
        return Category::create([
            'uuid' => (string) Str::uuid(),
            'business_id' => $this->business->id,
            'name' => 'Kategori',
            'slug' => 'kategori-'.Str::lower(Str::random(6)),
            'sort_order' => 0,
            'is_active' => true,
            ...$attributes,
        ]);
    }
}
