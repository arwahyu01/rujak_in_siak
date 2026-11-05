import { Head, useForm } from '@inertiajs/react';
import { useState } from 'react';
import { MdAdminPanelSettings, MdLock, MdSave } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import Card from '@/Components/Horizon/Card';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import InputField from '@/Components/UI/InputField';
import TextareaField from '@/Components/UI/TextareaField';
import Checkbox from '@/Components/UI/Checkbox';
import { formatNumber } from '@/lib/format';

export default function RolesIndex({ roles, permissionGroups }) {
    const [selectedId, setSelectedId] = useState(roles.find((role) => role.slug !== 'owner')?.id || roles[0]?.id);
    const selected = roles.find((role) => role.id === selectedId) || roles[0];

    const form = useForm({
        name: selected?.name || '',
        description: selected?.description || '',
        permissions: (selected?.permissions || []).map((permission) => permission.id),
    });

    const selectRole = (role) => {
        setSelectedId(role.id);
        form.setData({
            name: role.name,
            description: role.description || '',
            permissions: (role.permissions || []).map((permission) => permission.id),
        });
        form.clearErrors();
    };

    const togglePermission = (id) => {
        const current = form.data.permissions;
        form.setData(
            'permissions',
            current.includes(id) ? current.filter((value) => value !== id) : [...current, id],
        );
    };

    const toggleGroup = (group) => {
        const ids = group.permissions.map((permission) => permission.id);
        const allSelected = ids.every((id) => form.data.permissions.includes(id));
        form.setData(
            'permissions',
            allSelected
                ? form.data.permissions.filter((id) => !ids.includes(id))
                : Array.from(new Set([...form.data.permissions, ...ids])),
        );
    };

    const submit = (event) => {
        event.preventDefault();
        if (!selected) return;
        form.put(`/roles/${selected.id}`, { preserveScroll: true });
    };

    const locked = selected?.slug === 'owner';

    return (
        <>
            <Head title="Peran & Hak Akses" />
            <PageHeader
                eyebrow="Administrasi"
                title="Peran & Hak Akses"
                description="Peran Owner selalu memiliki seluruh permission. Peran lain dapat disesuaikan, tetapi tidak boleh melepas akses web selama masih dipakai pengguna aktif."
            />

            <div className="grid grid-cols-1 gap-5 xl:grid-cols-[300px_1fr]">
                <Card className="h-fit overflow-hidden">
                    <div className="border-b border-gray-100 px-5 py-4 dark:border-white/10">
                        <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Daftar Peran</h2>
                        <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Pilih peran untuk mengatur permission.</p>
                    </div>
                    <ul className="divide-y divide-gray-100 dark:divide-white/5">
                        {roles.map((role) => (
                            <li key={role.id}>
                                <button
                                    type="button"
                                    onClick={() => selectRole(role)}
                                    className={`flex w-full items-start justify-between gap-3 px-5 py-4 text-left transition ${
                                        role.id === selected?.id
                                            ? 'bg-brand-50 dark:bg-brand-500/10'
                                            : 'hover:bg-lightPrimary dark:hover:bg-white/5'
                                    }`}
                                >
                                    <div className="min-w-0">
                                        <div className="flex items-center gap-2">
                                            <p className="truncate text-sm font-bold text-navy-700 dark:text-white">{role.name}</p>
                                            {role.slug === 'owner' ? <MdLock className="h-3.5 w-3.5 text-gray-400" /> : null}
                                        </div>
                                        <p className="mt-0.5 line-clamp-2 text-xs text-gray-500 dark:text-gray-400">
                                            {role.description || 'Tanpa deskripsi'}
                                        </p>
                                        <p className="mt-1.5 text-[11px] text-gray-500 dark:text-gray-400">
                                            {formatNumber(role.users_count)} pengguna · {formatNumber(role.permissions?.length || 0)} permission
                                        </p>
                                    </div>
                                    <Badge tone={role.slug === 'owner' ? 'brand' : 'neutral'}>{role.slug}</Badge>
                                </button>
                            </li>
                        ))}
                    </ul>
                </Card>

                <Card className="overflow-hidden">
                    <div className="flex flex-wrap items-start justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                        <div className="flex items-start gap-3">
                            <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-500 dark:bg-brand-500/10 dark:text-brand-300">
                                <MdAdminPanelSettings className="h-5 w-5" />
                            </span>
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">
                                    {selected?.name || 'Pilih peran'}
                                </h2>
                                <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                                    {locked
                                        ? 'Peran Owner tidak dapat diubah dan selalu memiliki seluruh permission.'
                                        : 'Centang permission yang diberikan kepada peran ini.'}
                                </p>
                            </div>
                        </div>
                        {!locked ? (
                            <Button type="submit" form="role-form" disabled={form.processing}>
                                <MdSave className="h-4 w-4" />
                                {form.processing ? 'Menyimpan…' : 'Simpan'}
                            </Button>
                        ) : null}
                    </div>

                    <form id="role-form" onSubmit={submit} className="space-y-5 p-5">
                        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                            <InputField
                                id="role_name"
                                label="Nama peran"
                                value={form.data.name}
                                onChange={(event) => form.setData('name', event.target.value)}
                                error={form.errors.name}
                                disabled={locked}
                            />
                            <TextareaField
                                id="role_description"
                                label="Deskripsi"
                                rows={1}
                                value={form.data.description}
                                onChange={(event) => form.setData('description', event.target.value)}
                                error={form.errors.description}
                                disabled={locked}
                            />
                        </div>

                        {form.errors.permissions ? (
                            <p className="rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600 dark:bg-red-500/10 dark:text-red-300">
                                {form.errors.permissions}
                            </p>
                        ) : null}
                        {form.errors.role ? (
                            <p className="rounded-xl bg-red-50 px-3 py-2 text-sm text-red-600 dark:bg-red-500/10 dark:text-red-300">
                                {form.errors.role}
                            </p>
                        ) : null}

                        <div className="space-y-3">
                            {permissionGroups.map((group) => {
                                const ids = group.permissions.map((permission) => permission.id);
                                const selectedCount = ids.filter((id) => form.data.permissions.includes(id)).length;
                                const allSelected = selectedCount === ids.length;
                                return (
                                    <div key={group.module} className="rounded-2xl border border-gray-200 dark:border-white/10">
                                        <div className="flex items-center justify-between gap-3 border-b border-gray-100 px-4 py-3 dark:border-white/10">
                                            <div>
                                                <p className="text-sm font-bold text-navy-700 dark:text-white">{group.label}</p>
                                                <p className="text-xs text-gray-500 dark:text-gray-400">
                                                    {selectedCount} dari {ids.length} permission dipilih
                                                </p>
                                            </div>
                                            <button
                                                type="button"
                                                onClick={() => toggleGroup(group)}
                                                disabled={locked}
                                                className={`rounded-lg px-3 py-1.5 text-xs font-bold transition ${
                                                    locked
                                                        ? 'cursor-not-allowed text-gray-400'
                                                        : 'bg-lightPrimary text-navy-700 hover:bg-brand-50 dark:bg-white/5 dark:text-white'
                                                }`}
                                            >
                                                {allSelected ? 'Batalkan semua' : 'Pilih semua'}
                                            </button>
                                        </div>
                                        <div className="grid grid-cols-1 gap-2 px-4 py-3 sm:grid-cols-2">
                                            {group.permissions.map((permission) => (
                                                <Checkbox
                                                    key={permission.id}
                                                    id={`permission-${permission.id}`}
                                                    label={permission.name}
                                                    checked={form.data.permissions.includes(permission.id)}
                                                    onChange={() => togglePermission(permission.id)}
                                                    className={locked ? 'pointer-events-none opacity-70' : ''}
                                                />
                                            ))}
                                        </div>
                                    </div>
                                );
                            })}
                        </div>

                        {locked ? (
                            <p className="text-xs text-gray-500 dark:text-gray-400">
                                Permission peran Owner dikelola otomatis oleh sistem dan tidak dapat diubah dari halaman ini.
                            </p>
                        ) : null}
                    </form>
                </Card>
            </div>
        </>
    );
}

RolesIndex.layout = (page) => <AdminLayout>{page}</AdminLayout>;
