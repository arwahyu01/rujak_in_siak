# Receipt paper efficiency — implementation log

Status: **P1 verified on hardware; P2 and P3 implemented, pending device check.**
Last updated: 2026-11-07.

This file is the resume point if the session is interrupted. Read this before
continuing work on receipt printing.

## Goal

Reduce thermal paper usage per receipt without removing any field required by
the PRD, and prevent duplicate printing that wastes a full receipt.

## Approved product decisions

- Receipt is an **order proof**, printed automatically at checkout.
- Cash / fully paid receipt label: `LUNAS · <receipt number>` when it fits on
  one line; otherwise label and receipt number on separate lines.
- Non-cash awaiting-verification receipt label:
  `MENUNGGU VERIFIKASI PEMBAYARAN`, then the receipt number on the next line.
- Void receipt label: `VOID · <receipt number>` when it fits.
- Reprints keep the `CETAK ULANG` marker.
- After the owner verifies a non-cash payment, do **not** print a second receipt
  automatically. A paid copy is printed on demand with `CETAK ULANG`.
- Auto-print modes (`all` / `cashOnly` / `manual`) and an optional transfer proof
  photo are **later phases**, not part of P1.

## P1 scope (implemented)

File: `lib/data/services/printer_service.dart`

1. **Cut feed**
   - 58/72 mm: 2 feed lines + raw cut (unchanged).
   - 80 mm: 4 feed lines + raw cut (previously `feed(1) + Generator.cut()`,
     which adds five blank lines = six total).
   - Uses the same raw cut command on all widths.
2. **Separators**
   - Only one full-width separator, after the item block.
   - Uses `Generator.hr()` so the line matches the configured paper width
     (32 / 42 / 48 characters).
3. **Blank lines**
   - Kept: one blank after the header, one blank before payments.
   - Removed: blank after order info, blank after payments.
4. **Footer**
   - `Simpan struk ini sebagai bukti pembayaran.` (42 chars, wraps on 58 mm)
     replaced by `Simpan struk sebagai bukti` (27 chars, one line).
5. **Status header**
   - Old `PAID RECEIPT` / `PAYMENT PENDING` labels replaced by the
     status-aware labels above.
   - Paid/void label and receipt number are combined when they fit the paper
     width.
6. **Item layout**
   - Replaced the fixed `8/12` name and `4/12` price columns with a compact
     full-width line: item name left, amount right.
   - Long names wrap at word boundaries; continuation lines use the full paper
     width.
   - On 58 mm this allows about 23 characters for the name on the first line
     (including `2x `), versus about 20 before, and removes the 10-character
     price-column limit.

Expected result for a typical 3-item cash sale on 58 mm: about 23 lines instead
of about 28 (roughly 18–20% shorter). Line height and cutter behavior were
confirmed on the physical printer.

## Changed files

- `lib/data/services/printer_service.dart` — `ReceiptLayout` helpers, compact
  receipt body, status-aware heading, single separator, shorter footer,
  width-aware cut feed, `AutoPrintMode`, `compact`, `markPrinted()`, write
  timeout.
- `lib/data/repositories/sale_repository.dart` — `_enqueuePrint` deduplicates
  per sale.
- `lib/features/receipt/presentation/receipt_screen.dart` — mode-aware
  auto-print, dynamic print labels, `CETAK ULANG` only after a successful
  print, all queue jobs for a sale updated together.
- `lib/features/settings/presentation/printer_settings_screen.dart` — auto-print
  mode dropdown and "Mode hemat kertas" switch.
- `lib/features/settings/presentation/print_queue_screen.dart` — reprint marker
  on retry, PRINT_TIMEOUT as unknown, "Sudah tercetak" action.
- `test/receipt_layout_test.dart` — 10 unit tests for headings, item fitting,
  and word wrapping.
- `test/printer_config_test.dart` — 11 unit tests for modes, legacy migration,
  compact, and JSON round-trip.
- `docs/receipt-paper-efficiency.md` — this log.

## Verification checklist

- [x] `flutter test test/receipt_layout_test.dart` — 10 tests passed.
- [x] `flutter test test/printer_config_test.dart` — 11 tests passed.
- [x] `flutter test` — full suite passed (39 tests).
- [x] `flutter analyze` — no issues found.
- [x] P1 physical print test on 58 mm (default) and 80 mm — confirmed by user.
- [x] 80 mm cutter does not clip the footer at 4 feed lines — confirmed by user.
- [x] P1 item lines are acceptable — confirmed by user.
- [ ] P2 device check: mode dropdown, compact receipt, button labels.
- [ ] P3 device check: no duplicate print on replay, retry prints `CETAK ULANG`,
      "Sudah tercetak" resolves an `unknown` job.

## P2 — printer configuration (implemented)

- [x] `PrinterConfig.autoPrintMode`: `all` (default) / `cashOnly` / `manual`.
- [x] Migrate legacy `enabled` JSON: `false` → `manual`, otherwise `all`.
- [x] `PrinterConfig.compact`: hide optional outlet name, phone, and footer.
- [x] Settings UI: three-option dropdown and "Mode hemat kertas" switch.
- [x] Receipt screen: skip auto-print according to mode; label the manual
      button `Cetak struk` / `Cetak bukti pending` / `Cetak ulang`.
- [x] First manual print after checkout does not include `CETAK ULANG`; only
      after a successful print. Opening a receipt from history is a reprint.
- [x] Pass `compact` through `printSale()` / `buildReceipt()`.
- [x] `configured` now only requires a printer address.

## P3 — prevent duplicate paper (implemented)

- [x] `_enqueuePrint()` inserts only when no job exists for the sale and
      returns `true` only for a newly inserted job (replay does not auto-print).
- [x] Mark all pending jobs for a sale as sending/sent, not only the first.
- [x] `PrinterService.markPrinted()` plus a "Sudah tercetak" action for
      `unknown` queue jobs.
- [x] Queue retry passes `reprint: true` so it prints `CETAK ULANG`.
- [x] `BlueThermalPrinter.writeBytes` has a 20 s timeout; `PRINT_TIMEOUT` is
      treated as an unknown outcome so the job can be acknowledged instead of
      blindly retried.
- [x] Removed the unused `PrinterService.enqueue`.

### P1 follow-up (optional)
- Consider dropping `Rp` from item rows only if more width is needed.

### Later
- Optional transfer/e-wallet proof photo (not QRIS, not mandatory). Requires a
  backend upload endpoint, local file queue, compression, access control, and
  retention policy. Backend already has `sale_payments.proof_path` and
  `PaymentResource.has_proof`, but there is no upload route yet.

## Assumptions

- 58 mm Font A = 32 chars/line; 72 mm = 42; 80 mm = 48.
- Default ESC/POS line spacing 30 dots ≈ 3.75 mm per line.
- A 30 m roll holds roughly 285 receipts at 28 lines and roughly 365–400 at
  21–23 lines. These are estimates, not measured production numbers.
