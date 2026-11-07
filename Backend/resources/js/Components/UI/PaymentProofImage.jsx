import { useState } from 'react';

export default function PaymentProofImage({ paymentId, className = 'h-20 w-20' }) {
    const [failed, setFailed] = useState(false);
    const proofUrl = `/payments/${paymentId}/proof`;

    return (
        <div className="mt-2">
            <p className="mb-1 text-[11px] font-bold uppercase tracking-wide text-gray-500 dark:text-gray-400">
                Bukti pembayaran
            </p>
            {failed ? (
                <a
                    href={proofUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-xs font-bold text-brand-500 hover:text-brand-600"
                >
                    Bukti tidak dapat dimuat. Buka di tab baru.
                </a>
            ) : (
                <a href={proofUrl} target="_blank" rel="noreferrer" title="Buka bukti ukuran penuh" className="inline-block">
                    <img
                        src={proofUrl}
                        alt="Bukti pembayaran"
                        onError={() => setFailed(true)}
                        className={`${className} rounded-xl border border-gray-200 bg-white object-cover shadow-sm dark:border-white/10 dark:bg-navy-700`}
                    />
                </a>
            )}
        </div>
    );
}
