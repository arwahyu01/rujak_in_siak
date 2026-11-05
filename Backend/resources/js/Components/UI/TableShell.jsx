import Card from '@/Components/Horizon/Card';

export default function TableShell({ title, description, actions, children, footer }) {
    return (
        <Card className="overflow-hidden">
            {title || actions ? (
                <div className="flex flex-col gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/10 sm:flex-row sm:items-center sm:justify-between">
                    <div>
                        {title ? <h2 className="font-poppins text-base font-bold text-navy-700 dark:text-white">{title}</h2> : null}
                        {description ? <p className="mt-0.5 text-xs text-gray-600 dark:text-gray-400">{description}</p> : null}
                    </div>
                    {actions ? <div className="flex flex-wrap items-center gap-2">{actions}</div> : null}
                </div>
            ) : null}
            <div className="overflow-x-auto">{children}</div>
            {footer}
        </Card>
    );
}
