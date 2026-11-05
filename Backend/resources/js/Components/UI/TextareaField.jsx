export default function TextareaField({
    label,
    id,
    error,
    hint,
    className = '',
    required,
    rows = 3,
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
            <textarea
                id={id}
                rows={rows}
                className={`horizon-textarea ${error ? 'border-red-500 focus:border-red-500' : ''}`}
                {...props}
            />
            {error ? <p className="mt-1.5 text-xs font-medium text-red-500">{error}</p> : null}
            {!error && hint ? <p className="mt-1.5 text-xs text-gray-500 dark:text-gray-400">{hint}</p> : null}
        </div>
    );
}
