import Chart from 'react-apexcharts';
import { formatMoney } from '@/lib/format';

export default function PieChart({ series, labels, height = 300, totalLabel = 'Total' }) {
    const options = {
        chart: { type: 'donut', fontFamily: 'DM Sans, sans-serif' },
        labels,
        colors: ['#422AFB', '#17C1E8', '#05CD99', '#FFB547', '#EE5D50'],
        dataLabels: { enabled: false },
        stroke: { width: 2, colors: ['#ffffff'] },
        legend: {
            position: 'bottom',
            fontSize: '12px',
            fontWeight: 500,
            labels: { colors: '#a3aed0' },
            markers: { size: 5 },
        },
        plotOptions: {
            pie: {
                donut: {
                    size: '68%',
                    labels: {
                        show: true,
                        name: { fontSize: '12px', color: '#a3aed0' },
                        value: {
                            fontSize: '18px',
                            fontWeight: 700,
                            color: '#1B254B',
                            formatter: (value) => formatMoney(value),
                        },
                        total: {
                            show: true,
                            label: totalLabel,
                            color: '#a3aed0',
                            formatter: (items) => formatMoney(items.globals.seriesTotals.reduce((sum, value) => sum + value, 0)),
                        },
                    },
                },
            },
        },
        tooltip: { y: { formatter: formatMoney } },
    };

    return <Chart options={options} series={series} type="donut" height={height} width="100%" />;
}
