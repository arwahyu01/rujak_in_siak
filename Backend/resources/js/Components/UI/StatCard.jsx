import Card from '@/Components/Horizon/Card';

const toneClasses = {
    brand: 'bg-brand-50 text-brand-500 dark:bg-brand-500/10 dark:text-brand-300',
    green: 'bg-green-50 text-green-600 dark:bg-green-500/10 dark:text-green-400',
    amber: 'bg-amber-50 text-amber-600 dark:bg-amber-500/10 dark:text-amber-400',
    red: 'bg-red-50 text-red-500 dark:bg-red-500/10 dark:text-red-400',
    cyan: 'bg-cyan-50 text-cyan-600 dark:bg-cyan-500/10 dark:text-cyan-400',
    navy: 'bg-lightPrimary text-navy-700 dark:bg-white/5 dark:text-white',
};

export default function StatCard({ icon, label, value, detail, tone = 'brand' }) {
    return (
        <Card className="!flex-row items-center p-4">
            <div className={`flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl ${toneClasses[tone] || toneClasses.brand}`}>
                {icon}
            </div>
            <div className="ml-4 min-w-0">
                <p className="truncate font-dm text-xs font-medium text-gray-600 dark:text-gray-400">{label}</p>
                <h4 className="mt-0.5 truncate font-poppins text-xl font-bold text-navy-700 dark:text-white" title={value}>
                    {value}
                </h4>
                {detail ? <p className="mt-0.5 truncate text-xs text-gray-500 dark:text-gray-400">{detail}</p> : null}
            </div>
        </Card>
    );
}
