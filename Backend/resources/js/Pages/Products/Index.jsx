import { Head, router, useForm } from '@inertiajs/react';
import { useMemo, useState } from 'react';
import {
    MdAdd,
    MdDelete,
    MdEdit,
    MdImage,
    MdOutlineFastfood,
    MdSearch,
    MdToggleOff,
    MdToggleOn,
} from 'react-icons/md';
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
import { formatMoney } from '@/lib/format';

const emptyForm = {
    name: '',
    sku: '',
    barcode: '',
    category_id: '',
    description: '',
    unit: 'porsi',
    price: 0,
    production_cost: '',
    is_active: true,
    is_available: true,
    image: null,
    variants: [],
    addons: [],
};

function variantRow() {
    return { name: '', sku: '', price_delta: 0, is_active: true };
}

function addonRow() {
    return { name: '', price: 0, is_active: true };
}

export default function ProductsIndex({ products, categories, filters, canManage }) {
    const [search, setSearch] = useState(filters.q || '');
    const [categoryId, setCategoryId] = useState(filters.category_id || '');
    const [status, setStatus] = useState(filters.status || 'all');
    const [availability, setAvailability] = useState(filters.availability || 'all');
    const [modalOpen, setModalOpen] = useState(false);
    const [editing, setEditing] = useState(null);
    const [preview, setPreview] = useState(null);

    const form = useForm({ ...emptyForm });

    const activeCategories = useMemo(
        () => categories.filter((category) => category.is_active || String(category.id) === String(form.data.category_id)),
        [categories, form.data.category_id],
    );

    const applyFilters = (event) => {
        event?.preventDefault();
        router.get(
            '/products',
            { q: search, category_id: categoryId, status, availability },
            { preserveState: true, preserveScroll: true, replace: true },
        );
    };

    const openCreate = () => {
        setEditing(null);
        form.setData({ ...emptyForm });
        form.clearErrors();
        setModalOpen(true);
    };

    const openEdit = (product) => {
        setEditing(product);
        form.setData({
            name: product.name,
            sku: product.sku,
            barcode: product.barcode || '',
            category_id: product.category_id ? String(product.category_id) : '',
            description: product.description || '',
            unit: product.unit || 'porsi',
            price: product.price,
            production_cost: product.production_cost ?? '',
            is_active: !!product.is_active,
            is_available: !!product.is_available,
            image: null,
            variants: (product.variants || []).map((variant) => ({
                name: variant.name,
                sku: variant.sku || '',
                price_delta: variant.price_delta ?? 0,
                is_active: !!variant.is_active,
            })),
            addons: (product.addons || []).map((addon) => ({
                name: addon.name,
                price: addon.price ?? 0,
                is_active: !!addon.is_active,
            })),
        });
        form.clearErrors();
        setModalOpen(true);
    };

    const submit = (event) => {
        event.preventDefault();
        const options = {
            preserveScroll: true,
            forceFormData: true,
            onSuccess: () => setModalOpen(false),
        };

        if (editing) {
            form.post(`/products/${editing.id}`, options);
        } else {
            form.post('/products', options);
        }
    };

    const updateRow = (kind, index, key, value) => {
        const rows = [...form.data[kind]];
        rows[index] = { ...rows[index], [key]: value };
        form.setData(kind, rows);
    };

    const addRow = (kind) => {
        form.setData(kind, [...form.data[kind], kind === 'variants' ? variantRow() : addonRow()]);
    };

    const removeRow = (kind, index) => {
        form.setData(
            kind,
            form.data[kind].filter((_, rowIndex) => rowIndex !== index),
        );
    };

    const toggle = (product, field) => {
        router.patch(`/products/${product.id}/toggle/${field}`, {}, { preserveScroll: true });
    };

    return (
        <>
            <Head title="Produk" />
            <PageHeader
                eyebrow="Master data"
                title="Produk"
                description="Kelola menu, harga, varian, dan add-on. Perubahan harga hanya berlaku untuk transaksi berikutnya."
            >
                {canManage ? (
                    <Button onClick={openCreate}>
                        <MdAdd className="h-4 w-4" />
                        Tambah produk
                    </Button>
                ) : null}
            </PageHeader>

            <form onSubmit={applyFilters} className="mb-5 grid grid-cols-1 gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 md:grid-cols-2 xl:grid-cols-5">
                <div className="relative xl:col-span-2">
                    <MdSearch className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={search}
                        onChange={(event) => setSearch(event.target.value)}
                        placeholder="Cari nama, SKU, atau barcode…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="category_id" value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
                    <option value="">Semua kategori</option>
                    {categories.map((category) => (
                        <option key={category.id} value={category.id}>
                            {category.name}
                            {category.is_active ? '' : ' (nonaktif)'}
                        </option>
                    ))}
                </SelectField>
                <SelectField id="status" value={status} onChange={(event) => setStatus(event.target.value)}>
                    <option value="all">Semua status</option>
                    <option value="active">Aktif</option>
                    <option value="inactive">Nonaktif</option>
                </SelectField>
                <div className="flex gap-2">
                    <SelectField id="availability" value={availability} onChange={(event) => setAvailability(event.target.value)} className="flex-1">
                        <option value="all">Semua ketersediaan</option>
                        <option value="available">Tersedia</option>
                        <option value="unavailable">Habis</option>
                    </SelectField>
                    <Button type="submit" variant="secondary">
                        Filter
                    </Button>
                </div>
            </form>

            <TableShell
                title={`Daftar produk (${products.total})`}
                description="Produk tidak dihapus permanen agar referensi transaksi lama tetap utuh."
                footer={<Pagination paginator={products} />}
            >
                {products.data.length === 0 ? (
                    <EmptyState
                        icon={<MdOutlineFastfood />}
                        title="Belum ada produk"
                        description="Tambahkan produk pertama beserta harga dan variannya."
                        action={canManage ? <Button onClick={openCreate}>Tambah produk</Button> : null}
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Produk</th>
                                <th>Kategori</th>
                                <th className="text-right">Harga</th>
                                <th className="text-center">Varian / Add-on</th>
                                <th>Status</th>
                                {canManage ? <th className="text-right">Aksi</th> : null}
                            </tr>
                        </thead>
                        <tbody>
                            {products.data.map((product) => (
                                <tr key={product.id}>
                                    <td>
                                        <div className="flex items-center gap-3">
                                            {product.image_url ? (
                                                <button
                                                    type="button"
                                                    onClick={() => setPreview(product.image_url)}
                                                    className="h-11 w-11 shrink-0 overflow-hidden rounded-xl border border-gray-200 dark:border-white/10"
                                                >
                                                    <img src={product.image_url} alt={product.name} className="h-full w-full object-cover" />
                                                </button>
                                            ) : (
                                                <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-lightPrimary text-gray-400 dark:bg-white/5">
                                                    <MdImage className="h-5 w-5" />
                                                </span>
                                            )}
                                            <div className="min-w-0">
                                                <p className="truncate font-bold text-navy-700 dark:text-white">{product.name}</p>
                                                <p className="text-xs text-gray-500 dark:text-gray-400">
                                                    {product.sku}
                                                    {product.barcode ? ` · ${product.barcode}` : ''} · {product.unit}
                                                </p>
                                            </div>
                                        </div>
                                    </td>
                                    <td className="text-sm">{product.category?.name || '—'}</td>
                                    <td className="whitespace-nowrap text-right font-bold">{formatMoney(product.price)}</td>
                                    <td className="text-center text-sm">
                                        {(product.variants_count ?? product.variants?.length ?? 0)} /{' '}
                                        {(product.addons_count ?? product.addons?.length ?? 0)}
                                    </td>
                                    <td>
                                        <div className="flex flex-col gap-1">
                                            <Badge tone={product.is_active ? 'success' : 'neutral'}>
                                                {product.is_active ? 'Aktif' : 'Nonaktif'}
                                            </Badge>
                                            <Badge tone={product.is_available ? 'brand' : 'danger'}>
                                                {product.is_available ? 'Tersedia' : 'Habis'}
                                            </Badge>
                                        </div>
                                    </td>
                                    {canManage ? (
                                        <td>
                                            <div className="flex items-center justify-end gap-1.5">
                                                <Button variant="secondary" size="sm" onClick={() => openEdit(product)}>
                                                    <MdEdit className="h-4 w-4" />
                                                    Ubah
                                                </Button>
                                                <Button
                                                    variant="secondary"
                                                    size="sm"
                                                    onClick={() => toggle(product, 'is_available')}
                                                    title={product.is_available ? 'Tandai habis' : 'Tandai tersedia'}
                                                >
                                                    {product.is_available ? <MdToggleOn className="h-5 w-5 text-green-500" /> : <MdToggleOff className="h-5 w-5 text-gray-400" />}
                                                </Button>
                                                <Button
                                                    variant="secondary"
                                                    size="sm"
                                                    onClick={() => toggle(product, 'is_active')}
                                                    title={product.is_active ? 'Nonaktifkan produk' : 'Aktifkan produk'}
                                                >
                                                    <span className={`text-xs font-bold ${product.is_active ? 'text-green-600' : 'text-gray-500'}`}>
                                                        {product.is_active ? 'On' : 'Off'}
                                                    </span>
                                                </Button>
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
                title={editing ? 'Ubah produk' : 'Tambah produk'}
                description="Data produk menjadi acuan katalog pada aplikasi kasir setelah tersinkronisasi."
                size="lg"
                footer={
                    <>
                        <Button variant="secondary" onClick={() => setModalOpen(false)} type="button">
                            Batal
                        </Button>
                        <Button type="submit" form="product-form" disabled={form.processing}>
                            {form.processing ? 'Menyimpan…' : editing ? 'Simpan perubahan' : 'Simpan produk'}
                        </Button>
                    </>
                }
            >
                <form id="product-form" onSubmit={submit} className="space-y-5">
                    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                        <InputField
                            id="name"
                            label="Nama produk"
                            required
                            value={form.data.name}
                            onChange={(event) => form.setData('name', event.target.value)}
                            error={form.errors.name}
                        />
                        <InputField
                            id="sku"
                            label="SKU"
                            required
                            value={form.data.sku}
                            onChange={(event) => form.setData('sku', event.target.value)}
                            error={form.errors.sku}
                            hint="Unik per bisnis."
                        />
                        <SelectField
                            id="category_id"
                            label="Kategori"
                            value={form.data.category_id}
                            onChange={(event) => form.setData('category_id', event.target.value)}
                            error={form.errors.category_id}
                        >
                            <option value="">Tanpa kategori</option>
                            {activeCategories.map((category) => (
                                <option key={category.id} value={category.id}>
                                    {category.name}
                                </option>
                            ))}
                        </SelectField>
                        <InputField
                            id="barcode"
                            label="Barcode"
                            value={form.data.barcode}
                            onChange={(event) => form.setData('barcode', event.target.value)}
                            error={form.errors.barcode}
                        />
                        <InputField
                            id="price"
                            label="Harga jual (Rp)"
                            type="number"
                            min={0}
                            required
                            value={form.data.price}
                            onChange={(event) => form.setData('price', event.target.value)}
                            error={form.errors.price}
                        />
                        <InputField
                            id="production_cost"
                            label="Biaya produksi (Rp)"
                            type="number"
                            min={0}
                            value={form.data.production_cost}
                            onChange={(event) => form.setData('production_cost', event.target.value)}
                            error={form.errors.production_cost}
                            hint="Opsional, untuk perhitungan margin internal."
                        />
                        <InputField
                            id="unit"
                            label="Satuan"
                            value={form.data.unit}
                            onChange={(event) => form.setData('unit', event.target.value)}
                            error={form.errors.unit}
                            hint="Contoh: porsi, gelas, bungkus."
                        />
                        <div className="flex items-end gap-6 pb-2">
                            <Checkbox
                                id="is_active"
                                label="Produk aktif"
                                checked={form.data.is_active}
                                onChange={(event) => form.setData('is_active', event.target.checked)}
                            />
                            <Checkbox
                                id="is_available"
                                label="Tersedia"
                                checked={form.data.is_available}
                                onChange={(event) => form.setData('is_available', event.target.checked)}
                            />
                        </div>
                    </div>

                    <TextareaField
                        id="description"
                        label="Deskripsi"
                        rows={2}
                        value={form.data.description}
                        onChange={(event) => form.setData('description', event.target.value)}
                        error={form.errors.description}
                    />

                    <div>
                        <label htmlFor="image" className="horizon-label">
                            Foto produk
                        </label>
                        <div className="flex items-center gap-3">
                            {editing?.image_url ? (
                                <img src={editing.image_url} alt={editing.name} className="h-14 w-14 rounded-xl object-cover" />
                            ) : (
                                <span className="flex h-14 w-14 items-center justify-center rounded-xl bg-lightPrimary text-gray-400 dark:bg-white/5">
                                    <MdImage className="h-6 w-6" />
                                </span>
                            )}
                            <input
                                id="image"
                                type="file"
                                accept="image/png,image/jpeg,image/webp"
                                onChange={(event) => form.setData('image', event.target.files?.[0] || null)}
                                className="block w-full text-sm text-gray-600 file:mr-3 file:rounded-xl file:border-0 file:bg-brand-50 file:px-4 file:py-2 file:text-sm file:font-bold file:text-brand-600 dark:text-gray-400 dark:file:bg-white/10 dark:file:text-white"
                            />
                        </div>
                        {form.errors.image ? <p className="mt-1.5 text-xs font-medium text-red-500">{form.errors.image}</p> : null}
                    </div>

                    <div className="rounded-2xl border border-gray-200 p-4 dark:border-white/10">
                        <div className="mb-3 flex items-center justify-between">
                            <div>
                                <p className="text-sm font-bold text-navy-700 dark:text-white">Varian</p>
                                <p className="text-xs text-gray-500 dark:text-gray-400">Selisih harga diterapkan pada harga dasar produk.</p>
                            </div>
                            <Button type="button" variant="secondary" size="sm" onClick={() => addRow('variants')}>
                                <MdAdd className="h-4 w-4" />
                                Varian
                            </Button>
                        </div>
                        {form.data.variants.length === 0 ? (
                            <p className="text-xs text-gray-500 dark:text-gray-400">Belum ada varian.</p>
                        ) : (
                            <div className="space-y-2">
                                {form.data.variants.map((variant, index) => (
                                    <div key={index} className="grid grid-cols-1 gap-2 sm:grid-cols-[1fr_1fr_140px_auto]">
                                        <input
                                            className="horizon-input"
                                            placeholder="Nama varian"
                                            value={variant.name}
                                            onChange={(event) => updateRow('variants', index, 'name', event.target.value)}
                                        />
                                        <input
                                            className="horizon-input"
                                            placeholder="SKU varian"
                                            value={variant.sku}
                                            onChange={(event) => updateRow('variants', index, 'sku', event.target.value)}
                                        />
                                        <input
                                            className="horizon-input"
                                            type="number"
                                            placeholder="Selisih harga"
                                            value={variant.price_delta}
                                            onChange={(event) => updateRow('variants', index, 'price_delta', event.target.value)}
                                        />
                                        <Button
                                            type="button"
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => removeRow('variants', index)}
                                            title="Hapus varian"
                                        >
                                            <MdDelete className="h-4 w-4 text-red-500" />
                                        </Button>
                                    </div>
                                ))}
                            </div>
                        )}
                        {form.errors.variants ? <p className="mt-2 text-xs text-red-500">{form.errors.variants}</p> : null}
                    </div>

                    <div className="rounded-2xl border border-gray-200 p-4 dark:border-white/10">
                        <div className="mb-3 flex items-center justify-between">
                            <div>
                                <p className="text-sm font-bold text-navy-700 dark:text-white">Add-on</p>
                                <p className="text-xs text-gray-500 dark:text-gray-400">Tambahan berbayar yang dapat dipilih kasir.</p>
                            </div>
                            <Button type="button" variant="secondary" size="sm" onClick={() => addRow('addons')}>
                                <MdAdd className="h-4 w-4" />
                                Add-on
                            </Button>
                        </div>
                        {form.data.addons.length === 0 ? (
                            <p className="text-xs text-gray-500 dark:text-gray-400">Belum ada add-on.</p>
                        ) : (
                            <div className="space-y-2">
                                {form.data.addons.map((addon, index) => (
                                    <div key={index} className="grid grid-cols-1 gap-2 sm:grid-cols-[1fr_160px_auto]">
                                        <input
                                            className="horizon-input"
                                            placeholder="Nama add-on"
                                            value={addon.name}
                                            onChange={(event) => updateRow('addons', index, 'name', event.target.value)}
                                        />
                                        <input
                                            className="horizon-input"
                                            type="number"
                                            min={0}
                                            placeholder="Harga"
                                            value={addon.price}
                                            onChange={(event) => updateRow('addons', index, 'price', event.target.value)}
                                        />
                                        <Button
                                            type="button"
                                            variant="ghost"
                                            size="sm"
                                            onClick={() => removeRow('addons', index)}
                                            title="Hapus add-on"
                                        >
                                            <MdDelete className="h-4 w-4 text-red-500" />
                                        </Button>
                                    </div>
                                ))}
                            </div>
                        )}
                        {form.errors.addons ? <p className="mt-2 text-xs text-red-500">{form.errors.addons}</p> : null}
                    </div>
                </form>
            </Modal>

            <Modal open={!!preview} onClose={() => setPreview(null)} title="Foto produk" size="md">
                {preview ? <img src={preview} alt="Foto produk" className="mx-auto max-h-[60vh] rounded-2xl object-contain" /> : null}
            </Modal>
        </>
    );
}

ProductsIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
