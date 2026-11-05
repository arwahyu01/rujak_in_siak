import { HiChevronDown } from 'react-icons/hi';

export default function SelectField({
    label,
    id,
    error,
    hint,
    className = '',
    required,
    children,
    ...props
}) {
    return (
        <div className={className}>
            {label ? (
                <label htmlFor={id} className="horizon-label">
                    {label}
                    {required ? <span className="ml-1 text-red-500">*</span> : null}
                </label>
            ) : null}
            <div className="relative">
                <select
                    id={id}
                    className={`horizon-select ${error ? 'border-red-500 focus:border-red-500' : ''}`}
                    {...props}
                >
                    {children}
                </select>
                <HiChevronDown className="pointer-events-none absolute right-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-500" />
            </div>
            {error ? <p className="mt-1.5 text-xs font-medium text-red-500">{error}</p> : null}
            {!error && hint ? <p className="mt-1.5 text-xs text-gray-500 dark:text-gray-400">{hint}</p> : null}
        </div>
    );
}
