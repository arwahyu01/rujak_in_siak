import { Head, useForm } from '@inertiajs/react';
import { MdOutlinePayments, MdSave, MdSettings } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import Card from '@/Components/Horizon/Card';
import Button from '@/Components/UI/Button';
import Checkbox from '@/Components/UI/Checkbox';

export default function BusinessSettings({ business, settings }) {
    const form = useForm({
        non_cash_proof_required: !!settings.non_cash_proof_required,
    });

    const submit = (event) => {
        event.preventDefault();
        form.put('/settings/business', { preserveScroll: true });
    };

    return (
        <>
            <Head title="Pengaturan Bisnis" />
            <PageHeader
                eyebrow="Administrasi"
                title="Pengaturan Bisnis"
                description="Atur kebijakan operasional yang berlaku untuk seluruh outlet dan perangkat kasir."
            />

            <form onSubmit={submit} className="grid grid-cols-1 gap-5 xl:grid-cols-3">
                <Card className="overflow-hidden xl:col-span-2">
                    <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                        <MdOutlinePayments className="h-5 w-5 text-brand-500" />
                        <div>
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Pembayaran Non-Tunai</h2>
                            <p className="text-xs text-gray-600 dark:text-gray-400">
                                Kebijakan bukti pembayaran untuk QRIS, transfer bank, dan e-wallet.
                            </p>
                        </div>
                    </div>
                    <div className="space-y-4 px-5 py-5">
                        <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 dark:border-amber-500/30 dark:bg-amber-500/10">
                            <p className="text-xs leading-5 text-amber-800 dark:text-amber-300">
                                Jika diaktifkan, kasir dan admin wajib melampirkan foto bukti sebelum checkout non-tunai.
                                Owner selalu dikecualikan dari kewajiban ini. Referensi pembayaran tetap opsional dan dapat
                                diisi nama pelanggan atau catatan lain.
                            </p>
                        </div>

                        <Checkbox
                            id="non_cash_proof_required"
                            label="Wajibkan foto bukti untuk pembayaran non-tunai"
                            checked={form.data.non_cash_proof_required}
                            onChange={(event) => form.setData('non_cash_proof_required', event.target.checked)}
                        />
                        {form.errors.non_cash_proof_required ? (
                            <p className="text-xs font-medium text-red-600 dark:text-red-400">{form.errors.non_cash_proof_required}</p>
                        ) : null}

                        <div className="flex justify-end pt-2">
                            <Button type="submit" disabled={form.processing}>
                                <MdSave className="h-4 w-4" />
                                {form.processing ? 'Menyimpan…' : 'Simpan pengaturan'}
                            </Button>
                        </div>
                    </div>
                </Card>

                <Card className="overflow-hidden">
                    <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                        <MdSettings className="h-5 w-5 text-brand-500" />
                        <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Info Bisnis</h2>
                    </div>
                    <dl className="space-y-3 px-5 py-5 text-sm">
                        <div>
                            <dt className="text-xs text-gray-500 dark:text-gray-400">Nama bisnis</dt>
                            <dd className="font-bold text-navy-700 dark:text-white">{business.name}</dd>
                        </div>
                        <div>
                            <dt className="text-xs text-gray-500 dark:text-gray-400">Mata uang</dt>
                            <dd className="font-medium text-navy-700 dark:text-white">{business.currency || 'IDR'}</dd>
                        </div>
                        <div>
                            <dt className="text-xs text-gray-500 dark:text-gray-400">Zona waktu</dt>
                            <dd className="font-medium text-navy-700 dark:text-white">{business.timezone || 'Asia/Jakarta'}</dd>
                        </div>
                    </dl>
                </Card>
            </form>
        </>
    );
}

BusinessSettings.layout = (page) => <AdminLayout>{page}</AdminLayout>;
