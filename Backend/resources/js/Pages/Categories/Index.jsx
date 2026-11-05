import { Head, router, useForm } from '@inertiajs/react';
import { useState } from 'react';
import { MdAdd, MdEdit, MdOutlineCategory, MdPowerSettingsNew, MdSearch } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import TableShell from '@/Components/UI/TableShell';
import Pagination from '@/Components/UI/Pagination';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import Modal from '@/Components/UI/Modal';
import InputField from '@/Components/UI/InputField';
import TextareaField from '@/Components/UI/TextareaField';
import SelectField from '@/Components/UI/SelectField';
import Checkbox from '@/Components/UI/Checkbox';
import { formatDateTime } from '@/lib/format';

const emptyForm = {
    name: '',
    description: '',
    sort_order: 0,
    is_active: true,
};

export default function CategoriesIndex({ categories, filters, canManage }) {
    const [search, setSearch] = useState(filters.q || '');
    const [status, setStatus] = useState(filters.status || 'all');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [deactivating, setDeactivating] = useState(null);

    const form = useForm({ ...emptyForm });

    const applyFilters = (event) => {
        event?.preventDefault();
        router.get('/categories', { q: search, status }, { preserveState: true, preserveScroll: true, replace: true });
    };

    const openCreate = () => {
        setEditing(null);
        form.setData({ ...emptyForm });
        form.clearErrors();
        setModalOpen(true);
    };

    const openEdit = (category) => {
        setEditing(category);
        form.setData({
            name: category.name,
            description: category.description || '',
            sort_order: category.sort_order ?? 0,
            is_active: !!category.is_active,
        });
        form.clearErrors();
        setModalOpen(true);
    };

    const submit = (event) => {
        event.preventDefault();
        if (editing) {
            form.put(`/categories/${editing.id}`, {
                preserveScroll: true,
                onSuccess: () => setModalOpen(false),
            });
        } else {
            form.post('/categories', {
                preserveScroll: true,
                onSuccess: () => setModalOpen(false),
            });
        }
    };

    const deactivate = () => {
        if (!deactivating) return;
        router.delete(`/categories/${deactivating.id}`, {
            preserveScroll: true,
            onFinish: () => setDeactivating(null),
        });
    };

    return (
        <>
            <Head title="Kategori" />
            <PageHeader
                eyebrow="Master data"
                title="Kategori"
                description="Kelompokkan produk untuk memudahkan kasir menemukan menu. Menonaktifkan kategori tidak menghapus data historis."
            >
                {canManage ? (
                    <Button onClick={openCreate}>
                        <MdAdd className="h-4 w-4" />
                        Tambah kategori
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
                        placeholder="Cari nama atau deskripsi kategori…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="status" value={status} onChange={(event) => setStatus(event.target.value)} className="sm:w-48">
                    <option value="all">Semua status</option>
                    <option value="active">Aktif</option>
                    <option value="inactive">Nonaktif</option>
                </SelectField>
                <Button type="submit" variant="secondary">
                    Terapkan
                </Button>
            </form>

            <TableShell
                title={`Daftar kategori (${categories.total})`}
                description="Kategori nonaktif tidak lagi ditampilkan sebagai pilihan aktif pada aplikasi kasir."
                footer={<Pagination paginator={categories} />}
            >
                {categories.data.length === 0 ? (
                    <EmptyState
                        icon={<MdOutlineCategory />}
                        title="Belum ada kategori"
                        description="Buat kategori pertama agar produk dapat dikelompokkan dengan rapi."
                        action={canManage ? <Button onClick={openCreate}>Tambah kategori</Button> : null}
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Nama</th>
                                <th>Deskripsi</th>
                                <th className="text-center">Urutan</th>
                                <th className="text-center">Produk</th>
                                <th>Status</th>
                                <th>Diperbarui</th>
                                {canManage ? <th className="text-right">Aksi</th> : null}
                            </tr>
                        </thead>
                        <tbody>
                            {categories.data.map((category) => (
                                <tr key={category.id}>
                                    <td>
                                        <p className="font-bold text-navy-700 dark:text-white">{category.name}</p>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">{category.slug}</p>
                                    </td>
                                    <td className="max-w-xs">
                                        <p className="truncate text-sm text-gray-600 dark:text-gray-400" title={category.description || ''}>
                                            {category.description || '—'}
                                        </p>
                                    </td>
                                    <td className="text-center">{category.sort_order}</td>
                                    <td className="text-center">{category.products_count ?? 0}</td>
                                    <td>
                                        <Badge tone={category.is_active ? 'success' : 'neutral'}>
                                            {category.is_active ? 'Aktif' : 'Nonaktif'}
                                        </Badge>
                                    </td>
                                    <td className="whitespace-nowrap text-xs text-gray-500 dark:text-gray-400">
                                        {formatDateTime(category.updated_at)}
                                    </td>
                                    {canManage ? (
                                        <td>
                                            <div className="flex items-center justify-end gap-2">
                                                <Button variant="secondary" size="sm" onClick={() => openEdit(category)}>
                                                    <MdEdit className="h-4 w-4" />
                                                    Ubah
                                                </Button>
                                                {category.is_active ? (
                                                    <Button
                                                        variant="secondary"
                                                        size="sm"
                                                        onClick={() => setDeactivating(category)}
                                                        title="Nonaktifkan kategori"
                                                    >
                                                        <MdPowerSettingsNew className="h-4 w-4" />
                                                    </Button>
                                                ) : null}
                                            </div>
                                        </td>
                                    ) : null}
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </TableShell>

            <Modal
                open={modalOpen}
                onClose={() => setModalOpen(false)}
                title={editing ? 'Ubah kategori' : 'Tambah kategori'}
                description="Nama kategori akan diubah menjadi slug unik secara otomatis."
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)} type="button">
                            Batal
                        </Button>
                        <Button type="submit" form="category-form" disabled={form.processing}>
                            {form.processing ? 'Menyimpan…' : editing ? 'Simpan perubahan' : 'Simpan kategori'}
                        </Button>
                    </>
                }
            >
                <form id="category-form" onSubmit={submit} className="space-y-4">
                    <InputField
                        id="name"
                        label="Nama kategori"
                        required
                        value={form.data.name}
                        onChange={(event) => form.setData('name', event.target.value)}
                        error={form.errors.name}
                        placeholder="Contoh: Rujak Buah"
                    />
                    <TextareaField
                        id="description"
                        label="Deskripsi"
                        rows={3}
                        value={form.data.description}
                        onChange={(event) => form.setData('description', event.target.value)}
                        error={form.errors.description}
                        placeholder="Deskripsi singkat kategori (opsional)"
                    />
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <InputField
                            id="sort_order"
                            label="Urutan tampil"
                            type="number"
                            min={0}
                            value={form.data.sort_order}
                            onChange={(event) => form.setData('sort_order', event.target.value)}
                            error={form.errors.sort_order}
                            hint="Angka kecil tampil lebih awal."
                        />
                        <div className="flex items-end pb-2">
                            <Checkbox
                                id="is_active"
                                label="Kategori aktif"
                                checked={form.data.is_active}
                                onChange={(event) => form.setData('is_active', event.target.checked)}
                            />
                        </div>
                    </div>
                    {form.errors.category ? (
                        <p className="rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600 dark:bg-red-500/10 dark:text-red-300">
                            {form.errors.category}
                        </p>
                    ) : null}
                </form>
            </Modal>

            <Modal
                open={!!deactivating}
                onClose={() => setDeactivating(null)}
                title="Nonaktifkan kategori?"
                description="Kategori tidak akan dihapus. Produk yang masih terhubung tetap tersimpan dan dapat dipindahkan kapan saja."
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setDeactivating(null)} type="button">
                            Batal
                        </Button>
                        <Button variant="danger" onClick={deactivate}>
                            Nonaktifkan
                        </Button>
                    </>
                }
            >
                <p className="text-sm text-gray-600 dark:text-gray-400">
                    Kategori <span className="font-bold text-navy-700 dark:text-white">{deactivating?.name}</span> akan ditandai
                    nonaktif. Tindakan ini tercatat pada audit log.
                </p>
            </Modal>
        </>
    );
}

CategoriesIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
