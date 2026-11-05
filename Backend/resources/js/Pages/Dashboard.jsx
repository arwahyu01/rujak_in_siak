import { Link, router, usePage } from '@inertiajs/react';
import {
    MdAccountBalanceWallet,
    MdBarChart,
    MdCalculate,
    MdCheckCircle,
    MdPayments,
    MdReceiptLong,
    MdSync,
    MdWarning,
} from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import StatCard from '@/Components/UI/StatCard';
import Card from '@/Components/Horizon/Card';
import Badge from '@/Components/UI/Badge';
import EmptyState from '@/Components/UI/EmptyState';
import AreaChart from '@/Components/Charts/AreaChart';
import PieChart from '@/Components/Charts/PieChart';
import Button from '@/Components/UI/Button';
import {
    formatCompact,
    formatDateTime,
    formatMoney,
    formatNumber,
    formatRelative,
    paymentMethodLabels,
    paymentStatusLabels,
    statusTone,
} from '@/lib/format';

const periods = [
    { value: '7', label: '7 hari' },
    { value: '30', label: '30 hari' },
    { value: '90', label: '90 hari' },
    { value: 'month', label: 'Bulan ini' },
];

export default function Dashboard({
    period,
    metrics,
    daily_sales,
    top_products,
    payment_breakdown,
    shift_summary,
    sync,
    recent_sales,
    recent_pending_payments,
    filters,
}) {
    const { auth } = usePage().props;
    const canViewPayments = auth?.permissions?.includes('payments.view_pending');
    const canViewSync = auth?.permissions?.includes('sync.view');
    const hasSales = metrics.total_final_count > 0;
    const maxProduct = Math.max(...top_products.map((item) => item.quantity), 1);

    const paymentSeries = payment_breakdown.map((item) => item.total);
    const paymentLabels = payment_breakdown.map((item) => paymentMethodLabels[item.method] || item.method);

    return (
        <>
            <PageHeader
                eyebrow="Ringkasan operasional"
                title="Dashboard"
                description="Data penjualan, pembayaran, dan sinkronisasi dihitung langsung dari transaksi final yang tersimpan di backend."
            >
                <div className="flex flex-wrap items-center gap-1 rounded-xl bg-white p-1 shadow-sm dark:bg-navy-800">
                    {periods.map((item) => (
                        <button
                            key={item.value}
                            type="button"
                            onClick={() =>
                                router.get(
                                    '/dashboard',
                                    { period: item.value },
                                    { preserveState: true, preserveScroll: true, replace: true },
                                )
                            }
                            className={`rounded-lg px-3 py-2 text-xs font-bold transition ${
                                filters.period === item.value
                                    ? 'bg-brand-500 text-white'
                                    : 'text-gray-600 hover:bg-lightPrimary dark:text-gray-300 dark:hover:bg-white/5'
                            }`}
                        >
                            {item.label}
                        </button>
                    ))}
                </div>
                <Button
                    variant="secondary"
                    onClick={() => router.reload({ preserveScroll: true })}
                    title="Muat ulang data"
                >
                    <MdSync className="h-4 w-4" />
                    Muat ulang
                </Button>
            </PageHeader>

            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <StatCard
                    icon={<MdBarChart className="h-6 w-6" />}
                    label="Total Transaksi Final"
                    value={formatMoney(metrics.total_final)}
                    detail={`${formatNumber(metrics.total_final_count)} transaksi final`}
                />
                <StatCard
                    icon={<MdPayments className="h-6 w-6" />}
                    label="Pembayaran Diterima"
                    value={formatMoney(metrics.payments_received)}
                    detail={`${formatMoney(metrics.cash_total)} tunai + ${formatMoney(metrics.non_cash_total)} non-tunai`}
                    tone="green"
                />
                <StatCard
                    icon={<MdCheckCircle className="h-6 w-6" />}
                    label="Penjualan Lunas Terkonfirmasi"
                    value={formatMoney(metrics.paid_total)}
                    detail={`${formatNumber(metrics.paid_count)} transaksi lunas`}
                    tone="cyan"
                />
                <StatCard
                    icon={<MdWarning className="h-6 w-6" />}
                    label="Menunggu Verifikasi"
                    value={formatMoney(metrics.awaiting_total)}
                    detail={`${formatNumber(metrics.awaiting_count)} pembayaran pending`}
                    tone="amber"
                />
                <StatCard
                    icon={<MdCalculate className="h-6 w-6" />}
                    label="Rata-rata Transaksi"
                    value={formatMoney(metrics.average_transaction)}
                    detail="Dari transaksi lunas terkonfirmasi"
                    tone="navy"
                />
                <StatCard
                    icon={<MdAccountBalanceWallet className="h-6 w-6" />}
                    label="Diskon"
                    value={formatMoney(metrics.discount_total)}
                    detail="Diskon item dan transaksi"
                    tone="amber"
                />
                <StatCard
                    icon={<MdReceiptLong className="h-6 w-6" />}
                    label="Void"
                    value={formatMoney(metrics.void_total)}
                    detail={`${formatNumber(metrics.void_count)} transaksi di-void`}
                    tone="red"
                />
                <StatCard
                    icon={<MdPayments className="h-6 w-6" />}
                    label="Refund"
                    value={formatMoney(metrics.refund_total)}
                    detail="Refund tercatat pada periode"
                    tone="red"
                />
            </div>

            <div className="mt-5 grid grid-cols-1 gap-5 xl:grid-cols-3">
                <Card className="p-5 xl:col-span-2">
                    <div className="mb-4 flex flex-wrap items-start justify-between gap-3">
                        <div>
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Grafik Penjualan</h2>
                            <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                                Nilai transaksi final per hari ({period?.from || ''} s.d. {period?.to || ''})
                            </p>
                        </div>
                        <Badge tone="brand">Final</Badge>
                    </div>
                    {hasSales ? (
                        <AreaChart
                            series={[{ name: 'Total transaksi', data: daily_sales.map((item) => item.total) }]}
                            categories={daily_sales.map((item) => item.label)}
                            height={320}
                            formatter={formatCompact}
                        />
                    ) : (
                        <EmptyState
                            title="Belum ada transaksi final"
                            description="Grafik akan terisi setelah transaksi dari aplikasi POS tersinkronisasi ke server."
                        />
                    )}
                </Card>

                <Card className="p-5">
                    <div className="mb-2 flex items-start justify-between gap-3">
                        <div>
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Komposisi Pembayaran</h2>
                            <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                                Hanya pembayaran terkonfirmasi
                            </p>
                        </div>
                    </div>
                    {paymentSeries.length > 0 && paymentSeries.some((value) => value > 0) ? (
                        <PieChart series={paymentSeries} labels={paymentLabels} height={320} totalLabel="Diterima" />
                    ) : (
                        <EmptyState
                            compact
                            title="Belum ada pembayaran terkonfirmasi"
                            description="Pembayaran tunai dan non-tunai terkonfirmasi akan tampil di sini."
                        />
                    )}
                </Card>
            </div>

            <div className="mt-5 grid grid-cols-1 gap-5 xl:grid-cols-2">
                <Card className="p-5">
                    <div className="mb-4 flex items-center justify-between gap-3">
                        <div>
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Produk Terlaris</h2>
                            <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Berdasarkan kuantitas terjual</p>
                        </div>
                        <Link href="/reports?tab=products" className="text-xs font-bold text-brand-500 hover:text-brand-600">
                            Lihat laporan
                        </Link>
                    </div>
                    {top_products.length > 0 ? (
                        <ul className="space-y-4">
                            {top_products.map((product, index) => (
                                <li key={product.name}>
                                    <div className="mb-1.5 flex items-center justify-between gap-3 text-sm">
                                        <div className="flex min-w-0 items-center gap-2">
                                            <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-lg bg-lightPrimary text-xs font-bold text-brand-500 dark:bg-white/5 dark:text-brand-300">
                                                {index + 1}
                                            </span>
                                            <span className="truncate font-medium text-navy-700 dark:text-white">{product.name}</span>
                                        </div>
                                        <span className="shrink-0 text-xs text-gray-600 dark:text-gray-400">
                                            {formatNumber(product.quantity)}x · {formatMoney(product.revenue)}
                                        </span>
                                    </div>
                                    <div className="h-2 overflow-hidden rounded-full bg-lightPrimary dark:bg-white/5">
                                        <div
                                            className="h-full rounded-full bg-gradient-to-r from-brand-400 to-brand-600"
                                            style={{ width: `${Math.max((product.quantity / maxProduct) * 100, 4)}%` }}
                                        />
                                    </div>
                                </li>
                            ))}
                        </ul>
                    ) : (
                        <EmptyState compact title="Belum ada produk terjual" description="Data produk terlaris muncul setelah ada transaksi final." />
                    )}
                </Card>

                <Card className="p-5">
                    <div className="mb-4 flex items-center justify-between gap-3">
                        <div>
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Pembayaran Menunggu Verifikasi</h2>
                            <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                                Dipisahkan dari pembayaran lunas
                            </p>
                        </div>
                        {canViewPayments ? (
                            <Link href="/payments/pending" className="text-xs font-bold text-brand-500 hover:text-brand-600">
                                Buka antrean
                            </Link>
                        ) : null}
                    </div>
                    {recent_pending_payments.length > 0 ? (
                        <ul className="divide-y divide-gray-100 dark:divide-white/5">
                            {recent_pending_payments.map((payment) => (
                                <li key={payment.id} className="flex items-center justify-between gap-3 py-3 first:pt-0 last:pb-0">
                                    <div className="min-w-0">
                                        <Link
                                            href={`/sales/${payment.sale_id}`}
                                            className="truncate text-sm font-bold text-navy-700 hover:text-brand-500 dark:text-white"
                                        >
                                            {payment.receipt_number}
                                        </Link>
                                        <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                                            {paymentMethodLabels[payment.method] || payment.method} · dicatat {payment.recorded_by} ·{' '}
                                            {formatDateTime(payment.recorded_at)}
                                        </p>
                                    </div>
                                    <div className="shrink-0 text-right">
                                        <p className="text-sm font-bold text-navy-700 dark:text-white">{formatMoney(payment.amount)}</p>
                                        <Badge tone="warning">Pending</Badge>
                                    </div>
                                </li>
                            ))}
                        </ul>
                    ) : (
                        <EmptyState compact title="Tidak ada pembayaran pending" description="Semua pembayaran non-tunai telah diproses." />
                    )}
                </Card>
            </div>

            <div className="mt-5 grid grid-cols-1 gap-5 xl:grid-cols-3">
                <Card className="overflow-hidden xl:col-span-2">
                    <div className="flex items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                        <div>
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Transaksi Terbaru</h2>
                            <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Termasuk transaksi void dan pending</p>
                        </div>
                        <Link href="/sales" className="text-xs font-bold text-brand-500 hover:text-brand-600">
                            Semua transaksi
                        </Link>
                    </div>
                    {recent_sales.length > 0 ? (
                        <div className="overflow-x-auto">
                            <table className="horizon-table">
                                <thead>
                                    <tr>
                                        <th>Nomor</th>
                                        <th>Kasir</th>
                                        <th>Waktu</th>
                                        <th className="text-right">Total</th>
                                        <th>Pembayaran</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {recent_sales.map((sale) => (
                                        <tr key={sale.id}>
                                            <td>
                                                <Link
                                                    href={`/sales/${sale.id}`}
                                                    className="font-bold text-brand-500 hover:text-brand-600"
                                                >
                                                    {sale.receipt_number}
                                                </Link>
                                                {sale.lifecycle_status === 'voided' ? (
                                                    <Badge tone="danger" className="ml-2">
                                                        Void
                                                    </Badge>
                                                ) : null}
                                            </td>
                                            <td>{sale.cashier || '—'}</td>
                                            <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                                {formatDateTime(sale.transacted_at)}
                                            </td>
                                            <td className="text-right font-bold">{formatMoney(sale.total)}</td>
                                            <td>
                                                <Badge tone={statusTone(sale.payment_status)}>
                                                    {paymentStatusLabels[sale.payment_status] || sale.payment_status}
                                                </Badge>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    ) : (
                        <EmptyState title="Belum ada transaksi" description="Transaksi dari aplikasi POS akan muncul di sini setelah tersedia di backend." />
                    )}
                </Card>

                <div className="space-y-5">
                    <Card className="p-5">
                        <div className="flex items-center justify-between gap-3">
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Ringkasan Shift</h2>
                            {auth?.permissions?.includes('shifts.view') ? (
                                <Link href="/shifts" className="text-xs font-bold text-brand-500 hover:text-brand-600">
                                    Detail
                                </Link>
                            ) : null}
                        </div>
                        <div className="mt-4 grid grid-cols-2 gap-3">
                            <MiniStat label="Shift buka" value={formatNumber(shift_summary.open)} />
                            <MiniStat label="Pending sync" value={formatNumber(shift_summary.closed_pending_sync)} tone="amber" />
                            <MiniStat label="Terkonfirmasi" value={formatNumber(shift_summary.closed_confirmed)} tone="green" />
                            <MiniStat label="Sync exception" value={formatNumber(shift_summary.closed_sync_exception)} tone="red" />
                        </div>
                        <div className="mt-4 flex items-center justify-between rounded-xl bg-lightPrimary px-3 py-2.5 dark:bg-white/5">
                            <span className="text-xs text-gray-600 dark:text-gray-400">Total variance kas</span>
                            <span
                                className={`text-sm font-bold ${
                                    shift_summary.variance_total < 0 ? 'text-red-500' : 'text-navy-700 dark:text-white'
                                }`}
                            >
                                {formatMoney(shift_summary.variance_total)}
                            </span>
                        </div>
                    </Card>

                    <Card className="p-5">
                        <div className="flex items-center justify-between gap-3">
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Status Sinkronisasi</h2>
                            {canViewSync ? (
                                <Link href="/sync" className="text-xs font-bold text-brand-500 hover:text-brand-600">
                                    Monitor
                                </Link>
                            ) : null}
                        </div>
                        <div className="mt-4 grid grid-cols-2 gap-3">
                            <MiniStat label="Event pending" value={formatNumber(sync.pending)} tone="amber" />
                            <MiniStat label="Perlu perhatian" value={formatNumber(sync.issues)} tone="red" />
                        </div>
                        <p className="mt-4 text-xs text-gray-600 dark:text-gray-400">
                            Sinkronisasi terakhir diproses: <span className="font-bold text-navy-700 dark:text-white">{formatRelative(sync.last_processed_at)}</span>
                        </p>
                        <p className="mt-1 text-[11px] leading-5 text-gray-500 dark:text-gray-500">
                            Status dihitung dari event sinkronisasi aktual. Pemrosesan ulang manual belum tersedia pada backend MVP.
                        </p>
                    </Card>
                </div>
            </div>
        </>
    );
}

function MiniStat({ label, value, tone = 'brand' }) {
    const tones = {
        brand: 'text-brand-500 dark:text-brand-300',
        amber: 'text-amber-600 dark:text-amber-400',
        green: 'text-green-600 dark:text-green-400',
        red: 'text-red-500 dark:text-red-400',
    };
    return (
        <div className="rounded-xl bg-lightPrimary p-3 dark:bg-white/5">
            <p className="text-[11px] text-gray-600 dark:text-gray-400">{label}</p>
            <p className={`mt-1 font-poppins text-lg font-bold ${tones[tone]}`}>{value}</p>
        </div>
    );
}

Dashboard.layout = (page) => <AdminLayout>{page}</AdminLayout>;
