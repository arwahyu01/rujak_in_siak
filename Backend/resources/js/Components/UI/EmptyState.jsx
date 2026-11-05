import { HiOutlineInbox } from 'react-icons/hi';

export default function EmptyState({
    icon,
    title = 'Belum ada data',
    description = 'Data akan tampil di sini setelah tersedia dari aplikasi POS.',
    action,
    compact = false,
}) {
    return (
        <div className={`flex flex-col items-center justify-center text-center ${compact ? 'px-4 py-10' : 'px-6 py-16'}`}>
            <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-lightPrimary text-2xl text-brand-500 dark:bg-white/5 dark:text-brand-300">
                {icon || <HiOutlineInbox />}
            </div>
            <h3 className="font-poppins text-base font-bold text-navy-700 dark:text-white">{title}</h3>
            <p className="mt-2 max-w-md text-sm text-gray-600 dark:text-gray-400">{description}</p>
            {action ? <div className="mt-5">{action}</div> : null}
        </div>
    );
}
