import { Link, usePage } from '@inertiajs/react';
import { HiX } from 'react-icons/hi';
import { MdPointOfSale } from 'react-icons/md';
import { activeItem, visibleNavigation } from '@/lib/navigation';

export default function Sidebar({ open, onClose }) {
    const page = usePage();
    const { auth, business, outlet, pendingPaymentsCount } = page.props;
    const pathname = page.url.split('?')[0];
    const active = activeItem(pathname);
    const groups = visibleNavigation(auth?.permissions || []);

    return (
        <aside
            className={`fixed left-0 top-0 z-[60] flex h-screen w-[290px] flex-col bg-white pb-6 shadow-2xl shadow-navy-900/5 transition-transform duration-200 dark:bg-navy-800 xl:z-40 xl:translate-x-0 ${
                open ? 'translate-x-0' : '-translate-x-full'
            }`}
        >
            <button
                type="button"
                onClick={onClose}
                className="absolute right-4 top-4 rounded-full p-2 text-gray-500 hover:bg-lightPrimary dark:hover:bg-white/10 xl:hidden"
                aria-label="Tutup menu"
            >
                <HiX className="h-5 w-5" />
            </button>

            <div className="flex items-center gap-3 px-6 pb-6 pt-7">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-brand-400 to-brand-700 font-poppins text-2xl font-extrabold text-white shadow-lg shadow-brand-500/30">
                    R
                </div>
                <div className="min-w-0">
                    <p className="truncate font-poppins text-base font-extrabold tracking-tight text-navy-700 dark:text-white">
                        RUJAK.IN.SIAK
                    </p>
                    <p className="text-[11px] font-bold uppercase tracking-[0.18em] text-brand-500 dark:text-brand-300">
                        POS Back-office
                    </p>
                </div>
            </div>

            <div className="mx-6 h-px bg-gray-200 dark:bg-white/10" />

            <nav className="mt-5 flex-1 overflow-y-auto px-3">
                {groups.map((group) => (
                    <div key={group.label} className="mb-5">
                        <p className="mb-2 px-4 text-[10px] font-extrabold uppercase tracking-[0.2em] text-gray-400">
                            {group.label}
                        </p>
                        <ul className="space-y-1">
                            {group.items.map((item) => {
                                const Icon = item.icon;
                                const isActive = active?.href === item.href;
                                const badge = item.badge ? page.props[item.badge] : 0;
                                return (
                                    <li key={item.href}>
                                        <Link
                                            href={item.href}
                                            onClick={onClose}
                                            className={`group relative flex items-center gap-3 rounded-xl px-4 py-2.5 text-sm transition ${
                                                isActive
                                                    ? 'bg-brand-50 font-bold text-brand-600 dark:bg-brand-500/10 dark:text-brand-300'
                                                    : 'font-medium text-gray-600 hover:bg-lightPrimary hover:text-navy-700 dark:text-gray-400 dark:hover:bg-white/5 dark:hover:text-white'
                                            }`}
                                        >
                                            <Icon className="h-5 w-5 shrink-0" />
                                            <span className="flex-1">{item.name}</span>
                                            {badge > 0 ? (
                                                <span className="inline-flex min-w-5 items-center justify-center rounded-full bg-red-500 px-1.5 py-0.5 text-[10px] font-bold text-white">
                                                    {badge > 99 ? '99+' : badge}
                                                </span>
                                            ) : null}
                                            {isActive ? (
                                                <span className="absolute right-0 top-1/2 h-6 w-1 -translate-y-1/2 rounded-l-full bg-brand-500" />
                                            ) : null}
                                        </Link>
                                    </li>
                                );
                            })}
                        </ul>
                    </div>
                ))}
            </nav>

            <div className="mx-4 mt-2 rounded-2xl bg-lightPrimary p-4 dark:bg-navy-900">
                <div className="flex items-center gap-2 text-brand-500 dark:text-brand-300">
                    <MdPointOfSale className="h-5 w-5" />
                    <p className="text-xs font-bold uppercase tracking-wide">Outlet aktif</p>
                </div>
                <p className="mt-2 truncate font-poppins text-sm font-bold text-navy-700 dark:text-white">
                    {outlet?.name || business?.name || 'Belum dikonfigurasi'}
                </p>
                <p className="mt-1 text-[11px] leading-4 text-gray-600 dark:text-gray-400">
                    Transaksi kasir tetap dilakukan melalui aplikasi Flutter Android.
                </p>
                <p className="mt-3 text-[10px] font-bold uppercase tracking-[0.18em] text-gray-400">
                    Web admin v{page.props.app?.version || '1.0.0'}
                </p>
            </div>
        </aside>
    );
}
