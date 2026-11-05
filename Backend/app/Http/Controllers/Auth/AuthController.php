<?php

namespace App\Http\Controllers\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Services\AuditLogger;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;
use Inertia\Response;

class AuthController extends Controller
{
    public function create(): Response|RedirectResponse
    {
        if (Auth::check()) {
            return redirect()->route('dashboard');
        }

        return Inertia::render('Auth/Login', [
            'status' => session('status'),
        ]);
    }

    public function store(LoginRequest $request, AuditLogger $audit): RedirectResponse
    {
        $identifier = trim((string) $request->input('email'));
        $field = filter_var($identifier, FILTER_VALIDATE_EMAIL) ? 'email' : 'username';

        if (! Auth::attempt([$field => $identifier, 'password' => $request->input('password'), 'is_active' => true], $request->boolean('remember'))) {
            return back()->withErrors([
                'email' => 'Kredensial tidak sesuai atau akun tidak aktif.',
            ])->onlyInput('email');
        }

        $request->session()->regenerate();
        $user = $request->user();

        if (! $user->hasPermission('admin.access')) {
            $audit->record('auth.web_access_denied', 'auth', 'Percobaan akses web tanpa permission', $user, actor: $user, businessId: $user->business_id);
            Auth::logout();
            $request->session()->invalidate();
            $request->session()->regenerateToken();

            return redirect()->route('login')->with('error', 'Akun kasir hanya dapat menggunakan aplikasi POS Android. Hubungi Owner untuk akses web.');
        }

        $user->forceFill(['last_login_at' => now()])->save();
        $audit->record('auth.login', 'auth', 'Login web back-office', $user, actor: $user, businessId: $user->business_id);

        return redirect()->intended(route('dashboard'));
    }

    public function destroy(Request $request, AuditLogger $audit): RedirectResponse
    {
        $user = $request->user();
        if ($user) {
            $audit->record('auth.logout', 'auth', 'Logout web back-office', $user, actor: $user, businessId: $user->business_id);
        }

        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();

        return redirect()->route('login');
    }
}
