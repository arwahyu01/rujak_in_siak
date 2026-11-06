<?php

namespace App\Http\Controllers\Api\V1;

use App\Exceptions\ApiException;
use App\Http\Controllers\Controller;
use App\Services\ReportService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ReportController extends Controller
{
    public function sales(Request $request, ReportService $reports): JsonResponse
    {
        return $this->report($request, fn (int $businessId, Carbon $from, Carbon $to, ?int $outletId) => $reports->sales($businessId, $from, $to, $outletId));
    }

    public function payments(Request $request, ReportService $reports): JsonResponse
    {
        return $this->report($request, fn (int $businessId, Carbon $from, Carbon $to, ?int $outletId) => $reports->payments($businessId, $from, $to, $outletId));
    }

    public function products(Request $request, ReportService $reports): JsonResponse
    {
        return $this->report($request, fn (int $businessId, Carbon $from, Carbon $to, ?int $outletId) => $reports->products($businessId, $from, $to, $outletId));
    }

    public function shifts(Request $request, ReportService $reports): JsonResponse
    {
        return $this->report($request, fn (int $businessId, Carbon $from, Carbon $to, ?int $outletId) => $reports->shifts($businessId, $from, $to, $outletId));
    }

    private function report(Request $request, callable $resolver): JsonResponse
    {
        $user = $request->user();
        $business = $user->business;
        $timezone = $business->timezone ?: config('app.timezone');

        $from = $this->date($request->query('date_from'), $timezone)->startOfDay();
        $to = $this->date($request->query('date_to'), $timezone)->endOfDay();

        if ($from->greaterThan($to)) {
            throw new ApiException('REPORT_PERIOD_INVALID', 'Tanggal awal tidak boleh melewati tanggal akhir.', 422);
        }

        if ($from->diffInYears($to) > 5) {
            throw new ApiException('REPORT_PERIOD_TOO_LONG', 'Rentang laporan maksimal 5 tahun.', 422);
        }

        $outletId = $request->filled('outlet_uuid')
            ? $this->outletId($request, (string) $request->query('outlet_uuid'))
            : (int) $user->outlet_id;
        $outletId = $outletId > 0 ? $outletId : null;

        return ApiResponse::data(
            $resolver((int) $user->business_id, $from, $to, $outletId),
            meta: [
                'period' => [
                    'from' => $from->toDateString(),
                    'to' => $to->toDateString(),
                    'timezone' => $timezone,
                ],
                'server_time' => now()->toIso8601String(),
            ],
        );
    }

    private function outletId(Request $request, string $uuid): int
    {
        $outlet = $request->user()->business
            ->outlets()
            ->where('uuid', $uuid)
            ->where('is_active', true)
            ->first();

        if (! $outlet) {
            throw ApiException::notFound('Outlet tidak ditemukan pada bisnis ini.');
        }

        if ($request->user()->outlet_id && (int) $request->user()->outlet_id !== (int) $outlet->id) {
            throw ApiException::forbidden('Anda tidak memiliki akses ke outlet tersebut.');
        }

        return (int) $outlet->id;
    }

    private function date(mixed $value, string $timezone): Carbon
    {
        if (! is_string($value) || trim($value) === '') {
            return now($timezone);
        }

        try {
            return Carbon::parse($value, $timezone);
        } catch (\Throwable) {
            throw new ApiException('REPORT_DATE_INVALID', 'Format tanggal laporan tidak valid.', 422);
        }
    }
}
