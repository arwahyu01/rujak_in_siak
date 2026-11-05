import { Head, Link } from '@inertiajs/react';
import { MdArrowBack, MdOutlineSchedule, MdPointOfSale } from 'react-icons/md';
import AdminLayout from '@/Layouts/AdminLayout';
import PageHeader from '@/Components/UI/PageHeader';
import Card from '@/Components/Horizon/Card';
import Badge from '@/Components/UI/Badge';
import Button from '@/Components/UI/Button';
import EmptyState from '@/Components/UI/EmptyState';
import { formatDateTime, formatMoney, formatNumber, paymentStatusLabels, shiftStatusLabels, statusTone } from '@/lib/format';

export default function ShiftShow({ shift, summary }) {
    return (
        <>
            <Head title={`Shift ${shift.uuid}`} />
            <PageHeader
                eyebrow="Detail shift"
                title={`Shift ${shift.cashier?.name || ''}`}
                description={`${shift.outlet?.name || ''} · dibuka ${formatDateTime(shift.opened_at)}`}
            >
                <Link href="/shifts">
                    <Button variant="secondary">
                        <MdArrowBack className="h-4 w-4" />
                        Kembali
                    </Button>
                </Link>
            </PageHeader>

            <div className="grid grid-cols-1 gap-5 xl:grid-cols-3">
                <div className="space-y-5 xl:col-span-2">
                    <Card className="p-5">
                        <div className="flex flex-wrap items-start justify-between gap-3">
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Ringkasan Shift</h2>
                                <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                                    Rekap transaksi dan pembayaran yang terkait dengan shift ini.
                                </p>
                            </div>
                            <Badge tone={statusTone(shift.status)}>{shiftStatusLabels[shift.status] || shift.status}</Badge>
                        </div>

                        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
                            <Metric label="Transaksi final" value={formatNumber(summary.sales_count)} />
                            <Metric label="Nilai penjualan" value={formatMoney(summary.sales_total)} strong />
                            <Metric label="Transaksi void" value={formatNumber(summary.void_count)} tone="red" />
                            <Metric label="Tunai terkonfirmasi" value={formatMoney(summary.cash_confirmed)} tone="green" />
                            <Metric label="Non-tunai terkonfirmasi" value={formatMoney(summary.noncash_confirmed)} tone="green" />
                            <Metric label="Menunggu verifikasi" value={formatMoney(summary.awaiting)} tone="amber" />
                        </div>
                    </Card>

                    <Card className="p-5">
                        <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Rekonsiliasi Kas</h2>
                        <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">
                            Nilai mengikuti data shift yang dikirim perangkat kasir.
                        </p>
                        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3">
                            <Metric label="Kas awal" value={formatMoney(shift.opening_cash)} />
                            <Metric label="Kas masuk" value={formatMoney(shift.cash_in)} />
                            <Metric label="Kas keluar" value={formatMoney(shift.cash_out)} />
                            <Metric label="Refund tunai" value={formatMoney(shift.cash_refund)} tone="red" />
                            <Metric label="Kas diharapkan" value={formatMoney(shift.expected_cash)} />
                            <Metric label="Kas aktual" value={shift.actual_cash === null ? '—' : formatMoney(shift.actual_cash)} />
                            <Metric
                                label="Variance"
                                value={shift.variance === null ? '—' : formatMoney(shift.variance)}
                                tone={Number(shift.variance) < 0 ? 'red' : Number(shift.variance) > 0 ? 'green' : undefined}
                            />
                            <Metric label="Pending sync" value={formatNumber(shift.pending_sync_count)} tone="amber" />
                            <Metric label="Transaksi lokal" value={formatNumber(shift.local_transaction_count)} />
                        </div>

                        {shift.opening_notes ? (
                            <div className="mt-4 rounded-xl bg-lightPrimary px-4 py-3 text-sm dark:bg-white/5">
                                <p className="text-xs font-bold uppercase tracking-wide text-gray-500">Catatan buka</p>
                                <p className="mt-1 text-navy-700 dark:text-white">{shift.opening_notes}</p>
                            </div>
                        ) : null}
                        {shift.closing_notes ? (
                            <div className="mt-3 rounded-xl bg-lightPrimary px-4 py-3 text-sm dark:bg-white/5">
                                <p className="text-xs font-bold uppercase tracking-wide text-gray-500">Catatan tutup</p>
                                <p className="mt-1 text-navy-700 dark:text-white">{shift.closing_notes}</p>
                            </div>
                        ) : null}
                        {shift.approved_by ? (
                            <p className="mt-3 text-xs text-gray-500 dark:text-gray-400">
                                Disetujui oleh {shift.approved_by.name} · {formatDateTime(shift.approved_at)}
                            </p>
                        ) : null}
                    </Card>

                    <Card className="overflow-hidden">
                        <div className="flex items-center gap-2 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                            <MdPointOfSale className="h-5 w-5 text-brand-500" />
                            <div>
                                <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Transaksi Shift</h2>
                                <p className="text-xs text-gray-600 dark:text-gray-400">Maksimal 100 transaksi terbaru.</p>
                            </div>
                        </div>
                        {shift.sales?.length === 0 ? (
                            <EmptyState compact title="Belum ada transaksi" description="Transaksi pada shift ini belum tersedia." />
                        ) : (
                            <div className="overflow-x-auto">
                                <table className="horizon-table">
                                    <thead>
                                        <tr>
                                            <th>Nomor struk</th>
                                            <th>Waktu</th>
                                            <th className="text-right">Total</th>
                                            <th>Pembayaran</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        {(shift.sales || []).map((sale) => (
                                            <tr key={sale.id}>
                                                <td>
                                                    <Link href={`/sales/${sale.id}`} className="font-bold text-brand-500 hover:text-brand-600">
                                                        {sale.receipt_number}
                                                    </Link>
                                                </td>
                                                <td className="whitespace-nowrap text-xs text-gray-600 dark:text-gray-400">
                                                    {formatDateTime(sale.transacted_at)}
                                                </td>
                                                <td className="whitespace-nowrap text-right font-bold">{formatMoney(sale.total)}</td>
                                                <td>
                                                    <Badge tone={statusTone(sale.payment_status)}>
                                                        {paymentStatusLabels[sale.payment_status] || sale.payment_status}
                                                    </Badge>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        )}
                    </Card>
                </div>

                <div className="space-y-5">
                    <Card className="p-5">
                        <div className="flex items-center gap-2">
                            <MdOutlineSchedule className="h-5 w-5 text-brand-500" />
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Informasi Shift</h2>
                        </div>
                        <dl className="mt-4 space-y-3 text-sm">
                            <Info label="Kasir" value={shift.cashier?.name} />
                            <Info label="Email kasir" value={shift.cashier?.email} />
                            <Info label="Outlet" value={shift.outlet ? `${shift.outlet.name} (${shift.outlet.code})` : null} />
                            <Info
                                label="Perangkat"
                                value={shift.device ? `${shift.device.name} (${shift.device.terminal_code})` : null}
                            />
                            <Info label="Dibuka" value={formatDateTime(shift.opened_at)} />
                            <Info label="Ditutup" value={shift.closed_at ? formatDateTime(shift.closed_at) : null} />
                            <Info label="UUID" value={<span className="break-all text-xs">{shift.uuid}</span>} />
                        </dl>
                    </Card>

                    <Card className="overflow-hidden">
                        <div className="border-b border-gray-100 px-5 py-4 dark:border-white/10">
                            <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">Mutasi Kas</h2>
                            <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">Kas masuk dan keluar selama shift.</p>
                        </div>
                        {shift.cash_movements?.length === 0 ? (
                            <EmptyState compact title="Tidak ada mutasi kas" description="Belum ada kas masuk atau keluar pada shift ini." />
                        ) : (
                            <ul className="divide-y divide-gray-100 dark:divide-white/5">
                                {(shift.cash_movements || []).map((movement) => (
                                    <li key={movement.id} className="flex items-start justify-between gap-3 px-5 py-3">
                                        <div>
                                            <p className="text-sm font-medium text-navy-700 dark:text-white">
                                                {movement.type === 'cash_in' ? 'Kas masuk' : movement.type === 'cash_out' ? 'Kas keluar' : movement.type}
                                            </p>
                                            <p className="text-xs text-gray-500 dark:text-gray-400">
                                                {movement.created_by?.name || '—'} · {formatDateTime(movement.occurred_at)}
                                            </p>
                                            {movement.reason ? (
                                                <p className="mt-0.5 text-xs text-gray-500 dark:text-gray-400">{movement.reason}</p>
                                            ) : null}
                                        </div>
                                        <p
                                            className={`shrink-0 text-sm font-bold ${
                                                movement.type === 'cash_out' ? 'text-red-500' : 'text-green-600 dark:text-green-400'
                                            }`}
                                        >
                                            {formatMoney(movement.amount)}
                                        </p>
                                    </li>
                                ))}
                            </ul>
                        )}
                    </Card>
                </div>
            </div>
        </>
    );
}

function Metric({ label, value, strong = false, tone }) {
    const tones = {
        amber: 'text-amber-600 dark:text-amber-400',
        red: 'text-red-500 dark:text-red-400',
        green: 'text-green-600 dark:text-green-400',
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

ShiftShow.layout = (page) => <AdminLayout>{page}</AdminLayout>;
