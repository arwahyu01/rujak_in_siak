export default function PageHeader({ eyebrow, title, description, children }) {
    return (
        <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
                {eyebrow ? (
                    <p className="mb-1 text-xs font-bold uppercase tracking-[0.2em] text-brand-500 dark:text-brand-300">
                        {eyebrow}
                    </p>
                ) : null}
                <h1 className="font-poppins text-2xl font-bold text-navy-700 dark:text-white md:text-[32px]">
                    {title}
                </h1>
                {description ? (
                    <p className="mt-2 max-w-3xl text-sm leading-6 text-gray-600 dark:text-gray-400">{description}</p>
                ) : null}
            </div>
            {children ? <div className="flex flex-wrap items-center gap-3">{children}</div> : null}
        </div>
    );
}
