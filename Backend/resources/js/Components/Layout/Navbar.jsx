import { Link, usePage } from '@inertiajs/react';
import { useEffect, useState } from 'react';
import { FiAlignJustify, FiLogOut, FiMoon, FiSun } from 'react-icons/fi';
import { HiOutlineBell } from 'react-icons/hi';
import Dropdown from '@/Components/Horizon/Dropdown';
import { activeItem } from '@/lib/navigation';
import { initials } from '@/lib/format';

export default function Navbar({ onOpenSidebar }) {
    const page = usePage();
    const { auth, business, pendingPaymentsCount } = page.props;
    const pathname = page.url.split('?')[0];
    const active = activeItem(pathname);
    const [dark, setDark] = useState(() => document.documentElement.classList.contains('dark'));

    useEffect(() => {
        if (dark) {
            document.documentElement.classList.add('dark');
            localStorage.setItem('rujak-theme', 'dark');
        } else {
            document.documentElement.classList.remove('dark');
            localStorage.setItem('rujak-theme', 'light');
        }
    }, [dark]);

    const roleLabel = (auth?.roles || [])
        .map((role) => ({ owner: 'Owner', admin: 'Admin', supervisor: 'Supervisor', kasir: 'Kasir' }[role] || role))
        .join(', ');

    return (
        <header className="sticky top-3 z-40 flex flex-wrap items-center justify-between gap-3 rounded-2xl bg-white/70 p-3 shadow-sm backdrop-blur-xl dark:bg-navy-800/70 md:flex-nowrap">
            <div className="flex min-w-0 items-center gap-3">
                <button
                    type="button"
                    onClick={onOpenSidebar}
                    className="rounded-xl bg-lightPrimary p-2.5 text-navy-700 transition hover:bg-brand-50 dark:bg-white/5 dark:text-white xl:hidden"
                    aria-label="Buka menu"
                >
                    <FiAlignJustify className="h-5 w-5" />
                </button>
                <div className="min-w-0">
                    <p className="truncate text-xs font-medium text-gray-500 dark:text-gray-400">
                        Back-office <span className="mx-1">/</span>
                        <span className="text-brand-500 dark:text-brand-300">{active?.name || 'Dashboard'}</span>
                    </p>
                    <h2 className="truncate font-poppins text-lg font-bold text-navy-700 dark:text-white md:text-xl">
                        {active?.name || 'Dashboard'}
                    </h2>
                </div>
            </div>

            <div className="flex items-center gap-1.5 sm:gap-2">
                <div className="hidden max-w-[190px] truncate rounded-xl bg-lightPrimary px-3 py-2 text-xs font-medium text-gray-600 dark:bg-white/5 dark:text-gray-300 lg:block">
                    {business?.name || 'Rujak In Siak'}
                </div>

                <Link
                    href="/payments/pending"
                    className="relative rounded-xl bg-lightPrimary p-2.5 text-gray-600 transition hover:bg-brand-50 hover:text-brand-500 dark:bg-white/5 dark:text-gray-300 dark:hover:bg-white/10"
                    aria-label="Pembayaran menunggu verifikasi"
                >
                    <HiOutlineBell className="h-5 w-5" />
                    {pendingPaymentsCount > 0 ? (
                        <span className="absolute -right-1 -top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
                            {pendingPaymentsCount > 99 ? '99+' : pendingPaymentsCount}
                        </span>
                    ) : null}
                </Link>

                <button
                    type="button"
                    onClick={() => setDark((value) => !value)}
                    className="rounded-xl bg-lightPrimary p-2.5 text-gray-600 transition hover:bg-brand-50 hover:text-brand-500 dark:bg-white/5 dark:text-gray-300 dark:hover:bg-white/10"
                    aria-label="Ubah tema"
                >
                    {dark ? <FiSun className="h-5 w-5" /> : <FiMoon className="h-5 w-5" />}
                </button>

                <Dropdown
                    classNames="top-12 right-0 w-64"
                    button={
                        <span className="flex items-center gap-2 rounded-xl bg-lightPrimary px-2 py-1.5 pr-3 dark:bg-white/5">
                            <span className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-500 text-xs font-bold text-white">
                                {initials(auth?.user?.name)}
                            </span>
                            <span className="hidden max-w-[110px] truncate text-left text-xs font-bold text-navy-700 dark:text-white sm:block">
                                {auth?.user?.name}
                            </span>
                        </span>
                    }
                >
                    <div className="overflow-hidden rounded-2xl bg-white shadow-xl shadow-navy-900/10 dark:bg-navy-700 dark:shadow-none">
                        <div className="border-b border-gray-100 p-4 dark:border-white/10">
                            <p className="truncate text-sm font-bold text-navy-700 dark:text-white">{auth?.user?.name}</p>
                            <p className="mt-0.5 truncate text-xs text-gray-500 dark:text-gray-400">{roleLabel}</p>
                            <p className="mt-0.5 truncate text-xs text-gray-500 dark:text-gray-400">{auth?.user?.email}</p>
                        </div>
                        <Link
                            href="/logout"
                            method="post"
                            as="button"
                            className="flex w-full items-center gap-2 px-4 py-3 text-left text-sm font-medium text-red-500 transition hover:bg-red-50 dark:hover:bg-red-500/10"
                        >
                            <FiLogOut className="h-4 w-4" />
                            Keluar
                        </Link>
                    </div>
                </Dropdown>
            </div>
        </header>
    );
}
