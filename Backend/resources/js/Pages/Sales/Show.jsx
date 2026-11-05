import { Head, Link, useForm } from '@inertiajs/react';
import { useState } from 'react';
import {
    MdArrowBack,
    MdHistory,
    MdOutlinePayments,
    MdOutlineReceiptLong,
    MdReplay,
    MdWarning,
} from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import Card from '@/Components/Horizon/Card';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import Modal from '@/Components/UI/Modal';
import InputField from '@/Components/UI/InputField';
import TextareaField from '@/Components/UI/TextareaField';
import EmptyState from '@/Components/UI/EmptyState';
import {
    formatDateTime,
    formatMoney,
    lifecycleLabels,
    orderTypeLabels,
    paymentEntryStatusLabels,
    paymentMethodLabels,
    paymentStatusLabels,
    statusTone,
} from '@/lib/format';

export default function SaleShow({ sale, auditTrail, abilities, voidBlockedReason, refundableAmount }) {
    const [voidOpen, setVoidOpen] = useState(false);
    const [refundOpen, setRefundOpen] = useState(false);

    const voidForm = useForm({ reason: '' });
    const refundForm = useForm({ amount: refundableAmount || 0, reason: '' });

    const submitVoid = (event) => {
        event.preventDefault();
        voidForm.post(`/sales/${sale.id}/void`, {
            preserveScroll: true,
            onSuccess: () => {
                setVoidOpen(false);
                voidForm.reset();
            },
        });
    };

    const submitRefund = (event) => {
        event.preventDefault();
        refundForm.post(`/sales/${sale.id}/refund`, {
            preserveScroll: true,
            onSuccess: () => {
                setRefundOpen(false);
                refundForm.reset();
            },
        });
    };

    const awaiting = sale.awaiting_verification_amount || 0;

    return (
        <>
            <Head title={`Transaksi ${sale.receipt_number}`} />
            <PageHeader
                eyebrow="Detail transaksi"
                title={sale.receipt_number}
                description={`${orderTypeLabels[sale.order_type] || sale.order_type} · ${formatDateTime(sale.transacted_at)} · ${
                    sale.outlet?.name || ''
                }`}
            >
                <Link href="/sales">
                    <Button variant="secondary">
                        <MdArrowBack className="h-4 w-4" />
                        Kembali
                    </Button>
                </Link>
                <Button
                    variant="danger"
                    onClick={() => {
                        voidForm.clearErrors();
                        setVoidOpen(true);
                    }}
                    disabled={!abilities.void}
                    title={voidBlockedReason || 'Void transaksi'}
                >
                    Void
                </Button>
                <Button
                    variant="primary"
                    onClick={() => {
                        refundForm.setData({ amount: refundableAmount || 0, reason: '' });
                        refundForm.clearErrors();
                        setRefundOpen(true);
                    }}
                    disabled={!abilities.refund}
                    title={abilities.refund ? 'Catat refund' : 'Tidak ada dana terkonfirmasi yang dapat direfund'}
                >
                    <MdReplay className="h-4 w-4" />
                    Refund
                </Button>
            </PageHeader>

            {voidBlockedReason ? (
                <div className="mb-5 flex items-start gap-3 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 dark:border-amber-500/30 dark:bg-amber-500/10">
                    <MdWarning className="mt-0.5 h-5 w-5 shrink-0 text-amber-600" />
                    <p className="text-sm text-amber-800 dark:text-amber-200">
                        Void tidak tersedia: {voidBlockedReason}
                    </p>
                </div>
            ) : null}

            <div className="grid grid-cols-1 gap-5 xl:grid-cols-3">
                <div className="space-y-5 xl:col-span-2">
                    <Card className="p-5">
                        <div className="flex flex-wrap items-start justify-between gap-3">
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Ringkasan Transaksi</h2>
                                <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Nilai final dan status pembayaran aktual.</p>
                            </div>
                            <div className="flex flex-wrap gap-2">
                                <Badge tone={statusTone(sale.lifecycle_status)}>
                                    {lifecycleLabels[sale.lifecycle_status] || sale.lifecycle_status}
                                </Badge>
                                <Badge tone={statusTone(sale.payment_status)}>
                                    {paymentStatusLabels[sale.payment_status] || sale.payment_status}
                                </Badge>
                            </div>
                        </div>

                        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
                            <Metric label="Subtotal" value={formatMoney(sale.subtotal)} />
                            <Metric label="Diskon" value={formatMoney(sale.discount_total)} />
                            <Metric label="Service charge" value={formatMoney(sale.service_charge)} />
                            <Metric label="Pajak" value={formatMoney(sale.tax_total)} />
                            <Metric label="Total" value={formatMoney(sale.total)} strong />
                            <Metric label="Diterima (terkonfirmasi)" value={formatMoney(sale.confirmed_amount)} />
                            <Metric label="Menunggu verifikasi" value={formatMoney(sale.awaiting_verification_amount)} tone="amber" />
                            <Metric label="Outstanding" value={formatMoney(sale.outstanding_amount)} tone="red" />
                            <Metric label="Refund" value={formatMoney(sale.refunded_amount)} tone="red" />
                        </div>

                        {sale.notes ? (
                            <div className="mt-4 rounded-xl bg-lightPrimary px-4 py-3 text-sm text-gray-700 dark:bg-white/5 dark:text-gray-300">
                                <span className="font-bold">Catatan:</span> {sale.notes}
                            </div>
                        ) : null}

                        {sale.lifecycle_status === 'voided' ? (
                            <div className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                                <p className="font-bold">Transaksi di-void</p>
                                <p className="mt-1">{sale.void_reason || 'Tanpa alasan tercatat.'}</p>
                                <p className="mt-1 text-xs">
                                    Oleh {sale.voided_by?.name || '—'} · {formatDateTime(sale.voided_at)}
                                </p>
                            </div>
                        ) : null}
                    </Card>

                    <Card className="overflow-hidden">
                        <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                            <MdOutlineReceiptLong className="h-5 w-5 text-brand-500" />
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Item Transaksi</h2>
                                <p className="text-xs text-gray-600 dark:text-gray-400">Snapshot produk saat transaksi terjadi.</p>
                            </div>
                        </div>
                        {sale.items.length === 0 ? (
                            <EmptyState compact title="Tidak ada item" description="Detail item tidak tersedia pada transaksi ini." />
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="horizon-table">
                                    <thead>
                                        <tr>
                                            <th>Produk</th>
                                            <th className="text-center">Qty</th>
                                            <th className="text-right">Harga</th>
                                            <th className="text-right">Diskon</th>
                                            <th className="text-right">Total</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {sale.items.map((item) => (
                                            <tr key={item.id}>
                                                <td>
                                                    <p className="font-bold text-navy-700 dark:text-white">{item.product_name}</p>
                                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                                        {item.sku || '—'}
                                                        {item.variant_name ? ` · ${item.variant_name}` : ''}
                                                        {item.addon_summary ? ` · ${item.addon_summary}` : ''}
                                                    </p>
                                                </td>
                                                <td className="text-center">{item.quantity}</td>
                                                <td className="whitespace-nowrap text-right">{formatMoney(item.unit_price)}</td>
                                                <td className="whitespace-nowrap text-right">{formatMoney(item.discount_amount)}</td>
                                                <td className="whitespace-nowrap text-right font-bold">{formatMoney(item.total)}</td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </Card>

                    <Card className="overflow-hidden">
                        <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                            <MdOutlinePayments className="h-5 w-5 text-brand-500" />
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Pembayaran</h2>
                                <p className="text-xs text-gray-600 dark:text-gray-400">
                                    Hanya pembayaran terkonfirmasi yang dihitung sebagai dana diterima.
                                </p>
                            </div>
                        </div>
                        {sale.payments.length === 0 ? (
                            <EmptyState compact title="Belum ada pembayaran" description="Transaksi ini belum memiliki catatan pembayaran." />
                        ) : (
                            <div className="divide-y divide-gray-100 dark:divide-white/5">
                                {sale.payments.map((payment) => (
                                    <div key={payment.id} className="px-5 py-4">
                                        <div className="flex flex-wrap items-start justify-between gap-3">
                                            <div>
                                                <div className="flex flex-wrap items-center gap-2">
                                                    <p className="font-bold text-navy-700 dark:text-white">
                                                        {paymentMethodLabels[payment.method] || payment.method}
                                                    </p>
                                                    <Badge tone={statusTone(payment.status)}>
                                                        {paymentEntryStatusLabels[payment.status] || payment.status}
                                                    </Badge>
                                                </div>
                                                <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                                    Dicatat oleh {payment.recorded_by?.name || '—'} · {formatDateTime(payment.recorded_at)}
                                                </p>
                                                {payment.provider_reference ? (
                                                    <p className="text-xs text-gray-500 dark:text-gray-400">
                                                        Referensi: <span className="font-medium">{payment.provider_reference}</span>
                                                    </p>
                                                ) : null}
                                            </div>
                                            <div className="text-right">
                                                <p className="text-xs text-gray-500 dark:text-gray-400">Tercatat</p>
                                                <p className="font-bold text-navy-700 dark:text-white">{formatMoney(payment.amount)}</p>
                                                {payment.verified_amount !== null ? (
                                                    <p className="text-xs text-green-600 dark:text-green-400">
                                                        Terverifikasi {formatMoney(payment.verified_amount)}
                                                    </p>
                                                ) : null}
                                            </div>
                                        </div>

                                        {payment.rejection_reason ? (
                                            <div className="mt-3 rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-xs text-red-700 dark:border-red-500/30 dark:bg-red-500/10 dark:text-red-300">
                                                <span className="font-bold">Ditolak:</span> {payment.rejection_reason}
                                                {payment.rejected_by ? ` — ${payment.rejected_by.name}` : ''}
                                            </div>
                                        ) : null}

                                        {payment.verification_logs?.length > 0 ? (
                                            <div className="mt-3 rounded-xl bg-lightPrimary px-3 py-2 dark:bg-white/5">
                                                <p className="mb-1 text-[11px] font-bold uppercase tracking-wide text-gray-500">
                                                    Jejak verifikasi
                                                </p>
                                                <ul className="space-y-1">
                                                    {payment.verification_logs.map((log) => (
                                                        <li key={log.id} className="text-xs text-gray-600 dark:text-gray-400">
                                                            <span className="font-bold text-navy-700 dark:text-white">{log.action}</span> oleh{' '}
                                                            {log.actor?.name || '—'} · tercatat {formatMoney(log.recorded_amount)}
                                                            {log.verified_amount !== null ? ` → ${formatMoney(log.verified_amount)}` : ''}
                                                            {log.reason ? ` · ${log.reason}` : ''}
                                                        </li>
                                                    ))}
                                                </ul>
                                            </div>
                                        ) : null}
                                    </div>
                                ))}
                            </div>
                        )}
                    </Card>

                    {sale.refunds?.length > 0 ? (
                        <Card className="overflow-hidden">
                            <div className="border-b border-gray-100 px-5 py-4 dark:border-white/10">
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Refund</h2>
                            </div>
                            <div className="divide-y divide-gray-100 dark:divide-white/5">
                                {sale.refunds.map((refund) => (
                                    <div key={refund.id} className="flex flex-wrap items-start justify-between gap-3 px-5 py-3">
                                        <div>
                                            <p className="text-sm text-navy-700 dark:text-white">{refund.reason}</p>
                                            <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                                                {refund.created_by?.name || '—'} · {formatDateTime(refund.refunded_at)}
                                            </p>
                                        </div>
                                        <p className="font-bold text-red-500">{formatMoney(refund.amount)}</p>
                                    </div>
                                ))}
                            </div>
                        </Card>
                    ) : null}
                </div>

                <div className="space-y-5">
                    <Card className="p-5">
                        <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Informasi</h2>
                        <dl className="mt-4 space-y-3 text-sm">
                            <Info label="Kasir" value={sale.cashier?.name} />
                            <Info label="Outlet" value={sale.outlet?.name} />
                            <Info label="Perangkat" value={sale.device?.name ? `${sale.device.name} (${sale.device.terminal_code})` : null} />
                            <Info
                                label="Shift"
                                value={
                                    sale.shift ? (
                                        <Link href={`/shifts/${sale.shift.id}`} className="font-bold text-brand-500 hover:text-brand-600">
                                            {sale.shift.status}
                                        </Link>
                                    ) : null
                                }
                            />
                            <Info label="Waktu transaksi" value={formatDateTime(sale.transacted_at)} />
                            <Info label="Nomor meja" value={sale.table_number} />
                            <Info label="Tipe order" value={orderTypeLabels[sale.order_type] || sale.order_type} />
                            <Info label="UUID" value={<span className="break-all text-xs">{sale.uuid}</span>} />
                        </dl>
                    </Card>

                    <Card className="overflow-hidden">
                        <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                            <MdHistory className="h-5 w-5 text-brand-500" />
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Audit Trail</h2>
                                <p className="text-xs text-gray-600 dark:text-gray-400">Aksi sensitif pada transaksi ini.</p>
                            </div>
                        </div>
                        {auditTrail.length === 0 ? (
                            <EmptyState compact title="Belum ada audit" description="Belum ada aksi sensitif yang tercatat." />
                        ) : (
                            <ul className="divide-y divide-gray-100 dark:divide-white/5">
                                {auditTrail.map((log) => (
                                    <li key={log.id} className="px-5 py-3">
                                        <p className="text-sm font-medium text-navy-700 dark:text-white">{log.description}</p>
                                        <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">
                                            {log.user?.name || 'Sistem'} · {formatDateTime(log.created_at)}
                                        </p>
                                    </li>
                                ))}
                            </ul>
                        )}
                    </Card>

                    {awaiting > 0 && sale.lifecycle_status !== 'voided' ? (
                        <Card className="p-5">
                            <p className="text-sm font-bold text-amber-600 dark:text-amber-400">Ada pembayaran menunggu verifikasi</p>
                            <p className="mt-1 text-xs text-gray-600 dark:text-gray-400">
                                Selesaikan verifikasi atau penolakan pada antrean pembayaran sebelum melakukan void.
                            </p>
                            <Link href="/payments/pending" className="mt-3 inline-block">
                                <Button variant="secondary" size="sm">
                                    Buka antrean
                                </Button>
                            </Link>
                        </Card>
                    ) : null}
                </div>
            </div>

            <Modal
                open={voidOpen}
                onClose={() => setVoidOpen(false)}
                title="Void transaksi?"
                description="Void hanya dapat dilakukan jika belum ada pembayaran terkonfirmasi dan tidak ada pembayaran menunggu verifikasi."
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" type="button" onClick={() => setVoidOpen(false)}>
                            Batal
                        </Button>
                        <Button variant="danger" type="submit" form="void-form" disabled={voidForm.processing}>
                            {voidForm.processing ? 'Memproses…' : 'Void transaksi'}
                        </Button>
                    </>
                }
            >
                <form id="void-form" onSubmit={submitVoid} className="space-y-4">
                    <TextareaField
                        id="void_reason"
                        label="Alasan void"
                        required
                        rows={4}
                        value={voidForm.data.reason}
                        onChange={(event) => voidForm.setData('reason', event.target.value)}
                        error={voidForm.errors.reason || voidForm.errors.sale}
                        placeholder="Jelaskan alasan void secara rinci. Alasan tercatat pada audit log."
                    />
                </form>
            </Modal>

            <Modal
                open={refundOpen}
                onClose={() => setRefundOpen(false)}
                title="Catat refund"
                description={`Dana terkonfirmasi yang dapat direfund: ${formatMoney(refundableAmount)}.`}
                size="sm"
                footer={
                    <>
                        <Button variant="secondary" type="button" onClick={() => setRefundOpen(false)}>
                            Batal
                        </Button>
                        <Button type="submit" form="refund-form" disabled={refundForm.processing}>
                            {refundForm.processing ? 'Memproses…' : 'Simpan refund'}
                        </Button>
                    </>
                }
            >
                <form id="refund-form" onSubmit={submitRefund} className="space-y-4">
                    <InputField
                        id="amount"
                        label="Nominal refund (Rp)"
                        type="number"
                        min={1}
                        max={refundableAmount}
                        required
                        value={refundForm.data.amount}
                        onChange={(event) => refundForm.setData('amount', event.target.value)}
                        error={refundForm.errors.amount}
                        hint={`Maksimal ${formatMoney(refundableAmount)}.`}
                    />
                    <TextareaField
                        id="refund_reason"
                        label="Alasan refund"
                        required
                        rows={4}
                        value={refundForm.data.reason}
                        onChange={(event) => refundForm.setData('reason', event.target.value)}
                        error={refundForm.errors.reason || refundForm.errors.sale}
                        placeholder="Jelaskan alasan refund. Alasan tercatat pada audit log."
                    />
                </form>
            </Modal>
        </>
    );
}

function Metric({ label, value, strong = false, tone }) {
    const tones = {
        amber: 'text-amber-600 dark:text-amber-400',
        red: 'text-red-500 dark:text-red-400',
    };
    return (
        <div className="rounded-xl bg-lightPrimary p-3 dark:bg-white/5">
            <p className="text-[11px] text-gray-600 dark:text-gray-400">{label}</p>
            <p className={`mt-1 font-poppins ${strong ? 'text-lg' : 'text-sm'} font-bold ${tone ? tones[tone] : 'text-navy-700 dark:text-white'}`}>
                {value}
            </p>
        </div>
    );
}

function Info({ label, value }) {
    return (
        <div className="flex items-start justify-between gap-3">
            <dt className="shrink-0 text-xs text-gray-500 dark:text-gray-400">{label}</dt>
            <dd className="text-right text-sm font-medium text-navy-700 dark:text-white">{value || '—'}</dd>
        </div>
    );
}

SaleShow.layout = (page) => <AdminLayout>{page}</AdminLayout>;
