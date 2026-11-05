import { Head, router } from '@inertiajs/react';
import { useState } from 'react';
import { MdHistory, MdSearch, MdVisibility } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import TableShell from '@/Components/UI/TableShell';
import Pagination from '@/Components/UI/Pagination';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import Modal from '@/Components/UI/Modal';
import InputField from '@/Components/UI/InputField';
import SelectField from '@/Components/UI/SelectField';
import { formatDateTime } from '@/lib/format';

const moduleLabels = {
    auth: 'Autentikasi',
    categories: 'Kategori',
    products: 'Produk',
    sales: 'Transaksi',
    payments: 'Pembayaran',
    shifts: 'Shift',
    users: 'Pengguna',
    roles: 'Peran',
    reports: 'Laporan',
    sync: 'Sinkronisasi',
};

function actionTone(action = '') {
    if (action.includes('void') || action.includes('reject') || action.includes('denied')) return 'danger';
    if (action.includes('verify') || action.includes('confirm')) return 'success';
    if (action.includes('created')) return 'brand';
    if (action.includes('updated') || action.includes('corrected')) return 'warning';
    return 'neutral';
}

export default function AuditIndex({ logs, modules, users, filters }) {
    const [form, setForm] = useState({
        q: filters.q || '',
        module: filters.module || '',
        user_id: filters.user_id || '',
        date_from: filters.date_from || '',
        date_to: filters.date_to || '',
    });
    const [detail, setDetail] = useState(null);

    const update = (key, value) => setForm((current) => ({ ...current, [key]: value }));

    const submit = (event) => {
        event.preventDefault();
        router.get('/audit-logs', form, { preserveState: true, preserveScroll: true, replace: true });
    };

    const reset = () => {
        const empty = { q: '', module: '', user_id: '', date_from: '', date_to: '' };
        setForm(empty);
        router.get('/audit-logs', {}, { preserveScroll: true, replace: true });
    };

    return (
        <>
            <Head title="Audit Log" />
            <PageHeader
                eyebrow="Administrasi"
                title="Audit Log"
                description="Jejak aksi sensitif: login, perubahan master data, verifikasi/penolakan pembayaran, void, refund, serta perubahan hak akses."
            />

            <form onSubmit={submit} className="mb-5 grid grid-cols-1 gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 md:grid-cols-2 xl:grid-cols-6">
                <div className="relative xl:col-span-2">
                    <MdSearch className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={form.q}
                        onChange={(event) => update('q', event.target.value)}
                        placeholder="Cari deskripsi, aksi, atau ID objek…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="module" value={form.module} onChange={(event) => update('module', event.target.value)}>
                    <option value="">Semua modul</option>
                    {modules.map((module) => (
                        <option key={module} value={module}>
                            {moduleLabels[module] || module}
                        </option>
                    ))}
                </SelectField>
                <SelectField id="user_id" value={form.user_id} onChange={(event) => update('user_id', event.target.value)}>
                    <option value="">Semua pengguna</option>
                    {users.map((user) => (
                        <option key={user.id} value={user.id}>
                            {user.name}
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
                <div className="flex items-end gap-2">
                    <Button type="submit" variant="primary">
                        Terapkan
                    </Button>
                    <Button type="button" variant="secondary" onClick={reset}>
                        Reset
                    </Button>
                </div>
            </form>

            <TableShell
                title={`Audit log (${logs.total})`}
                description="Catatan audit tidak dapat diubah dari antarmuka dan diurutkan dari yang terbaru."
                footer={<Pagination paginator={logs} />}
            >
                {logs.data.length === 0 ? (
                    <EmptyState
                        icon={<MdHistory />}
                        title="Belum ada audit log"
                        description="Aktivitas sensitif akan tercatat otomatis setelah pengguna melakukan aksi."
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Waktu</th>
                                <th>Modul</th>
                                <th>Aksi</th>
                                <th>Deskripsi</th>
                                <th>Pengguna</th>
                                <th>IP</th>
                                <th className="text-right">Detail</th>
                            </tr>
                        </thead>
                        <tbody>
                            {logs.data.map((log) => (
                                <tr key={log.id}>
                                    <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                        {formatDateTime(log.created_at)}
                                    </td>
                                    <td className="text-xs font-medium">{moduleLabels[log.module] || log.module}</td>
                                    <td>
                                        <Badge tone={actionTone(log.action)}>{log.action}</Badge>
                                    </td>
                                    <td className="max-w-sm">
                                        <p className="truncate text-sm" title={log.description}>
                                            {log.description}
                                        </p>
                                    </td>
                                    <td className="text-sm">{log.user?.name || 'Sistem'}</td>
                                    <td className="text-xs text-gray-500 dark:text-gray-400">{log.ip_address || '—'}</td>
                                    <td className="text-right">
                                        <Button variant="secondary" size="sm" onClick={() => setDetail(log)}>
                                            <MdVisibility className="h-4 w-4" />
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
                title="Detail audit log"
                description={detail ? formatDateTime(detail.created_at) : ''}
                size="lg"
            >
                {detail ? (
                    <div className="space-y-4">
                        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                            <Detail label="Aksi" value={detail.action} />
                            <Detail label="Modul" value={moduleLabels[detail.module] || detail.module} />
                            <Detail label="Pengguna" value={detail.user?.name || 'Sistem'} />
                            <Detail label="IP" value={detail.ip_address || '—'} />
                            <Detail label="Tipe objek" value={detail.auditable_type || '—'} />
                            <Detail label="ID objek" value={detail.auditable_id || '—'} />
                        </div>
                        <div className="rounded-xl bg-lightPrimary px-4 py-3 dark:bg-white/5">
                            <p className="text-xs font-bold uppercase tracking-wide text-gray-500">Deskripsi</p>
                            <p className="mt-1 text-sm text-navy-700 dark:text-white">{detail.description}</p>
                        </div>
                        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                            <JsonBlock title="Nilai lama" value={detail.old_values} />
                            <JsonBlock title="Nilai baru" value={detail.new_values} />
                        </div>
                        {detail.user_agent ? (
                            <div>
                                <p className="text-xs font-bold uppercase tracking-wide text-gray-500">User agent</p>
                                <p className="mt-1 break-all text-xs text-gray-600 dark:text-gray-400">{detail.user_agent}</p>
                            </div>
                        ) : null}
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

function JsonBlock({ title, value }) {
    return (
        <div>
            <p className="mb-1 text-xs font-bold uppercase tracking-wide text-gray-500">{title}</p>
            <pre className="max-h-64 overflow-auto rounded-xl bg-navy-900 p-3 text-[11px] leading-5 text-green-300">
                {value ? JSON.stringify(value, null, 2) : '—'}
            </pre>
        </div>
    );
}

AuditIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
