<?php

namespace Database\Seeders;

use App\Models\Permission;
use Illuminate\Database\Seeder;

class PermissionSeeder extends Seeder
{
    /** @var array<string, array{0: string, 1: string}> */
    private array $permissions = [
        'dashboard.view' => ['Lihat dashboard', 'dashboard'],
        'categories.view' => ['Lihat kategori', 'categories'],
        'categories.manage' => ['Kelola kategori', 'categories'],
        'products.view' => ['Lihat produk', 'products'],
        'products.manage' => ['Kelola produk', 'products'],
        'orders.view' => ['Lihat pesanan', 'orders'],
        'orders.manage' => ['Kelola pesanan', 'orders'],
        'orders.override_table_conflict' => ['Override konflik meja', 'orders'],
        'sales.view' => ['Lihat transaksi', 'sales'],
        'sales.checkout' => ['Checkout transaksi', 'sales'],
        'sales.void' => ['Void transaksi', 'sales'],
        'sales.refund' => ['Refund transaksi', 'sales'],
        'payments.record' => ['Catat pembayaran', 'payments'],
        'payments.view_pending' => ['Lihat pembayaran menunggu verifikasi', 'payments'],
        'payments.verify' => ['Verifikasi pembayaran', 'payments'],
        'payments.reject' => ['Tolak pembayaran', 'payments'],
        'payments.correct_amount' => ['Koreksi nominal pembayaran', 'payments'],
        'shifts.view' => ['Lihat shift', 'shifts'],
        'shifts.manage' => ['Buka/tutup shift dan kas', 'shifts'],
        'shifts.reconcile' => ['Rekonsiliasi shift', 'shifts'],
        'devices.view' => ['Lihat perangkat', 'devices'],
        'devices.manage' => ['Kelola dan cabut perangkat', 'devices'],
        'reports.view' => ['Lihat laporan', 'reports'],
        'reports.export' => ['Ekspor laporan', 'reports'],
        'users.view' => ['Lihat pengguna', 'users'],
        'users.manage' => ['Kelola pengguna', 'users'],
        'roles.manage' => ['Kelola peran dan hak akses', 'roles'],
        'audit.view' => ['Lihat audit log', 'audit'],
        'sync.view' => ['Lihat status sinkronisasi', 'sync'],
        'admin.access' => ['Akses web back-office', 'admin'],
    ];

    public function run(): void
    {
        foreach ($this->permissions as $slug => [$name, $module]) {
            Permission::updateOrCreate(
                ['slug' => $slug],
                ['name' => $name, 'module' => $module],
            );
        }
    }
}
