import { Head, router } from '@inertiajs/react';
import { useState } from 'react';
import {
    MdBarChart,
    MdDownload,
    MdOutlinePayments,
    MdOutlineReceiptLong,
    MdOutlineSchedule,
    MdOutlineFastfood,
} from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import Card from '@/Components/Horizon/Card';
import StatCard from '@/Components/UI/StatCard';
import TableShell from '@/Components/UI/TableShell';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import InputField from '@/Components/UI/InputField';
import AreaChart from '@/Components/Charts/AreaChart';
import BarChart from '@/Components/Charts/BarChart';
import {
    formatCompact,
    formatDate,
    formatDateTime,
    formatMoney,
    formatNumber,
    orderTypeLabels,
    paymentEntryStatusLabels,
    paymentMethodLabels,
    shiftStatusLabels,
    statusTone,
} from '@/lib/format';

const tabs = [
    { key: 'sales', label: 'Penjualan', icon: MdOutlineReceiptLong },
    { key: 'payments', label: 'Pembayaran', icon: MdOutlinePayments },
    { key: 'products', label: 'Produk', icon: MdOutlineFastfood },
    { key: 'shifts', label: 'Shift', icon: MdOutlineSchedule },
];

export default function ReportsIndex({ tab, report, filters, canExport }) {
    const [form, setForm] = useState({ from: filters.from, to: filters.to });

    const goTab = (nextTab) => {
        router.get('/reports', { tab: nextTab, from: form.from, to: form.to }, { preserveState: false, preserveScroll: true });
    };

    const submit = (event) => {
        event.preventDefault();
        router.get('/reports', { tab, from: form.from, to: form.to }, { preserveState: true, preserveScroll: true });
    };

    const exportUrl = `/reports/export?tab=${tab}&from=${form.from}&to=${form.to}`;

    return (
        <>
            <Head title="Laporan" />
            <PageHeader
                eyebrow="Analitik MVP"
                title="Laporan"
                description={`Periode ${formatDate(filters.from)} – ${formatDate(filters.to)}. Laporan dihitung dari transaksi final yang tersimpan di backend.`}
            >
                {canExport ? (
                    <a href={exportUrl}>
                        <Button variant="secondary">
                            <MdDownload className="h-4 w-4" />
                            Ekspor CSV
                        </Button>
                    </a>
                ) : null}
            </PageHeader>

            <div className="mb-5 flex flex-wrap items-center gap-2 rounded-2xl bg-white p-2 shadow-sm dark:bg-navy-800">
                {tabs.map((item) => {
                    const Icon = item.icon;
                    return (
                        <button
                            key={item.key}
                            type="button"
                            onClick={() => goTab(item.key)}
                            className={`inline-flex items-center gap-2 rounded-xl px-4 py-2.5 text-sm font-bold transition ${
                                tab === item.key
                                    ? 'bg-brand-500 text-white shadow-lg shadow-brand-500/20'
                                    : 'text-gray-600 hover:bg-lightPrimary dark:text-gray-300 dark:hover:bg-white/5'
                            }`}
                        >
                            <Icon className="h-5 w-5" />
                            {item.label}
                        </button>
                    );
                })}
            </div>

            <form onSubmit={submit} className="mb-5 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 sm:flex-row sm:items-end">
                <InputField
                    id="from"
                    label="Dari tanggal"
                    type="date"
                    value={form.from}
                    onChange={(event) => setForm((current) => ({ ...current, from: event.target.value }))}
                    className="sm:w-52"
                />
                <InputField
                    id="to"
                    label="Sampai tanggal"
                    type="date"
                    value={form.to}
                    onChange={(event) => setForm((current) => ({ ...current, to: event.target.value }))}
                    className="sm:w-52"
                />
                <Button type="submit" variant="primary">
                    Terapkan periode
                </Button>
            </form>

            {tab === 'sales' ? <SalesReport report={report} /> : null}
            {tab === 'payments' ? <PaymentsReport report={report} /> : null}
            {tab === 'products' ? <ProductsReport report={report} /> : null}
            {tab === 'shifts' ? <ShiftsReport report={report} /> : null}
        </>
    );
}

