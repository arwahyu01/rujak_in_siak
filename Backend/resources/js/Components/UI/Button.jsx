const variants = {
    primary:
        'bg-brand-500 text-white shadow-lg shadow-brand-500/30 hover:bg-brand-600 active:bg-brand-700 disabled:bg-brand-300',
    secondary:
        'border border-gray-200 bg-white text-navy-700 hover:bg-gray-50 dark:border-white/10 dark:bg-navy-800 dark:text-white dark:hover:bg-white/5',
    danger: 'bg-red-500 text-white hover:bg-red-600 active:bg-red-700 disabled:bg-red-300',
    success: 'bg-green-500 text-white hover:bg-green-600 active:bg-green-700 disabled:bg-green-300',
    ghost: 'text-navy-700 hover:bg-lightPrimary dark:text-white dark:hover:bg-white/5',
};

const sizes = {
    sm: 'h-9 px-3 text-xs',
    md: 'h-11 px-5 text-sm',
    lg: 'h-12 px-6 text-sm',
};

export default function Button({
    children,
    variant = 'primary',
    size = 'md',
    className = '',
    type = 'button',
    disabled,
    ...props
}) {
    return (
        <button
            type={type}
            disabled={disabled}
            className={`inline-flex items-center justify-center gap-2 rounded-xl font-bold transition disabled:cursor-not-allowed ${variants[variant]} ${sizes[size]} ${className}`}
            {...props}
        >
            {children}
        </button>
    );
}
