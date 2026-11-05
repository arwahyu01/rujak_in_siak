import { usePage } from '@inertiajs/react';

export default function Footer() {
    const { app } = usePage().props;

    return (
        <footer className="flex flex-col items-center justify-between gap-2 px-2 pb-6 pt-6 text-center sm:flex-row sm:text-left">
            <p className="text-xs text-gray-500 dark:text-gray-400">
                © {new Date().getFullYear()} {app?.name || 'RUJAK.IN.SIAK POS'}. Seluruh hak dilindungi.
            </p>
            <p className="text-xs text-gray-500 dark:text-gray-400">
                UI berbasis{' '}
                <a
                    href="https://github.com/horizon-ui/horizon-tailwind-react"
                    target="_blank"
                    rel="noreferrer"
                    className="font-semibold text-brand-500 hover:text-brand-600 dark:text-brand-300"
                >
                    Horizon UI
                </a>{' '}
                • Lisensi MIT dipertahankan.
            </p>
        </footer>
    );
}
