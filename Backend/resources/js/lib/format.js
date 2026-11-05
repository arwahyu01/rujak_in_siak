export const currency = new Intl.NumberFormat('id-ID', {
    style: 'currency',
    currency: 'IDR',
    maximumFractionDigits: 0,
});

export const number = new Intl.NumberFormat('id-ID');

export function formatMoney(value) {
    return currency.format(Number(value || 0));
}

export function formatNumber(value) {
    return number.format(Number(value || 0));
}

export function formatCompact(value) {
    const amount = Number(value || 0);
    if (Math.abs(amount) >= 1_000_000_000) return `${(amount / 1_000_000_000).toFixed(1).replace('.', ',')} M`;
    if (Math.abs(amount) >= 1_000_000) return `${(amount / 1_000_000).toFixed(1).replace('.', ',')} jt`;
    if (Math.abs(amount) >= 1_000) return `${Math.round(amount / 1_000)} rb`;
    return String(amount);
}

export function formatDate(value, withTime = false) {
    if (!value) return '—';
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) return '—';
    return new Intl.DateTimeFormat('id-ID', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        ...(withTime ? { hour: '2-digit', minute: '2-digit' } : {}),
    }).format(date);
}

export function formatDateTime(value) {
    return formatDate(value, true);
}

export function formatRelative(value) {
    if (!value) return 'Belum pernah';
    const date = new Date(value);
    const diff = Date.now() - date.getTime();
    const minutes = Math.floor(diff / 60000);
    if (minutes < 1) return 'Baru saja';
    if (minutes < 60) return `${minutes} menit lalu`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24) return `${hours} jam lalu`;
    const days = Math.floor(hours / 24);
    if (days < 30) return `${days} hari lalu`;
    return formatDate(value);
}

export function initials(name) {
    return (name || '?')
        .split(' ')
        .filter(Boolean)
        .slice(0, 2)
        .map((part) => part[0])
        .join('')
        .toUpperCase();
}

export function truncate(value, length = 40) {
    if (!value) return '—';
    return value.length > length ? `${value.slice(0, length)}…` : value;
}

export const orderTypeLabels = {
    dine_in: 'Dine In',
    take_away: 'Take Away',
    delivery: 'Delivery',
};

export const paymentMethodLabels = {
    cash: 'Tunai',
    qris: 'QRIS',
    transfer: 'Transfer Bank',
    ewallet: 'E-Wallet',
};

export const paymentStatusLabels = {
    unpaid: 'Belum Dibayar',
    partially_paid: 'Dibayar Sebagian',
    awaiting_verification: 'Menunggu Verifikasi',
    paid: 'Lunas',
    partially_refunded: 'Refund Sebagian',
    refunded: 'Direfund',
    cancelled: 'Dibatalkan',
};

export const lifecycleLabels = {
    finalized: 'Final',
    voided: 'Void',
};

export const paymentEntryStatusLabels = {
    recorded: 'Tercatat',
    awaiting_verification: 'Menunggu Verifikasi',
    confirmed: 'Terkonfirmasi',
    rejected: 'Ditolak',
    cancelled: 'Dibatalkan',
    refunded: 'Direfund',
};

export const shiftStatusLabels = {
    open: 'Buka',
    closed_pending_sync: 'Tutup — Menunggu Sinkronisasi',
    closed_confirmed: 'Tutup — Terkonfirmasi',
    closed_sync_exception: 'Tutup — Sync Exception',
};

export const syncStatusLabels = {
    pending: 'Pending',
    accepted: 'Accepted',
    duplicate: 'Duplicate',
    rejected: 'Rejected',
    conflict: 'Conflict',
    blocked_dependency: 'Blocked Dependency',
    upgrade_required: 'Upgrade Required',
};

export function statusTone(status) {
    return {
        paid: 'success',
        confirmed: 'success',
        closed_confirmed: 'success',
        accepted: 'success',
        finalized: 'success',
        partially_paid: 'warning',
        awaiting_verification: 'warning',
        pending: 'warning',
        closed_pending_sync: 'warning',
        blocked_dependency: 'warning',
        upgrade_required: 'warning',
        duplicate: 'info',
        open: 'brand',
        rejected: 'danger',
        cancelled: 'danger',
        voided: 'danger',
        refunded: 'info',
        partially_refunded: 'info',
        closed_sync_exception: 'danger',
        conflict: 'danger',
        unpaid: 'neutral',
    }[status] || 'neutral';
}
