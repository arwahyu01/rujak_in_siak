import Chart from 'react-apexcharts';
import { formatCompact } from '@/lib/format';

const axis = {
    labels: { style: { colors: '#a3aed0', fontSize: '12px', fontFamily: 'DM Sans' } },
    axisBorder: { show: false },
    axisTicks: { show: false },
};

export default function AreaChart({ series, categories, height = 300, formatter = formatCompact }) {
    const options = {
        chart: {
            type: 'area',
            toolbar: { show: false },
            fontFamily: 'DM Sans, sans-serif',
            zoom: { enabled: false },
        },
        colors: ['#422AFB'],
        dataLabels: { enabled: false },
        stroke: { curve: 'smooth', width: 3 },
        fill: {
            type: 'gradient',
            gradient: { shadeIntensity: 1, opacityFrom: 0.35, opacityTo: 0.02, stops: [0, 90, 100] },
        },
        grid: { borderColor: '#edf2f7', strokeDashArray: 4, padding: { left: 8, right: 8 } },
        xaxis: { ...axis, categories },
        yaxis: { labels: { ...axis.labels, formatter } },
        tooltip: { y: { formatter } },
        markers: { size: 0, hover: { size: 5 } },
    };

    return <Chart options={options} series={series} type="area" height={height} width="100%" />;
}
