import { Head, router } from '@inertiajs/react';
import { useState } from 'react';
import { MdCloudSync, MdInfoOutline, MdSearch, MdSync, MdWarning } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import StatCard from '@/Components/UI/StatCard';
import TableShell from '@/Components/UI/TableShell';
import Pagination from '@/Components/UI/Pagination';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import SelectField from '@/Components/UI/SelectField';
import Modal from '@/Components/UI/Modal';
import { formatDateTime, formatNumber, formatRelative, statusTone, syncStatusLabels } from '@/lib/format';

const statusOptions = ['pending', 'accepted', 'duplicate', 'rejected', 'conflict', 'blocked_dependency', 'upgrade_required'];

export default function SyncIndex({ events, summary, eventTypes, filters }) {
    const [form, setForm] = useState({
        q: filters.q || '',
        status: filters.status || '',
        event_type: filters.event_type || '',
    });
    const [detail, setDetail] = useState(null);

    const update = (key, value) => setForm((current) => ({ ...current, [key]: value }));

    const submit = (event) => {
        event.preventDefault();
        router.get('/sync', form, { preserveState: true, preserveScroll: true, replace: true });
    };

    const reset = () => {
        setForm({ q: '', status: '', event_type: '' });
        router.get('/sync', {}, { preserveScroll: true, replace: true });
    };

    const byStatus = summary.by_status || {};

    return (
        <>
            <Head title="Sinkronisasi" />
            <PageHeader
                eyebrow="Operasional"
                title="Status Sinkronisasi"
                description="Pantau event sinkronisasi dari perangkat kasir. Pemrosesan ulang manual belum tersedia pada backend MVP."
            />

            <div className="mb-5 flex items-start gap-3 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 dark:border-amber-500/30 dark:bg-amber-500/10">
                <MdInfoOutline className="mt-0.5 h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
                <p className="text-xs leading-5 text-amber-800 dark:text-amber-200">
                    Halaman ini bersifat monitoring. Modul push/pull dan resolusi konflik sync belum tersedia di backend, sehingga
                    tidak ada aksi proses ulang atau resolve dari web admin.
                </p>
            </div>

            <div className="mb-5 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <StatCard
                    icon={<MdCloudSync className="h-6 w-6" />}
                    label="Total event"
                    value={formatNumber(summary.total)}
                    detail="Seluruh event pada bisnis ini"
                />
                <StatCard
                    icon={<MdSync className="h-6 w-6" />}
                    label="Belum diproses"
                    value={formatNumber(summary.pending)}
                    detail="Event tanpa waktu proses"
                    tone="amber"
                />
                <StatCard
                    icon={<MdWarning className="h-6 w-6" />}
                    label="Konflik / ditolak"
                    value={formatNumber((byStatus.conflict || 0) + (byStatus.rejected || 0) + (byStatus.blocked_dependency || 0))}
                    detail="Perlu perhatian operasional"
                    tone="red"
                />
                <StatCard
                    icon={<MdCloudSync className="h-6 w-6" />}
                    label="Proses terakhir"
                    value={formatRelative(summary.last_processed_at)}
                    detail={summary.last_processed_at ? formatDateTime(summary.last_processed_at) : 'Belum ada'}
                    tone="green"
                />
            </div>

            <div className="mb-5 flex flex-wrap gap-2">
                {statusOptions.map((status) => (
                    <button
                        key={status}
                        type="button"
                        onClick={() => {
                            setForm((current) => ({ ...current, status }));
                            router.get(
                                '/sync',
                                { ...form, status },
                                { preserveState: true, preserveScroll: true, replace: true },
                            );
                        }}
                        className={`inline-flex items-center gap-2 rounded-xl px-3 py-2 text-xs font-bold transition ${
                            form.status === status
                                ? 'bg-brand-500 text-white'
                                : 'bg-white text-gray-600 shadow-sm hover:bg-brand-50 dark:bg-navy-800 dark:text-gray-300 dark:hover:bg-white/10'
                        }`}
                    >
                        {syncStatusLabels[status] || status}
                        <span className="rounded-full bg-black/10 px-1.5 py-0.5 text-[10px] dark:bg-white/10">
                            {formatNumber(byStatus[status] || 0)}
                        </span>
                    </button>
                ))}
            </div>

            <form onSubmit={submit} className="mb-5 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 sm:flex-row sm:items-center">
                <div className="relative flex-1">
                    <MdSearch className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={form.q}
                        onChange={(event) => update('q', event.target.value)}
                        placeholder="Cari event ID atau aggregate ID…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="event_type" value={form.event_type} onChange={(event) => update('event_type', event.target.value)} className="sm:w-64">
                    <option value="">Semua tipe event</option>
                    {eventTypes.map((type) => (
                        <option key={type} value={type}>
                            {type}
                        </option>
                    ))}
                </SelectField>
                <Button type="submit" variant="secondary">
                    Terapkan
                </Button>
                <Button type="button" variant="ghost" onClick={reset}>
                    Reset
                </Button>
            </form>

            <TableShell
                title={`Event sinkronisasi (${events.total})`}
                description="Klik detail untuk melihat payload event yang tersimpan."
                footer={<Pagination paginator={events} />}
            >
                {events.data.length === 0 ? (
                    <EmptyState
                        icon={<MdCloudSync />}
                        title="Belum ada event sinkronisasi"
                        description="Event akan tercatat setelah perangkat kasir mengirim perubahan ke server."
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Waktu</th>
                                <th>Tipe event</th>
                                <th>Agregat</th>
                                <th>Status</th>
                                <th>Outlet / Perangkat</th>
                                <th>Diproses</th>
                                <th className="text-right">Detail</th>
                            </tr>
                        </thead>
                        <tbody>
                            {events.data.map((event) => (
                                <tr key={event.id}>
                                    <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                        {formatDateTime(event.occurred_at || event.created_at)}
                                    </td>
                                    <td>
                                        <p className="text-sm font-medium">{event.event_type}</p>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">{event.aggregate_type}</p>
                                    </td>
                                    <td className="max-w-[180px]">
                                        <p className="truncate text-xs" title={event.aggregate_id}>
                                            {event.aggregate_id}
                                        </p>
                                    </td>
                                    <td>
                                        <Badge tone={statusTone(event.status)}>{syncStatusLabels[event.status] || event.status}</Badge>
                                        {event.error_code ? (
                                            <p className="mt-1 text-[11px] text-red-500">{event.error_code}</p>
                                        ) : null}
                                    </td>
                                    <td>
                                        <p className="text-sm">{event.outlet?.name || '—'}</p>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">
                                            {event.device ? `${event.device.name} (${event.device.terminal_code})` : '—'}
                                        </p>
                                    </td>
                                    <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                        {event.processed_at ? formatDateTime(event.processed_at) : '—'}
                                    </td>
                                    <td className="text-right">
                                        <Button variant="secondary" size="sm" onClick={() => setDetail(event)}>
                                            Detail
                                        </Button>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </TableShell>

            <Modal
                open={!!detail}
                onClose={() => setDetail(null)}
                title="Detail event sinkronisasi"
                description={detail ? formatDateTime(detail.occurred_at || detail.created_at) : ''}
                size="lg"
            >
                {detail ? (
                    <div className="space-y-4">
                        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                            <Detail label="Event ID" value={detail.event_id} />
                            <Detail label="Tipe event" value={detail.event_type} />
                            <Detail label="Agregat" value={`${detail.aggregate_type} · ${detail.aggregate_id}`} />
                            <Detail label="Status" value={syncStatusLabels[detail.status] || detail.status} />
                            <Detail label="Schema version" value={String(detail.schema_version)} />
                            <Detail label="Error code" value={detail.error_code || '—'} />
                            <Detail label="Diproses" value={detail.processed_at ? formatDateTime(detail.processed_at) : '—'} />
                            <Detail label="Dibuat" value={formatDateTime(detail.created_at)} />
                        </div>
                        <div>
                            <p className="mb-1 text-xs font-bold uppercase tracking-wide text-gray-500">Payload</p>
                            <pre className="max-h-80 overflow-auto rounded-xl bg-navy-900 p-3 text-[11px] leading-5 text-green-300">
                                {detail.payload ? JSON.stringify(detail.payload, null, 2) : '—'}
                            </pre>
                        </div>
                    </div>
                ) : null}
            </Modal>
        </>
    );
}

function Detail({ label, value }) {
    return (
        <div className="rounded-xl border border-gray-200 px-3 py-2 dark:border-white/10">
            <p className="text-[11px] font-medium text-gray-500 dark:text-gray-400">{label}</p>
            <p className="mt-0.5 break-all text-sm font-medium text-navy-700 dark:text-white">{value}</p>
        </div>
    );
}

SyncIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