function SalesReport({ report }) {
    const { summary, daily, by_cashier, by_order_type } = report;
    const hasDaily = daily.length > 0;

    return (
        <div className="space-y-5">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <StatCard
                    icon={<MdOutlineReceiptLong className="h-6 w-6" />}
                    label="Transaksi final"
                    value={formatNumber(summary.transactions)}
                    detail={`Total ${formatMoney(summary.total)}`}
                />
                <StatCard
                    icon={<MdBarChart className="h-6 w-6" />}
                    label="Diskon"
                    value={formatMoney(summary.discounts)}
                    detail="Total diskon transaksi final"
                    tone="amber"
                />
                <StatCard
                    icon={<MdOutlinePayments className="h-6 w-6" />}
                    label="Pajak & service"
                    value={formatMoney(summary.tax + summary.service_charge)}
                    detail={`Pajak ${formatMoney(summary.tax)} · service ${formatMoney(summary.service_charge)}`}
                    tone="cyan"
                />
                <StatCard
                    icon={<MdOutlineReceiptLong className="h-6 w-6" />}
                    label="Void"
                    value={formatNumber(summary.voided_transactions)}
                    detail={`Nilai ${formatMoney(summary.voided_total)}`}
                    tone="red"
                />
            </div>

            <Card className="p-5">
                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Penjualan Harian</h2>
                <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Hanya transaksi final pada periode terpilih.</p>
                <div className="mt-4">
                    {hasDaily ? (
                        <AreaChart
                            series={[{ name: 'Total penjualan', data: daily.map((row) => row.total) }]}
                            categories={daily.map((row) => formatDate(row.date))}
                            height={300}
                            formatter={formatCompact}
                        />
                    ) : (
                        <EmptyState title="Belum ada penjualan" description="Tidak ada transaksi final pada periode ini." />
                    )}
                </div>
            </Card>

            <div className="grid grid-cols-1 gap-5 xl:grid-cols-2">
                <TableShell title="Rekap Harian" description="Transaksi, total, dan komponen potongan.">
                    {daily.length === 0 ? (
                        <EmptyState compact title="Tidak ada data" />
                    ) : (
                        <table className="horizon-table">
                            <thead>
                                <tr>
                                    <th>Tanggal</th>
                                    <th className="text-center">Transaksi</th>
                                    <th className="text-right">Total</th>
                                    <th className="text-right">Diskon</th>
                                </tr>
                            </thead>
                            <tbody>
                                {daily.map((row) => (
                                    <tr key={row.date}>
                                        <td>{formatDate(row.date)}</td>
                                        <td className="text-center">{formatNumber(row.transactions)}</td>
                                        <td className="text-right font-bold">{formatMoney(row.total)}</td>
                                        <td className="text-right">{formatMoney(row.discounts)}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </TableShell>

                <TableShell title="Per Kasir" description="Kontribusi transaksi final per kasir.">
                    {by_cashier.length === 0 ? (
                        <EmptyState compact title="Tidak ada data" />
                    ) : (
                        <table className="horizon-table">
                            <thead>
                                <tr>
                                    <th>Kasir</th>
                                    <th className="text-center">Transaksi</th>
                                    <th className="text-right">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                {by_cashier.map((row) => (
                                    <tr key={row.name}>
                                        <td className="font-medium">{row.name}</td>
                                        <td className="text-center">{formatNumber(row.transactions)}</td>
                                        <td className="text-right font-bold">{formatMoney(row.total)}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </TableShell>
            </div>

            <TableShell title="Per Tipe Order" description="Komposisi dine in, take away, dan delivery.">
                {by_order_type.length === 0 ? (
                    <EmptyState compact title="Tidak ada data" />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Tipe order</th>
                                <th className="text-center">Transaksi</th>
                                <th className="text-right">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            {by_order_type.map((row) => (
                                <tr key={row.order_type}>
                                    <td>{orderTypeLabels[row.order_type] || row.order_type}</td>
                                    <td className="text-center">{formatNumber(row.transactions)}</td>
                                    <td className="text-right font-bold">{formatMoney(row.total)}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </TableShell>
        </div>
    );
}

function PaymentsReport({ report }) {
    const { by_method, by_status, rows } = report;
    const hasMethod = by_method.length > 0;

    return (
        <div className="space-y-5">
            <div className="grid grid-cols-1 gap-5 xl:grid-cols-2">
                <Card className="p-5">
                    <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Nilai Tercatat per Metode</h2>
                    <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Seluruh entri pembayaran pada periode.</p>
                    <div className="mt-4">
                        {hasMethod ? (
                            <BarChart
                                series={[{ name: 'Nilai tercatat', data: by_method.map((row) => row.recorded) }]}
                                categories={by_method.map((row) => paymentMethodLabels[row.method] || row.method)}
                                height={280}
                                formatter={formatCompact}
                            />
                        ) : (
                            <EmptyState compact title="Tidak ada pembayaran" />
                        )}
                    </div>
                </Card>

                <TableShell title="Rekap Metode" description="Nilai tercatat dibanding nilai terkonfirmasi.">
                    {by_method.length === 0 ? (
                        <EmptyState compact title="Tidak ada data" />
                    ) : (
                        <table className="horizon-table">
                            <thead>
                                <tr>
                                    <th>Metode</th>
                                    <th className="text-center">Entri</th>
                                    <th className="text-right">Tercatat</th>
                                    <th className="text-right">Terkonfirmasi</th>
                                </tr>
                            </thead>
                            <tbody>
                                {by_method.map((row) => (
                                    <tr key={row.method}>
                                        <td className="font-medium">{paymentMethodLabels[row.method] || row.method}</td>
                                        <td className="text-center">{formatNumber(row.entries)}</td>
                                        <td className="text-right">{formatMoney(row.recorded)}</td>
                                        <td className="text-right font-bold text-green-600 dark:text-green-400">
                                            {formatMoney(row.confirmed)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    )}
                </TableShell>
            </div>

            <TableShell title="Rekap Status" description="Distribusi status entri pembayaran.">
                {by_status.length === 0 ? (
                    <EmptyState compact title="Tidak ada data" />
                ) : (
                    <div className="flex flex-wrap gap-3 p-5">
                        {by_status.map((row) => (
                            <div key={row.status} className="min-w-[160px] rounded-xl bg-lightPrimary p-3 dark:bg-white/5">
                                <Badge tone={statusTone(row.status)}>{paymentEntryStatusLabels[row.status] || row.status}</Badge>
                                <p className="mt-2 font-poppins text-lg font-bold text-navy-700 dark:text-white">
                                    {formatMoney(row.total)}
                                </p>
                                <p className="text-xs text-gray-500 dark:text-gray-400">{formatNumber(row.entries)} entri</p>
                            </div>
                        ))}
                    </div>
                )}
            </TableShell>

            <TableShell title="Rincian Pembayaran" description="Maksimal 200 entri terbaru.">
                {rows.length === 0 ? (
                    <EmptyState compact title="Tidak ada data" />
                ) : (
                    <div className="overflow-x-auto">
                        <table className="horizon-table">
                            <thead>
                                <tr>
                                    <th>Struk</th>
                                    <th>Metode</th>
                                    <th className="text-right">Tercatat</th>
                                    <th className="text-right">Terverifikasi</th>
                                    <th>Status</th>
                                    <th>Pencatat</th>
                                    <th>Verifikator</th>
                                    <th>Waktu</th>
                                </tr>
                            </thead>
                            <tbody>
                                {rows.map((row) => (
                                    <tr key={row.id}>
                                        <td className="font-bold">{row.receipt_number || '—'}</td>
                                        <td>{paymentMethodLabels[row.method] || row.method}</td>
                                        <td className="text-right">{formatMoney(row.amount)}</td>
                                        <td className="text-right">{row.verified_amount === null ? '—' : formatMoney(row.verified_amount)}</td>
                                        <td>
                                            <Badge tone={statusTone(row.status)}>
                                                {paymentEntryStatusLabels[row.status] || row.status}
                                            </Badge>
                                        </td>
                                        <td className="text-xs">{row.recorded_by || '—'}</td>
                                        <td className="text-xs">{row.verified_by || '—'}</td>
                                        <td className="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400">
                                            {formatDateTime(row.recorded_at)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </TableShell>
        </div>
    );
}

function ProductsReport({ report }) {
    const { rows, summary } = report;

    return (
        <div className="space-y-5">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
                <StatCard
                    icon={<MdOutlineFastfood className="h-6 w-6" />}
                    label="Produk terjual"
                    value={formatNumber(summary.products_sold)}
                    detail="Total kuantitas item final"
                />
                <StatCard
                    icon={<MdBarChart className="h-6 w-6" />}
                    label="Pendapatan produk"
                    value={formatMoney(summary.revenue)}
                    detail="Setelah diskon item"
                    tone="green"
                />
                <StatCard
                    icon={<MdOutlineReceiptLong className="h-6 w-6" />}
                    label="Jenis produk"
                    value={formatNumber(rows.length)}
                    detail="Baris produk pada periode"
                    tone="cyan"
                />
            </div>

            <Card className="p-5">
                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Kuantitas Terjual</h2>
                <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">10 produk teratas berdasarkan kuantitas.</p>
                <div className="mt-4">
                    {rows.length > 0 ? (
                        <BarChart
                            series={[{ name: 'Kuantitas', data: rows.slice(0, 10).map((row) => row.quantity) }]}
                            categories={rows.slice(0, 10).map((row) => row.name)}
                            height={320}
                            horizontal
                            formatter={formatNumber}
                        />
                    ) : (
                        <EmptyState compact title="Belum ada produk terjual" />
                    )}
                </div>
            </Card>

            <TableShell title="Rincian Produk" description="Maksimal 200 produk terlaris.">
                {rows.length === 0 ? (
                    <EmptyState compact title="Tidak ada data" />
                ) : (
                    <div className="overflow-x-auto">
                        <table className="horizon-table">
                            <thead>
                                <tr>
                                    <th>Produk</th>
                                    <th>SKU</th>
                                    <th className="text-center">Kuantitas</th>
                                    <th className="text-right">Bruto</th>
                                    <th className="text-right">Diskon</th>
                                    <th className="text-right">Total</th>
                                </tr>
                            </thead>
                            <tbody>
                                {rows.map((row, index) => (
                                    <tr key={`${row.sku}-${index}`}>
                                        <td className="font-medium">{row.name}</td>
                                        <td className="text-xs text-gray-500 dark:text-gray-400">{row.sku || '—'}</td>
                                        <td className="text-center">{formatNumber(row.quantity)}</td>
                                        <td className="text-right">{formatMoney(row.gross)}</td>
                                        <td className="text-right">{formatMoney(row.discounts)}</td>
                                        <td className="text-right font-bold">{formatMoney(row.total)}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </TableShell>
        </div>
    );
}

function ShiftsReport({ report }) {
    const { rows, summary } = report;

    return (
        <div className="space-y-5">
            <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
                <StatCard
                    icon={<MdOutlineSchedule className="h-6 w-6" />}
                    label="Shift"
                    value={formatNumber(summary.shifts)}
                    detail="Berdasarkan waktu buka pada periode"
                />
                <StatCard
                    icon={<MdBarChart className="h-6 w-6" />}
                    label="Total variance"
                    value={formatMoney(summary.variance)}
                    detail="Akumulasi selisih kas"
                    tone={summary.variance < 0 ? 'red' : 'green'}
                />
                <StatCard
                    icon={<MdOutlineSchedule className="h-6 w-6" />}
                    label="Pending sync"
                    value={formatNumber(summary.pending_sync)}
                    detail="Akumulasi transaksi lokal belum tersinkron"
                    tone="amber"
                />
            </div>

            <TableShell title="Rincian Shift" description="Maksimal 200 shift pada periode.">
                {rows.length === 0 ? (
                    <EmptyState compact title="Tidak ada shift" description="Tidak ada shift pada periode ini." />
                ) : (
                    <div className="overflow-x-auto">
                        <table className="horizon-table">
                            <thead>
                                <tr>
                                    <th>Kasir / Outlet</th>
                                    <th>Status</th>
                                    <th className="text-right">Kas awal</th>
                                    <th className="text-right">Kas diharapkan</th>
                                    <th className="text-right">Kas aktual</th>
                                    <th className="text-right">Variance</th>
                                    <th className="text-right">Non-tunai</th>
                                    <th className="text-center">Pending</th>
                                    <th>Waktu</th>
                                </tr>
                            </thead>
                            <tbody>
                                {rows.map((row) => (
                                    <tr key={row.id}>
                                        <td>
                                            <p className="font-medium">{row.cashier || '—'}</p>
                                            <p className="text-xs text-gray-500 dark:text-gray-400">{row.outlet || '—'}</p>
                                        </td>
                                        <td>
                                            <Badge tone={statusTone(row.status)}>{shiftStatusLabels[row.status] || row.status}</Badge>
                                        </td>
                                        <td className="text-right">{formatMoney(row.opening_cash)}</td>
                                        <td className="text-right">{formatMoney(row.expected_cash)}</td>
                                        <td className="text-right">{row.actual_cash === null ? '—' : formatMoney(row.actual_cash)}</td>
                                        <td className={`text-right font-bold ${Number(row.variance) < 0 ? 'text-red-500' : ''}`}>
                                            {row.variance === null ? '—' : formatMoney(row.variance)}
                                        </td>
                                        <td className="text-right">{formatMoney(row.confirmed_noncash)}</td>
                                        <td className="text-center">{formatNumber(row.pending_sync_count)}</td>
                                        <td className="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400">
                                            {formatDateTime(row.opened_at)}
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </TableShell>
        </div>
    );
}

ReportsIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
