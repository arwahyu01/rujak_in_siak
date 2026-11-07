import {
    MdAdminPanelSettings,
    MdBarChart,
    MdHistory,
    MdHome,
    MdOutlineCategory,
    MdOutlineFastfood,
    MdOutlineSchedule,
    MdPeople,
    MdReceiptLong,
    MdSettings,
    MdSync,
    MdVerifiedUser,
} from 'react-icons/md';

export const navigation = [
    {
        label: 'Ringkasan',
        items: [
            {
                name: 'Dashboard',
                href: '/dashboard',
                icon: MdHome,
                permission: 'dashboard.view',
            },
        ],
    },
    {
        label: 'Katalog',
        items: [
            {
                name: 'Kategori',
                href: '/categories',
                icon: MdOutlineCategory,
                permission: 'categories.view',
            },
            {
                name: 'Produk',
                href: '/products',
                icon: MdOutlineFastfood,
                permission: 'products.view',
            },
        ],
    },
    {
        label: 'Penjualan',
        items: [
            {
                name: 'Transaksi',
                href: '/sales',
                icon: MdReceiptLong,
                permission: 'sales.view',
            },
            {
                name: 'Verifikasi Pembayaran',
                href: '/payments/pending',
                icon: MdVerifiedUser,
                permission: 'payments.view_pending',
                badge: 'pendingPaymentsCount',
            },
        ],
    },
    {
        label: 'Operasional',
        items: [
            {
                name: 'Monitoring Shift',
                href: '/shifts',
                icon: MdOutlineSchedule,
                permission: 'shifts.view',
            },
            {
                name: 'Sinkronisasi',
                href: '/sync',
                icon: MdSync,
                permission: 'sync.view',
            },
        ],
    },
    {
        label: 'Analitik',
        items: [
            {
                name: 'Laporan',
                href: '/reports',
                icon: MdBarChart,
                permission: 'reports.view',
            },
        ],
    },
    {
        label: 'Administrasi',
        items: [
            {
                name: 'Pengguna',
                href: '/users',
                icon: MdPeople,
                permission: 'users.view',
            },
            {
                name: 'Peran & Hak Akses',
                href: '/roles',
                icon: MdAdminPanelSettings,
                permission: 'roles.manage',
            },
            {
                name: 'Audit Log',
                href: '/audit-logs',
                icon: MdHistory,
                permission: 'audit.view',
            },
            {
                name: 'Pengaturan Bisnis',
                href: '/settings/business',
                icon: MdSettings,
                permission: 'settings.manage',
            },
        ],
    },
];

export function visibleNavigation(permissions = []) {
    return navigation
        .map((group) => ({
            ...group,
            items: group.items.filter((item) => permissions.includes(item.permission)),
        }))
        .filter((group) => group.items.length > 0);
}

export function activeItem(pathname) {
    const flat = navigation.flatMap((group) => group.items);
    return flat
        .filter((item) => pathname === item.href || pathname.startsWith(`${item.href}/`))
        .sort((a, b) => b.href.length - a.href.length)[0];
}
