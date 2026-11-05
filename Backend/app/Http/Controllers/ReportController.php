<?php

namespace App\Http\Controllers;

use App\Services\ReportService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Inertia\Inertia;
use Inertia\Response;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    public function index(Request $request, ReportService $reports): Response
    {
        $data = $this->validatedFilters($request);
        $tab = $data['tab'];
        $from = $data['from'];
        $to = $data['to'];
        $businessId = $request->user()->business_id;
        $outletId = $request->user()->outlet_id;

        $report = match ($tab) {
            'payments' => $reports->payments($businessId, $from, $to, $outletId),
            'products' => $reports->products($businessId, $from, $to, $outletId),
            'shifts' => $reports->shifts($businessId, $from, $to, $outletId),
            default => $reports->sales($businessId, $from, $to, $outletId),
        };

        return Inertia::render('Reports/Index', [
            'tab' => $tab,
            'report' => $report,
            'filters' => [
                'from' => $from->toDateString(),
                'to' => $to->toDateString(),
            ],
            'canExport' => $request->user()->hasPermission('reports.export'),
        ]);
    }

    public function export(Request $request, ReportService $reports): StreamedResponse
    {
        abort_unless($request->user()->hasPermission('reports.export'), 403);

        $data = $this->validatedFilters($request);
        $type = $data['tab'];
        $rows = $reports->exportRows($type, $request->user()->business_id, $data['from'], $data['to'], $request->user()->outlet_id);

        $filename = "laporan-{$type}-{$data['from']->toDateString()}-{$data['to']->toDateString()}.csv";

        return response()->streamDownload(function () use ($rows) {
            $handle = fopen('php://output', 'w');
            fwrite($handle, "\xEF\xBB\xBF");
            if (count($rows) > 0) {
                fputcsv($handle, array_keys($rows[0]));
                foreach ($rows as $row) {
                    fputcsv($handle, array_values($row));
                }
            } else {
                fputcsv($handle, ['Tidak ada data pada periode ini']);
            }
            fclose($handle);
        }, $filename, ['Content-Type' => 'text/csv; charset=UTF-8']);
    }

    private function validatedFilters(Request $request): array
    {
        $validated = $request->validate([
            'tab' => ['nullable', 'in:sales,payments,products,shifts'],
            'from' => ['nullable', 'date'],
            'to' => ['nullable', 'date'],
        ]);

        $from = ! empty($validated['from']) ? Carbon::parse($validated['from'])->startOfDay() : now()->startOfMonth();
        $to = ! empty($validated['to']) ? Carbon::parse($validated['to'])->endOfDay() : now()->endOfDay();

        if ($from->greaterThan($to)) {
            [$from, $to] = [$to->copy()->startOfDay(), $from->copy()->endOfDay()];
        }

        return [
            'tab' => $validated['tab'] ?? 'sales',
            'from' => $from,
            'to' => $to,
        ];
    }
}
