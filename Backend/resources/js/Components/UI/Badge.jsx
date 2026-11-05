const tones = {
    success: 'bg-green-50 text-green-700 dark:bg-green-500/10 dark:text-green-400',
    warning: 'bg-amber-50 text-amber-700 dark:bg-amber-500/10 dark:text-amber-400',
    danger: 'bg-red-50 text-red-700 dark:bg-red-500/10 dark:text-red-400',
    info: 'bg-cyan-50 text-cyan-700 dark:bg-cyan-500/10 dark:text-cyan-400',
    brand: 'bg-brand-50 text-brand-600 dark:bg-brand-500/10 dark:text-brand-300',
    neutral: 'bg-lightPrimary text-gray-600 dark:bg-white/5 dark:text-gray-300',
};

export default function Badge({ children, tone = 'neutral', className = '' }) {
    return (
        <span
            className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-bold ${tones[tone] || tones.neutral} ${className}`}
        >
            {children}
        </span>
    );
}
