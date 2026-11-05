import Chart from 'react-apexcharts';
import { formatCompact } from '@/lib/format';

export default function BarChart({ series, categories, height = 300, horizontal = false, formatter = formatCompact }) {
    const options = {
        chart: {
            type: 'bar',
            toolbar: { show: false },
            fontFamily: 'DM Sans, sans-serif',
        },
        colors: ['#422AFB', '#17C1E8'],
        plotOptions: {
            bar: {
                horizontal,
                borderRadius: 6,
                columnWidth: '42%',
                barHeight: '60%',
            },
        },
        dataLabels: { enabled: false },
        grid: { borderColor: '#edf2f7', strokeDashArray: 4 },
        xaxis: {
            categories,
            labels: { style: { colors: '#a3aed0', fontSize: '12px' } },
            axisBorder: { show: false },
            axisTicks: { show: false },
        },
        yaxis: {
            labels: {
                style: { colors: '#a3aed0', fontSize: '12px' },
                formatter: horizontal ? (value) => value : formatter,
            },
        },
        tooltip: { y: { formatter } },
    };

    return <Chart options={options} series={series} type="bar" height={height} width="100%" />;
}
