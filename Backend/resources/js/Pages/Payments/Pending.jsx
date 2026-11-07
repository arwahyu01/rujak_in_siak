import { Head, Link, router, useForm } from '@inertiajs/react';
import { useState } from 'react';
import {
    MdCheckCircle,
    MdErrorOutline,
    MdSearch,
    MdVerifiedUser,
    MdWarning,
} from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import StatCard from '@/Components/UI/StatCard';
import Card from '@/Components/Horizon/Card';
import TableShell from '@/Components/UI/TableShell';
import Pagination from '@/Components/UI/Pagination';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import Modal from '@/Components/UI/Modal';
import PaymentProofImage from '@/Components/UI/PaymentProofImage';
import InputField from '@/Components/UI/InputField';
import SelectField from '@/Components/UI/SelectField';
import TextareaField from '@/Components/UI/TextareaField';
import {
    formatDateTime,
    formatMoney,
    formatNumber,
    paymentEntryStatusLabels,
    paymentMethodLabels,
    statusTone,
} from '@/lib/format';

export default function PaymentsPending({ payments, summary, recent, filters, separationOfDuties }) {
    const [search, setSearch] = useState(filters.q || '');
    const [method, setMethod] = useState(filters.method || '');
    const [verifying, setVerifying] = useState(null);
    const [rejecting, setRejecting] = useState(null);

    const verifyForm = useForm({
        verified_amount: 0,
        provider_reference: '',
        verification_note: '',
        correction_reason: '',
    });
    const rejectForm = useForm({ reason: '', notes: '' });

    const applyFilters = (event) => {
        event?.preventDefault();
        router.get('/payments/pending', { q: search, method }, { preserveState: true, preserveScroll: true, replace: true });
    };

    const openVerify = (payment) => {
        setVerifying(payment);
        verifyForm.setData({
            verified_amount: payment.amount,
            provider_reference: payment.provider_reference || '',
            verification_note: '',
            correction_reason: '',
        });
        verifyForm.clearErrors();
    };

    const openReject = (payment) => {
        setRejecting(payment);
        rejectForm.setData({ reason: '', notes: '' });
        rejectForm.clearErrors();
    };

    const submitVerify = (event) => {
        event.preventDefault();
        verifyForm.post(`/payments/${verifying.id}/verify`, {
            preserveScroll: true,
            onSuccess: () => {
                setVerifying(null);
                verifyForm.reset();
            },
        });
    };

    const submitReject = (event) => {
        event.preventDefault();
        rejectForm.post(`/payments/${rejecting.id}/reject`, {
            preserveScroll: true,
            onSuccess: () => {
                setRejecting(null);
                rejectForm.reset();
            },
        });
    };

    const isCorrection = verifying && Number(verifyForm.data.verified_amount || 0) > Number(verifying.amount || 0);

    return (
        <>
            <Head title="Verifikasi Pembayaran" />
            <PageHeader
                eyebrow="Pembayaran non-tunai"
                title="Antrean Verifikasi"
                description="Pembayaran non-tunai wajib diverifikasi oleh pengguna berbeda dari pencatatnya. Setiap keputusan menyimpan alasan dan audit trail."
            />

            <div className="mb-5 grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <StatCard
                    icon={<MdVerifiedUser className="h-6 w-6" />}
                    label="Menunggu verifikasi"
                    value={formatNumber(summary.count)}
                    detail="Pembayaran pada filter aktif"
                    tone="amber"
                />
                <StatCard
                    icon={<MdOutlinePaymentsIcon />}
                    label="Nilai tercatat"
                    value={formatMoney(summary.total)}
                    detail="Belum dihitung sebagai dana diterima"
                    tone="cyan"
                />
                <StatCard
                    icon={<MdCheckCircle className="h-6 w-6" />}
                    label="Diproses terakhir"
                    value={formatNumber(recent.length)}
                    detail="Verifikasi/penolakan terbaru di bawah"
                    tone="green"
                />
                <StatCard
                    icon={<MdErrorOutline className="h-6 w-6" />}
                    label="Pemisahan tugas"
                    value={separationOfDuties ? 'Aktif' : 'Nonaktif'}
                    detail="Pencatat tidak dapat memverifikasi entrinya"
                    tone="red"
                />
            </div>

            <form onSubmit={applyFilters} className="mb-5 flex flex-col gap-3 rounded-2xl bg-white p-4 shadow-sm dark:bg-navy-800 sm:flex-row sm:items-center">
                <div className="relative flex-1">
                    <MdSearch className="pointer-events-none absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-gray-400" />
                    <input
                        type="text"
                        value={search}
                        onChange={(event) => setSearch(event.target.value)}
                        placeholder="Cari referensi pembayaran atau nomor struk…"
                        className="horizon-input pl-10"
                    />
                </div>
                <SelectField id="method" value={method} onChange={(event) => setMethod(event.target.value)} className="sm:w-56">
                    <option value="">Semua metode</option>
                    <option value="qris">QRIS</option>
                    <option value="transfer">Transfer Bank</option>
                    <option value="ewallet">E-Wallet</option>
                    <option value="cash">Tunai</option>
                </SelectField>
                <Button type="submit" variant="secondary">
                    Terapkan
                </Button>
            </form>

            <div className="mb-5 flex items-start gap-3 rounded-2xl border border-brand-50 bg-brand-50/60 px-4 py-3 dark:border-brand-500/20 dark:bg-brand-500/10">
                <MdWarning className="mt-0.5 h-5 w-5 shrink-0 text-brand-500 dark:text-brand-300" />
                <p className="text-xs leading-5 text-navy-700 dark:text-gray-300">
                    Nominal verifikasi tidak boleh melebihi outstanding transaksi. Koreksi ke nominal lebih besar dari yang tercatat
                    memerlukan permission koreksi dan alasan wajib.
                </p>
            </div>

            <TableShell
                title={`Antrean pembayaran (${payments.total})`}
                description="Gunakan tombol verifikasi atau tolak. Entri yang Anda catat sendiri tidak dapat Anda proses."
                footer={<Pagination paginator={payments} />}
            >
                {payments.data.length === 0 ? (
                    <EmptyState
                        icon={<MdVerifiedUser />}
                        title="Antrean kosong"
                        description="Tidak ada pembayaran non-tunai yang menunggu verifikasi pada filter ini."
                    />
                ) : (
                    <table className="horizon-table">
                        <thead>
                            <tr>
                                <th>Transaksi</th>
                                <th>Metode</th>
                                <th className="text-right">Nominal</th>
                                <th>Catatan</th>
                                <th>Pencatat</th>
                                <th>Status</th>
                                <th className="text-right">Aksi</th>
                            </tr>
                        </thead>
                        <tbody>
                            {payments.data.map((payment) => (
                                <tr key={payment.id}>
                                    <td>
                                        <Link href={`/sales/${payment.sale_id}`} className="font-bold text-brand-500 hover:text-brand-600">
                                            {payment.sale?.receipt_number || '—'}
                                        </Link>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">
                                            Total transaksi {formatMoney(payment.sale?.total || 0)}
                                        </p>
                                    </td>
                                    <td className="text-sm">{paymentMethodLabels[payment.method] || payment.method}</td>
                                    <td className="whitespace-nowrap text-right font-bold">{formatMoney(payment.amount)}</td>
                                    <td className="max-w-[160px]">
                                        <p className="truncate text-xs" title={payment.provider_reference || ''}>
                                            {payment.provider_reference || '—'}
                                        </p>
                                        {payment.has_proof ? (
                                            <PaymentProofImage paymentId={payment.id} className="h-16 w-16" />
                                        ) : null}
                                        {payment.proof_required && !payment.has_proof ? (
                                            <p className="mt-1 text-[11px] font-bold text-red-600 dark:text-red-400">
                                                Bukti wajib diunggah sebelum verifikasi.
                                            </p>
                                        ) : null}
                                    </td>
                                    <td>
                                        <p className="text-sm">{payment.recorded_by?.name || '—'}</p>
                                        <p className="text-xs text-gray-500 dark:text-gray-400">{formatDateTime(payment.recorded_at)}</p>
                                    </td>
                                    <td>
                                        <Badge tone={statusTone(payment.status)}>
                                            {paymentEntryStatusLabels[payment.status] || payment.status}
                                        </Badge>
                                        {payment.is_own_entry ? (
                                            <p className="mt-1 text-[11px] font-medium text-amber-600 dark:text-amber-400">Entri Anda</p>
                                        ) : null}
                                    </td>
                                    <td>
                                        <div className="flex flex-wrap items-center justify-end gap-2">
                                            <Button
                                                size="sm"
                                                variant="success"
                                                disabled={!payment.can_verify}
                                                onClick={() => openVerify(payment)}
                                                title={
                                                    payment.can_verify
                                                        ? 'Verifikasi pembayaran'
                                                        : payment.is_own_entry
                                                          ? 'Pemisahan tugas: tidak dapat memverifikasi entri sendiri'
                                                          : 'Tidak memiliki izin verifikasi'
                                                }
                                            >
                                                Verifikasi
                                            </Button>
                                            <Button
                                                size="sm"
                                                variant="danger"
                                                disabled={!payment.can_reject}
                                                onClick={() => openReject(payment)}
                                                title={
                                                    payment.can_reject
                                                        ? 'Tolak pembayaran'
                                                        : payment.is_own_entry
                                                          ? 'Pemisahan tugas: tidak dapat menolak entri sendiri'
                                                          : 'Tidak memiliki izin penolakan'
                                                }
                                            >
                                                Tolak
                                            </Button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </TableShell>

            <Card className="mt-5 overflow-hidden">
                <div className="border-b border-gray-100 px-5 py-4 dark:border-white/10">
                    <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Keputusan Terbaru</h2>
                    <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                        Verifikasi dan penolakan terakhir beserta aktor dan alasan.
                    </p>
                </div>
                {recent.length === 0 ? (
                    <EmptyState compact title="Belum ada keputusan" description="Belum ada pembayaran yang diverifikasi atau ditolak." />
                ) : (
                    <ul className="divide-y divide-gray-100 dark:divide-white/5">
                        {recent.map((payment) => (
                            <li key={payment.id} className="flex flex-col gap-2 px-5 py-3 sm:flex-row sm:items-start sm:justify-between">
                                <div className="min-w-0">
                                    <div className="flex flex-wrap items-center gap-2">
                                        <Link
                                            href={`/sales/${payment.sale_id}`}
                                            className="text-sm font-bold text-brand-500 hover:text-brand-600"
                                        >
                                            {payment.sale?.receipt_number || '—'}
                                        </Link>
                                        <Badge tone={statusTone(payment.status)}>
                                            {paymentEntryStatusLabels[payment.status] || payment.status}
                                        </Badge>
                                        <span className="text-xs text-gray-500 dark:text-gray-400">
                                            {paymentMethodLabels[payment.method] || payment.method}
                                        </span>
                                    </div>
                                    <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                        {payment.status === 'confirmed'
                                            ? `Diverifikasi oleh ${payment.verified_by?.name || '—'}`
                                            : `Ditolak oleh ${payment.rejected_by?.name || '—'}`}
                                        {' · '}
                                        {formatDateTime(payment.verified_at || payment.rejected_at)}
                                    </p>
                                    {payment.rejection_reason ? (
                                        <p className="mt-1 text-xs text-red-600 dark:text-red-400">Alasan: {payment.rejection_reason}</p>
                                    ) : null}
                                </div>
                                <p className="shrink-0 text-sm font-bold text-navy-700 dark:text-white">
                                    {formatMoney(payment.verified_amount ?? payment.amount)}
                                </p>
                            </li>
                        ))}
                    </ul>
                )}
            </Card>

            <Modal
                open={!!verifying}
                onClose={() => setVerifying(null)}
                title="Verifikasi pembayaran"
                description={
                    verifying
                        ? `${paymentMethodLabels[verifying.method] || verifying.method} · ${verifying.sale?.receipt_number || ''}`
                        : ''
                }
                size="md"
                footer={
                    <>
                        <Button variant="secondary" type="button" onClick={() => setVerifying(null)}>
                            Batal
                        </Button>
                        <Button type="submit" form="verify-form" variant="success" disabled={verifyForm.processing}>
                            {verifyForm.processing ? 'Memproses…' : 'Konfirmasi verifikasi'}
                        </Button>
                    </>
                }
            >
                {verifying ? (
                    <form id="verify-form" onSubmit={submitVerify} className="space-y-4">
                        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
                            <div className="rounded-xl bg-lightPrimary p-3 dark:bg-white/5">
                                <p className="text-[11px] text-gray-600 dark:text-gray-400">Nominal tercatat</p>
                                <p className="font-poppins text-lg font-bold text-navy-700 dark:text-white">
                                    {formatMoney(verifying.amount)}
                                </p>
                            </div>
                            <div className="rounded-xl bg-lightPrimary p-3 dark:bg-white/5">
                                <p className="text-[11px] text-gray-600 dark:text-gray-400">Outstanding transaksi</p>
                                <p className="font-poppins text-lg font-bold text-navy-700 dark:text-white">
                                    {formatMoney(verifying.sale?.outstanding_amount ?? 0)}
                                </p>
                            </div>
                        </div>

                        {verifying.proof_required && !verifying.has_proof ? (
                            <div className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                                Bukti pembayaran wajib diunggah terlebih dahulu. Minta kasir mengunggah bukti atau
                                nonaktifkan kebijakan wajib bukti di Pengaturan Bisnis.
                            </div>
                        ) : null}

                        <InputField
                            id="verified_amount"
                            label="Nominal terverifikasi (Rp)"
                            type="number"
                            min={1}
                            required
                            value={verifyForm.data.verified_amount}
                            onChange={(event) => verifyForm.setData('verified_amount', event.target.value)}
                            error={verifyForm.errors.verified_amount || verifyForm.errors.payment}
                            hint="Tidak boleh melebihi outstanding transaksi."
                        />
                        <InputField
                            id="provider_reference"
                            label="Catatan / referensi pembayaran (opsional)"
                            value={verifyForm.data.provider_reference}
                            onChange={(event) => verifyForm.setData('provider_reference', event.target.value)}
                            error={verifyForm.errors.provider_reference}
                            hint="Boleh dikosongkan. Isi referensi transaksi atau catatan lain bila perlu."
                        />
                        <TextareaField
                            id="verification_note"
                            label="Catatan verifikasi"
                            rows={2}
                            value={verifyForm.data.verification_note}
                            onChange={(event) => verifyForm.setData('verification_note', event.target.value)}
                            error={verifyForm.errors.verification_note}
                        />
                        {isCorrection ? (
                            <TextareaField
                                id="correction_reason"
                                label="Alasan koreksi nominal"
                                required
                                rows={3}
                                value={verifyForm.data.correction_reason}
                                onChange={(event) => verifyForm.setData('correction_reason', event.target.value)}
                                error={verifyForm.errors.correction_reason}
                                hint="Nominal yang diverifikasi lebih besar dari nominal tercatat. Wajib memiliki izin koreksi dan alasan."
                            />
                        ) : null}
                    </form>
                ) : null}
            </Modal>

            <Modal
                open={!!rejecting}
                onClose={() => setRejecting(null)}
                title="Tolak pembayaran"
                description={
                    rejecting
                        ? `Nominal tercatat ${formatMoney(rejecting.amount)} · ${rejecting.sale?.receipt_number || ''}`
                        : ''
                }
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" type="button" onClick={() => setRejecting(null)}>
                            Batal
                        </Button>
                        <Button type="submit" form="reject-form" variant="danger" disabled={rejectForm.processing}>
                            {rejectForm.processing ? 'Memproses…' : 'Tolak pembayaran'}
                        </Button>
                    </>
                }
            >
                <form id="reject-form" onSubmit={submitReject} className="space-y-4">
                    <TextareaField
                        id="reason"
                        label="Alasan penolakan"
                        required
                        rows={4}
                        value={rejectForm.data.reason}
                        onChange={(event) => rejectForm.setData('reason', event.target.value)}
                        error={rejectForm.errors.reason || rejectForm.errors.payment}
                        placeholder="Contoh: mutasi tidak ditemukan, nominal tidak sesuai, atau referensi tidak valid."
                    />
                    <TextareaField
                        id="notes"
                        label="Catatan tambahan"
                        rows={2}
                        value={rejectForm.data.notes}
                        onChange={(event) => rejectForm.setData('notes', event.target.value)}
                        error={rejectForm.errors.notes}
                    />
                </form>
            </Modal>
        </>
    );
}

function MdOutlinePaymentsIcon() {
    return <MdVerifiedUser className="h-6 w-6" />;
}

PaymentsPending.layout = (page) => <AdminLayout>{page}</AdminLayout>;
