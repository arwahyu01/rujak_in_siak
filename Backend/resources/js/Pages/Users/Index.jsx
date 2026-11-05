import { Head, router, useForm, usePage } from '@inertiajs/react';
import { useState } from 'react';
import { MdAdd, MdEdit, MdPeople, MdSearch } from 'react-icons/md';
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
import Checkbox from '@/Components/UI/Checkbox';
import { formatDateTime, initials } from '@/lib/format';

const emptyForm = {
    name: '',
    email: '',
    username: '',
    phone: '',
    role_id: '',
    outlet_id: '',
    password: '',
    password_confirmation: '',
    is_active: true,
};

export default function UsersIndex({ users, roles, outlets, filters, canManage }) {
    const { auth } = usePage().props;
    const [search, setSearch] = useState(filters.q || '');
    const [roleId, setRoleId] = useState(filters.role_id || '');
    const [status, setStatus] = useState(filters.status || 'all');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);

    const form = useForm({ ...emptyForm });

    const applyFilters = (event) => {
        event?.preventDefault();
        router.get('/users', { q: search, role_id: roleId, status }, { preserveState: true, preserveScroll: true, replace: true });
    };

    const openCreate = () => {
        setEditing(null);
        form.setData({ ...emptyForm, role_id: roles[0]?.id ? String(roles[0].id) : '', outlet_id: outlets[0]?.id ? String(outlets[0].id) : '' });
        form.clearErrors();
        setModalOpen(true);
    };

    const openEdit = (user) => {
        setEditing(user);
        form.setData({
            name: user.name,
            email: user.email,
            username: user.username || '',
            phone: user.phone || '',
            role_id: user.roles?.[0]?.id ? String(user.roles[0].id) : '',
            outlet_id: user.outlet_id ? String(user.outlet_id) : '',
            password: '',
            password_confirmation: '',
            is_active: !!user.is_active,
        });
        form.clearErrors();
        setModalOpen(true);
    };

    const submit = (event) => {
        event.preventDefault();
        const options = { preserveScroll: true, onSuccess: () => setModalOpen(false) };

        if (editing) {
            form.put(`/users/${editing.id}`, options);
        } else {
            form.post('/users', options);
        }
    };

    return (
        <>
            <Head title="Pengguna" />
            <PageHeader
                eyebrow="Administrasi"
                title="Pengguna"
                description="Kelola akun Owner, Admin, Supervisor, dan Kasir. Akun kasir tetap bertransaksi melalui aplikasi Android."
            >
                {canManage ? (
                    <Button onClick={openCreate}>
                        <MdAdd className="h-4 w-4" />
                        Tambah pengguna
                    </Button>
                ) : null}
            </PageHeader>

            <form onSubmit={applyFilters} className="mb-5 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 sm:flex-row sm:items-center">
                <div className="relative flex-1">
                    <MdSearch className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={search}
                        onChange={(event) => setSearch(event.target.value)}
                        placeholder="Cari nama, email, atau username…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="role_id" value={roleId} onChange={(event) => setRoleId(event.target.value)} className="sm:w-52">
                    <option value="">Semua peran</option>
                    {roles.map((role) => (
                        <option key={role.id} value={role.id}>
                            {role.name}
                        </option>
                    ))}
                </SelectField>
                <SelectField id="status" value={status} onChange={(event) => setStatus(event.target.value)} className="sm:w-44">
                    <option value="all">Semua status</option>
                    <option value="active">Aktif</option>
                    <option value="inactive">Nonaktif</option>
                </SelectField>
                <Button type="submit" variant="secondary">
                    Terapkan
                </Button>
            </form>

            <TableShell
                title={`Daftar pengguna (${users.total})`}
                description="Nonaktifkan akun untuk mencabut akses tanpa menghapus riwayat transaksi."
                footer={<Pagination paginator={users} />}
            >
                {users.data.length === 0 ? (
                    <EmptyState
                        icon={<MdPeople />}
                        title="Belum ada pengguna"
                        description="Tambahkan pengguna untuk memberikan akses back-office sesuai peran."
                        action={canManage ? <Button onClick={openCreate}>Tambah pengguna</Button> : null}
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Nama</th>
                                <th>Kontak</th>
                                <th>Peran</th>
                                <th>Outlet</th>
                                <th>Status</th>
                                <th>Login terakhir</th>
                                {canManage ? <th className="text-right">Aksi</th> : null}
                            </tr>
                        </thead>
                        <tbody>
                            {users.data.map((user) => {
                                const isSelf = user.id === auth?.user?.id;
                                return (
                                    <tr key={user.id}>
                                        <td>
                                            <div className="flex items-center gap-3">
                                                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-brand-50 text-xs font-bold text-brand-600 dark:bg-brand-500/10 dark:text-brand-300">
                                                    {initials(user.name)}
                                                </span>
                                                <div className="min-w-0">
                                                    <p className="truncate font-bold text-navy-700 dark:text-white">
                                                        {user.name}
                                                        {isSelf ? <span className="ml-2 text-[11px] font-medium text-brand-500">Anda</span> : null}
                                                    </p>
                                                    <p className="truncate text-xs text-gray-500 dark:text-gray-400">{user.username || '—'}</p>
                                                </div>
                                            </div>
                                        </td>
                                        <td>
                                            <p className="text-sm">{user.email}</p>
                                            <p className="text-xs text-gray-500 dark:text-gray-400">{user.phone || '—'}</p>
                                        </td>
                                        <td>
                                            <div className="flex flex-wrap gap-1">
                                                {(user.roles || []).map((role) => (
                                                    <Badge key={role.id} tone={role.slug === 'owner' ? 'brand' : 'info'}>
                                                        {role.name}
                                                    </Badge>
                                                ))}
                                            </div>
                                        </td>
                                        <td className="text-sm">{user.outlet?.name || '—'}</td>
                                        <td>
                                            <Badge tone={user.is_active ? 'success' : 'neutral'}>
                                                {user.is_active ? 'Aktif' : 'Nonaktif'}
                                            </Badge>
                                        </td>
                                        <td className="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400">
                                            {user.last_login_at ? formatDateTime(user.last_login_at) : 'Belum pernah'}
                                        </td>
                                        {canManage ? (
                                            <td className="text-right">
                                                <Button variant="secondary" size="sm" onClick={() => openEdit(user)}>
                                                    <MdEdit className="h-4 w-4" />
                                                    Ubah
                                                </Button>
                                            </td>
                                        ) : null}
                                    </tr>
                                );
                            })}
                        </tbody>
                    </table>
                )}
            </TableShell>

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Ubah pengguna' : 'Tambah pengguna'}
                description="Peran menentukan permission back-office. Permission rinci dikelola pada halaman Peran & Hak Akses."
                size="md"
                footer={
                    <>
                        <Button variant="secondary" type="button" onClick={() => setModalOpen(false)}>
                            Batal
                        </Button>
                        <Button type="submit" form="user-form" disabled={form.processing}>
                            {form.processing ? 'Menyimpan…' : editing ? 'Simpan perubahan' : 'Simpan pengguna'}
                        </Button>
                    </>
                }
            >
                <form id="user-form" onSubmit={submit} className="space-y-4">
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <InputField
                            id="name"
                            label="Nama lengkap"
                            required
                            value={form.data.name}
                            onChange={(event) => form.setData('name', event.target.value)}
                            error={form.errors.name}
                        />
                        <InputField
                            id="email"
                            label="Email"
                            type="email"
                            required
                            value={form.data.email}
                            onChange={(event) => form.setData('email', event.target.value)}
                            error={form.errors.email}
                        />
                        <InputField
                            id="username"
                            label="Username"
                            value={form.data.username}
                            onChange={(event) => form.setData('username', event.target.value)}
                            error={form.errors.username}
                            hint="Huruf, angka, dash, dan underscore."
                        />
                        <InputField
                            id="phone"
                            label="Nomor telepon"
                            value={form.data.phone}
                            onChange={(event) => form.setData('phone', event.target.value)}
                            error={form.errors.phone}
                        />
                        <SelectField
                            id="role_id"
                            label="Peran"
                            required
                            value={form.data.role_id}
                            onChange={(event) => form.setData('role_id', event.target.value)}
                            error={form.errors.role_id}
                        >
                            <option value="">Pilih peran</option>
                            {roles.map((role) => (
                                <option key={role.id} value={role.id}>
                                    {role.name}
                                </option>
                            ))}
                        </SelectField>
                        <SelectField
                            id="outlet_id"
                            label="Outlet"
                            value={form.data.outlet_id}
                            onChange={(event) => form.setData('outlet_id', event.target.value)}
                            error={form.errors.outlet_id}
                        >
                            <option value="">Tanpa outlet</option>
                            {outlets.map((outlet) => (
                                <option key={outlet.id} value={outlet.id}>
                                    {outlet.name}
                                </option>
                            ))}
                        </SelectField>
                        <InputField
                            id="password"
                            label={editing ? 'Password baru' : 'Password'}
                            type="password"
                            required={!editing}
                            value={form.data.password}
                            onChange={(event) => form.setData('password', event.target.value)}
                            error={form.errors.password}
                            hint={editing ? 'Biarkan kosong jika tidak ingin mengubah password.' : 'Minimal 8 karakter.'}
                        />
                        <InputField
                            id="password_confirmation"
                            label="Konfirmasi password"
                            type="password"
                            required={!editing}
                            value={form.data.password_confirmation}
                            onChange={(event) => form.setData('password_confirmation', event.target.value)}
                            error={form.errors.password_confirmation}
                        />
                    </div>
                    <div className="flex items-center justify-between rounded-xl bg-lightPrimary px-4 py-3 dark:bg-white/5">
                        <Checkbox
                            id="is_active"
                            label="Akun aktif"
                            checked={form.data.is_active}
                            onChange={(event) => form.setData('is_active', event.target.checked)}
                        />
                        <span className="text-xs text-gray-500 dark:text-gray-400">Nonaktifkan untuk mencabut akses.</span>
                    </div>
                </form>
            </Modal>
        </>
    );
}

UsersIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
