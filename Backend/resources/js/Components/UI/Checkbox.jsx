export default function Checkbox({ label, id, className = '', ...props }) {
    return (
        <label htmlFor={id} className={`flex cursor-pointer items-center gap-2 text-sm font-medium text-navy-700 dark:text-white ${className}`}>
            <input
                id={id}
                type="checkbox"
                className="h-4 w-4 rounded border-gray-300 text-brand-500 accent-brand-500 focus:ring-brand-500 dark:border-white/20 dark:bg-navy-800"
                {...props}
            />
            <span>{label}</span>
        </label>
    );
}
