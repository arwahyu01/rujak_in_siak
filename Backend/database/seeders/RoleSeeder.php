<?php

namespace Database\Seeders;

use App\Models\Permission;
use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        $roles = [
            'owner' => [
                'name' => 'Owner',
                'description' => 'Seluruh data dan konfigurasi bisnis.',
            ],
            'admin' => [
                'name' => 'Admin',
                'description' => 'Pengelolaan operasional dan master data.',
            ],
            'supervisor' => [
                'name' => 'Supervisor',
                'description' => 'Monitoring dan persetujuan tindakan sensitif.',
            ],
            'kasir' => [
                'name' => 'Kasir',
                'description' => 'POS, pembayaran, shift, dan struk melalui aplikasi Android.',
            ],
        ];

        foreach ($roles as $slug => $attributes) {
            Role::updateOrCreate(
                ['slug' => $slug],
                [...$attributes, 'is_system' => true],
            );
        }

        $all = Permission::query()->pluck('id');

        $admin = Permission::query()
            ->whereIn('slug', [
                'admin.access',
                'dashboard.view',
                'categories.view',
                'categories.manage',
                'products.view',
                'products.manage',
                'sales.view',
                'sales.void',
                'sales.refund',
                'payments.view_pending',
                'payments.verify',
                'payments.reject',
                'shifts.view',
                'reports.view',
                'reports.export',
                'users.view',
                'audit.view',
                'sync.view',
            ])
            ->pluck('id');

        $supervisor = Permission::query()
            ->whereIn('slug', [
                'admin.access',
                'dashboard.view',
                'sales.view',
                'payments.view_pending',
                'payments.verify',
                'payments.reject',
                'payments.correct_amount',
                'shifts.view',
                'reports.view',
                'audit.view',
                'sync.view',
            ])
            ->pluck('id');

        $owner = Role::where('slug', 'owner')->firstOrFail();
        $adminRole = Role::where('slug', 'admin')->firstOrFail();
        $supervisorRole = Role::where('slug', 'supervisor')->firstOrFail();
        $kasirRole = Role::where('slug', 'kasir')->firstOrFail();

        $owner->permissions()->sync($all);
        $adminRole->permissions()->sync($admin);
        $supervisorRole->permissions()->sync($supervisor);
        $kasirRole->permissions()->sync([]);
    }
}
