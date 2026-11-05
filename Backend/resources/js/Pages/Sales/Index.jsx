import { Head, Link, router } from '@inertiajs/react';
import { useState } from 'react';
import { MdCheckCircle, MdOutlineReceiptLong, MdSearch, MdWarning } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import StatCard from '@/Components/UI/StatCard';
import TableShell from '@/Components/UI/TableShell';
import Pagination from '@/Components/UI/Pagination';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import InputField from '@/Components/UI/InputField';
import SelectField from '@/Components/UI/SelectField';
import {
    formatDateTime,
    formatMoney,
    formatNumber,
    lifecycleLabels,
    orderTypeLabels,
    paymentStatusLabels,
    statusTone,
} from '@/lib/format';

const paymentStatuses = [
    'unpaid',
    'partially_paid',
    'awaiting_verification',
    'paid',
    'partially_refunded',
    'refunded',
    'cancelled',
];

export default function SalesIndex({ sales, summary, cashiers, filters }) {
    const [form, setForm] = useState({
        q: filters.q || '',
        payment_status: filters.payment_status || '',
        lifecycle_status: filters.lifecycle_status || '',
        cashier_id: filters.cashier_id || '',
        date_from: filters.date_from || '',
        date_to: filters.date_to || '',
    });

    const update = (key, value) => setForm((current) => ({ ...current, [key]: value }));

    const submit = (event) => {
        event.preventDefault();
        router.get('/sales', form, { preserveState: true, preserveScroll: true, replace: true });
    };

    const reset = () => {
        const empty = { q: '', payment_status: '', lifecycle_status: '', cashier_id: '', date_from: '', date_to: '' };
        setForm(empty);
        router.get('/sales', {}, { preserveScroll: true, replace: true });
    };

    return (
        <>
            <Head title="Transaksi" />
            <PageHeader
                eyebrow="Penjualan"
                title="Riwayat Transaksi"
                description="Transaksi final dan void dari aplikasi kasir. Status pembayaran dipisahkan dari lifecycle transaksi."
            />

            <div className="mb-5 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <StatCard
                    icon={<MdOutlineReceiptLong className="h-6 w-6" />}
                    label="Transaksi pada filter"
                    value={formatNumber(summary.count)}
                    detail={`Total nilai ${formatMoney(summary.total)}`}
                />
                <StatCard
                    icon={<MdCheckCircle className="h-6 w-6" />}
                    label="Nilai lunas"
                    value={formatMoney(summary.paid)}
                    detail="Transaksi dengan status pembayaran lunas"
                    tone="green"
                />
                <StatCard
                    icon={<MdWarning className="h-6 w-6" />}
                    label="Menunggu verifikasi"
                    value={formatMoney(summary.awaiting)}
                    detail="Akumulasi pembayaran non-tunai pending"
                    tone="amber"
                />
                <StatCard
                    icon={<MdOutlineReceiptLong className="h-6 w-6" />}
                    label="Transaksi void"
                    value={formatNumber(summary.voided)}
                    detail="Tidak dihitung sebagai penjualan final"
                    tone="red"
                />
            </div>

            <form onSubmit={submit} className="mb-5 grid grid-cols-1 gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 md:grid-cols-2 xl:grid-cols-6">
                <div className="relative xl:col-span-2">
                    <MdSearch className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={form.q}
                        onChange={(event) => update('q', event.target.value)}
                        placeholder="Cari nomor struk atau meja…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="payment_status" value={form.payment_status} onChange={(event) => update('payment_status', event.target.value)}>
                    <option value="">Semua pembayaran</option>
                    {paymentStatuses.map((status) => (
                        <option key={status} value={status}>
                            {paymentStatusLabels[status] || status}
                        </option>
                    ))}
                </SelectField>
                <SelectField id="lifecycle_status" value={form.lifecycle_status} onChange={(event) => update('lifecycle_status', event.target.value)}>
                    <option value="">Semua lifecycle</option>
                    <option value="finalized">Final</option>
                    <option value="voided">Void</option>
                </SelectField>
                <SelectField id="cashier_id" value={form.cashier_id} onChange={(event) => update('cashier_id', event.target.value)}>
                    <option value="">Semua kasir</option>
                    {cashiers.map((cashier) => (
                        <option key={cashier.id} value={cashier.id}>
                            {cashier.name}
                        </option>
                    ))}
                </SelectField>
                <div className="grid grid-cols-2 gap-2">
                    <InputField
                        id="date_from"
                        label="Dari"
                        type="date"
                        value={form.date_from}
                        onChange={(event) => update('date_from', event.target.value)}
                    />
                    <InputField
                        id="date_to"
                        label="Sampai"
                        type="date"
                        value={form.date_to}
                        onChange={(event) => update('date_to', event.target.value)}
                    />
                </div>
                <div className="flex items-end gap-2 xl:col-span-6">
                    <Button type="submit" variant="primary">
                        Terapkan filter
                    </Button>
                    <Button type="button" variant="secondary" onClick={reset}>
                        Reset
                    </Button>
                </div>
            </form>

            <TableShell
                title={`Daftar transaksi (${sales.total})`}
                description="Klik nomor struk untuk melihat detail item, pembayaran, refund, dan audit trail."
                footer={<Pagination paginator={sales} />}
            >
                {sales.data.length === 0 ? (
                    <EmptyState
                        icon={<MdOutlineReceiptLong />}
                        title="Tidak ada transaksi"
                        description="Belum ada transaksi yang cocok dengan filter, atau data belum tersinkronisasi dari perangkat kasir."
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Nomor struk</th>
                                <th>Waktu</th>
                                <th>Kasir / Outlet</th>
                                <th className="text-center">Tipe</th>
                                <th className="text-right">Total</th>
                                <th>Pembayaran</th>
                                <th>Lifecycle</th>
                            </tr>
                        </thead>
                        <tbody>
                            {sales.data.map((sale) => (
                                <tr key={sale.id}>
                                    <td>
                                        <Link href={`/sales/${sale.id}`} className="font-bold text-brand-500 hover:text-brand-600">
                                            {sale.receipt_number}
                                        </Link>
                                        {sale.table_number ? (
                                            <p className="text-xs text-gray-500 dark:text-gray-400">Meja {sale.table_number}</p>
                                        ) : null}
                                    </td>
                                    <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                        {formatDateTime(sale.transacted_at)}
                                    </td>
                                    <td>
                                        <p className="text-sm font-medium">{sale.cashier?.name || '—'}</p>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">{sale.outlet?.name || '—'}</p>
                                    </td>
                                    <td className="text-center text-xs">{orderTypeLabels[sale.order_type] || sale.order_type}</td>
                                    <td className="whitespace-nowrap text-right font-bold">{formatMoney(sale.total)}</td>
                                    <td>
                                        <Badge tone={statusTone(sale.payment_status)}>
                                            {paymentStatusLabels[sale.payment_status] || sale.payment_status}
                                        </Badge>
                                    </td>
                                    <td>
                                        <Badge tone={statusTone(sale.lifecycle_status)}>
                                            {lifecycleLabels[sale.lifecycle_status] || sale.lifecycle_status}
                                        </Badge>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </TableShell>
        </>
    );
}

SalesIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
