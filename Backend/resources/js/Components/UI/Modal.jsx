import { useEffect } from 'react';
import { HiX } from 'react-icons/hi';

const widths = {
    sm: 'max-w-md',
    md: 'max-w-2xl',
    lg: 'max-w-4xl',
    xl: 'max-w-6xl',
};

export default function Modal({ open, onClose, title, description, children, footer, size = 'md' }) {
    useEffect(() => {
        if (!open) return;
        const onKey = (event) => {
            if (event.key === 'Escape') onClose();
        };
        document.addEventListener('keydown', onKey);
        document.body.style.overflow = 'hidden';
        return () => {
            document.removeEventListener('keydown', onKey);
            document.body.style.overflow = '';
        };
    }, [open, onClose]);

    if (!open) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-start justify-center overflow-y-auto bg-navy-900/50 p-4 backdrop-blur-sm sm:items-center">
            <div
                className={`relative my-8 w-full ${widths[size]} rounded-[20px] bg-white shadow-2xl dark:bg-navy-800`}
                onClick={(event) => event.stopPropagation()}
            >
                <div className="flex items-start justify-between gap-4 border-b border-gray-100 px-6 py-5 dark:border-white/10">
                    <div>
                        <h3 className="font-poppins text-xl font-bold text-navy-700 dark:text-white">{title}</h3>
                        {description ? (
                            <p className="mt-1 text-sm text-gray-600 dark:text-gray-400">{description}</p>
                        ) : null}
                    </div>
                    <button
                        type="button"
                        onClick={onClose}
                        className="rounded-full p-2 text-gray-500 transition hover:bg-lightPrimary hover:text-navy-700 dark:hover:bg-white/10 dark:hover:text-white"
                        aria-label="Tutup"
                    >
                        <HiX className="h-5 w-5" />
                    </button>
                </div>
                <div className="max-h-[70vh] overflow-y-auto px-6 py-5">{children}</div>
                {footer ? (
                    <div className="flex flex-wrap items-center justify-end gap-3 border-t border-gray-100 px-6 py-4 dark:border-white/10">
                        {footer}
                    </div>
                ) : null}
            </div>
        </div>
    );
}
