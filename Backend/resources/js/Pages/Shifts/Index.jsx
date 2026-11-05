import { Head, Link, router } from '@inertiajs/react';
import { useState } from 'react';
import { MdOutlineSchedule, MdPointOfSale, MdSyncProblem, MdWarning } from 'react-icons/md';
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
import { formatDateTime, formatMoney, formatNumber, shiftStatusLabels, statusTone } from '@/lib/format';

export default function ShiftsIndex({ shifts, summary, filters }) {
    const [form, setForm] = useState({
        status: filters.status || '',
        date_from: filters.date_from || '',
        date_to: filters.date_to || '',
    });

    const update = (key, value) => setForm((current) => ({ ...current, [key]: value }));

    const submit = (event) => {
        event.preventDefault();
        router.get('/shifts', form, { preserveState: true, preserveScroll: true, replace: true });
    };

    const reset = () => {
        setForm({ status: '', date_from: '', date_to: '' });
        router.get('/shifts', {}, { preserveScroll: true, replace: true });
    };

    return (
        <>
            <Head title="Monitoring Shift" />
            <PageHeader
                eyebrow="Operasional"
                title="Monitoring Shift"
                description="Shift dibuka dan ditutup dari aplikasi kasir. Back-office memantau status penutupan, selisih kas, dan sinkronisasi."
            />

            <div className="mb-5 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <StatCard
                    icon={<MdPointOfSale className="h-6 w-6" />}
                    label="Shift buka"
                    value={formatNumber(summary.open)}
                    detail="Masih berjalan pada filter aktif"
                    tone="brand"
                />
                <StatCard
                    icon={<MdOutlineSchedule className="h-6 w-6" />}
                    label="Menunggu sinkronisasi"
                    value={formatNumber(summary.pending_sync)}
                    detail="Shift ditutup, menunggu konfirmasi server"
                    tone="amber"
                />
                <StatCard
                    icon={<MdSyncProblem className="h-6 w-6" />}
                    label="Sync exception"
                    value={formatNumber(summary.exception)}
                    detail="Perlu tindak lanjut operasional"
                    tone="red"
                />
                <StatCard
                    icon={<MdWarning className="h-6 w-6" />}
                    label="Total variance"
                    value={formatMoney(summary.variance)}
                    detail="Selisih kas aktual terhadap ekspektasi"
                    tone={summary.variance < 0 ? 'red' : 'green'}
                />
            </div>

            <form onSubmit={submit} className="mb-5 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 md:flex-row md:items-end">
                <SelectField id="status" label="Status shift" value={form.status} onChange={(event) => update('status', event.target.value)} className="md:w-64">
                    <option value="">Semua status</option>
                    <option value="open">Buka</option>
                    <option value="closed_pending_sync">Tutup — menunggu sinkronisasi</option>
                    <option value="closed_confirmed">Tutup — terkonfirmasi</option>
                    <option value="closed_sync_exception">Tutup — sync exception</option>
                </SelectField>
                <InputField
                    id="date_from"
                    label="Dari tanggal buka"
                    type="date"
                    value={form.date_from}
                    onChange={(event) => update('date_from', event.target.value)}
                    className="md:w-48"
                />
                <InputField
                    id="date_to"
                    label="Sampai tanggal buka"
                    type="date"
                    value={form.date_to}
                    onChange={(event) => update('date_to', event.target.value)}
                    className="md:w-48"
                />
                <div className="flex gap-2">
                    <Button type="submit" variant="primary">
                        Terapkan
                    </Button>
                    <Button type="button" variant="secondary" onClick={reset}>
                        Reset
                    </Button>
                </div>
            </form>

            <TableShell
                title={`Daftar shift (${shifts.total})`}
                description="Variance negatif berarti kas aktual lebih kecil dari kas yang diharapkan."
                footer={<Pagination paginator={shifts} />}
            >
                {shifts.data.length === 0 ? (
                    <EmptyState
                        icon={<MdOutlineSchedule />}
                        title="Belum ada shift"
                        description="Shift akan muncul setelah kasir membuka shift pada aplikasi Android dan data tersinkronisasi."
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Kasir / Outlet</th>
                                <th>Perangkat</th>
                                <th>Status</th>
                                <th className="text-right">Kas awal</th>
                                <th className="text-right">Kas diharapkan</th>
                                <th className="text-right">Kas aktual</th>
                                <th className="text-right">Variance</th>
                                <th className="text-center">Transaksi</th>
                                <th>Waktu</th>
                            </tr>
                        </thead>
                        <tbody>
                            {shifts.data.map((shift) => (
                                <tr key={shift.id}>
                                    <td>
                                        <Link href={`/shifts/${shift.id}`} className="font-bold text-brand-500 hover:text-brand-600">
                                            {shift.cashier?.name || '—'}
                                        </Link>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">{shift.outlet?.name || '—'}</p>
                                    </td>
                                    <td className="text-xs text-gray-600 dark:text-gray-400">
                                        {shift.device ? (
                                            <>
                                                {shift.device.name}
                                                <br />
                                                {shift.device.terminal_code}
                                            </>
                                        ) : (
                                            '—'
                                        )}
                                    </td>
                                    <td>
                                        <Badge tone={statusTone(shift.status)}>{shiftStatusLabels[shift.status] || shift.status}</Badge>
                                    </td>
                                    <td className="whitespace-nowrap text-right">{formatMoney(shift.opening_cash)}</td>
                                    <td className="whitespace-nowrap text-right">{formatMoney(shift.expected_cash)}</td>
                                    <td className="whitespace-nowrap text-right">{shift.actual_cash === null ? '—' : formatMoney(shift.actual_cash)}</td>
                                    <td
                                        className={`whitespace-nowrap text-right font-bold ${
                                            Number(shift.variance) < 0
                                                ? 'text-red-500'
                                                : Number(shift.variance) > 0
                                                  ? 'text-green-600'
                                                  : ''
                                        }`}
                                    >
                                        {shift.variance === null ? '—' : formatMoney(shift.variance)}
                                    </td>
                                    <td className="text-center">{shift.sales_count ?? 0}</td>
                                    <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                        Buka {formatDateTime(shift.opened_at)}
                                        {shift.closed_at ? (
                                            <>
                                                <br />
                                                Tutup {formatDateTime(shift.closed_at)}
                                            </>
                                        ) : null}
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

ShiftsIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
