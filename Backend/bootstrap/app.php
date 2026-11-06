<?php

use App\Exceptions\ApiException;
use App\Http\Middleware\EnsureApiUserIsActive;
use App\Http\Middleware\EnsureUserHasPermission;
use App\Http\Middleware\EnsureUserIsActive;
use App\Http\Middleware\HandleInertiaRequests;
use App\Http\Middleware\ResolveApiDevice;
use App\Support\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Exceptions\ThrottleRequestsException;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Inertia\Inertia;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->web(append: [
            HandleInertiaRequests::class,
            EnsureUserIsActive::class,
        ]);

        $middleware->alias([
            'permission' => EnsureUserHasPermission::class,
            'api.active' => EnsureApiUserIsActive::class,
            'device.context' => ResolveApiDevice::class,
        ]);
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->render(function (Throwable $exception, Request $request) {
            if (! $request->is('api/*')) {
                return null;
            }

            if ($exception instanceof ApiException) {
                return ApiResponse::error(
                    $exception->errorCode,
                    $exception->getMessage(),
                    $exception->status,
                    $exception->details,
                    $exception->retryable,
                );
            }

            if ($exception instanceof ValidationException) {
                return ApiResponse::error(
                    'VALIDATION_FAILED',
                    'Data yang dikirim tidak valid.',
                    422,
                    ['errors' => $exception->errors()],
                );
            }

            if ($exception instanceof AuthenticationException) {
                return ApiResponse::error('UNAUTHENTICATED', 'Token autentikasi tidak valid atau sudah berakhir.', 401);
            }

            if ($exception instanceof AuthorizationException) {
                return ApiResponse::error(
                    'FORBIDDEN',
                    $exception->getMessage() ?: 'Anda tidak memiliki hak untuk tindakan ini.',
                    403,
                );
            }

            if ($exception instanceof ModelNotFoundException) {
                return ApiResponse::error('NOT_FOUND', 'Data tidak ditemukan.', 404);
            }

            if ($exception instanceof ThrottleRequestsException) {
                return ApiResponse::error(
                    'RATE_LIMITED',
                    'Terlalu banyak permintaan. Coba lagi nanti.',
                    429,
                    [],
                    true,
                )->withHeaders($exception->getHeaders());
            }

            if ($exception instanceof HttpExceptionInterface) {
                $status = $exception->getStatusCode();

                return ApiResponse::error(
                    match ($status) {
                        403 => 'FORBIDDEN',
                        404 => 'NOT_FOUND',
                        405 => 'METHOD_NOT_ALLOWED',
                        429 => 'RATE_LIMITED',
                        default => 'HTTP_ERROR',
                    },
                    $status >= 500 ? 'Terjadi kesalahan pada server.' : ($exception->getMessage() ?: 'Permintaan tidak dapat diproses.'),
                    $status,
                    [],
                    $status >= 500 || $status === 429,
                )->withHeaders($exception->getHeaders());
            }

            return ApiResponse::error(
                'SERVER_ERROR',
                'Terjadi kesalahan pada server.',
                500,
                [],
                true,
            );
        });

        $exceptions->respond(function (Response $response, Throwable $exception, Request $request) {
            $status = $response->getStatusCode();

            if ($request->is('api/*') || $request->expectsJson() || $request->is('up')) {
                return $response;
            }

            if ($status === 500 && config('app.debug')) {
                return $response;
            }

            if (in_array($status, [403, 404, 419, 429, 500, 503], true)) {
                return Inertia::render('Error', ['status' => $status])
                    ->toResponse($request)
                    ->setStatusCode($status);
            }

            return $response;
        });
    })->create();
