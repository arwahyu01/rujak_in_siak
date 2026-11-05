<?php

namespace App\Http\Controllers;

use App\Services\DashboardService;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Inertia\Inertia;
use Inertia\Response;

class DashboardController extends Controller
{
    public function __invoke(Request $request, DashboardService $dashboard): Response
    {
        $period = (string) $request->query('period', '30');
        $allowed = ['7', '30', '90', 'month'];
        if (! in_array($period, $allowed, true)) {
            $period = '30';
        }

        $to = now()->endOfDay();
        $from = $period === 'month'
            ? now()->startOfMonth()
            : Carbon::today()->subDays(((int) $period) - 1)->startOfDay();

        $summary = $dashboard->summary(
            $request->user()->business_id,
            $from,
            $to,
            $request->user()->outlet_id,
        );

        return Inertia::render('Dashboard', [
            ...$summary,
            'filters' => [
                'period' => $period,
            ],
        ]);
    }
}
