import { Link } from '@inertiajs/react';

function labelText(label) {
    return (label || '')
        .replace(/&laquo;/g, '«')
        .replace(/&raquo;/g, '»')
        .replace(/&amp;/g, '&')
        .replace(/<[^>]*>/g, '');
}

export default function Pagination({ paginator }) {
    if (!paginator || paginator.last_page <= 1) return null;

    return (
        <div className="flex flex-col items-center justify-between gap-3 border-t border-gray-100 px-4 py-4 dark:border-white/10 sm:flex-row">
            <p className="text-xs text-gray-600 dark:text-gray-400">
                Menampilkan <span className="font-bold text-navy-700 dark:text-white">{paginator.from || 0}</span>–
                <span className="font-bold text-navy-700 dark:text-white">{paginator.to || 0}</span> dari{' '}
                <span className="font-bold text-navy-700 dark:text-white">{paginator.total}</span> data
            </p>
            <div className="flex flex-wrap items-center gap-1">
                {paginator.links.map((link, index) => {
                    const label = labelText(link.label);
                    if (!link.url) {
                        return (
                            <span
                                key={index}
                                className="flex h-8 min-w-8 items-center justify-center rounded-lg px-2 text-xs font-medium text-gray-400"
                            >
                                {label}
                            </span>
                        );
                    }
                    return (
                        <Link
                            key={index}
                            href={link.url}
                            preserveScroll
                            className={`flex h-8 min-w-8 items-center justify-center rounded-lg px-2 text-xs font-bold transition ${
                                link.active
                                    ? 'bg-brand-500 text-white'
                                    : 'bg-lightPrimary text-navy-700 hover:bg-brand-50 dark:bg-white/5 dark:text-white dark:hover:bg-white/10'
                            }`}
                        >
                            {label}
                        </Link>
                    );
                })}
            </div>
        </div>
    );
}
