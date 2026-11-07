<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Inertia\Inertia;
use Inertia\Response;

class BusinessSettingsController extends Controller
{
    public function edit(Request $request): Response
    {
        $this->ensureOwner($request);

        $business = $request->user()->business;

        return Inertia::render('Settings/Business', [
            'business' => [
                'name' => $business->name,
                'currency' => $business->currency,
                'timezone' => $business->timezone,
            ],
            'settings' => [
                'non_cash_proof_required' => (bool) $business->non_cash_proof_required,
            ],
        ]);
    }

    public function update(Request $request): RedirectResponse
    {
        $this->ensureOwner($request);

        $validated = $request->validate([
            'non_cash_proof_required' => ['required', 'boolean'],
        ]);

        $request->user()->business->update([
            'non_cash_proof_required' => (bool) $validated['non_cash_proof_required'],
        ]);

        return back()->with('success', 'Pengaturan pembayaran berhasil disimpan.');
    }

    private function ensureOwner(Request $request): void
    {
        abort_unless($request->user()->isOwner(), 403);
    }
}
