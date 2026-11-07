import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../session/session_controller.dart';
import '../shifts/shift_controller.dart';
import 'sync_repository.dart';

class SyncReport {
  const SyncReport({
    this.pushed = 0,
    this.accepted = 0,
    this.pulled = 0,
    this.catalogChanged = false,
    this.conflicts = 0,
    this.blocked = 0,
  });

  final int pushed;
  final int accepted;
  final int pulled;
  final bool catalogChanged;
  final int conflicts;
  final int blocked;

  bool get didAnything => pushed > 0 || pulled > 0;
}

class SyncController extends AsyncNotifier<SyncStatusSnapshot> {
  bool _running = false;

  @override
  Future<SyncStatusSnapshot> build() async {
    return ref.read(syncRepositoryProvider).status();
  }

  bool get isRunning => _running;

  Future<SyncReport> syncNow({String? pin, String? password}) async {
    if (_running) {
      return const SyncReport();
    }
    _running = true;
    state = const AsyncLoading();
    try {
      var session = ref.read(sessionProvider).value;
      if (session == null) {
        throw const AppException('UNAUTHENTICATED', 'Sesi tidak tersedia.');
      }

      var snapshot = ref.read(bootstrapProvider).value?.snapshot;
      if (snapshot == null || snapshot.data == null) {
        await ref.read(bootstrapProvider.notifier).refresh();
        snapshot = ref.read(bootstrapProvider).value?.snapshot;
      }
      final data = snapshot?.data;
      if (data == null) {
        throw const AppException(
          'CATALOG_MISSING',
          'Data awal belum tersedia. Periksa koneksi ke server.',
        );
      }

      if (!session.leaseValid) {
        if (pin == null && password == null) {
          throw const AppException(
            'OFFLINE_LEASE_EXPIRED',
            'Lisensi offline telah berakhir. Masukkan PIN untuk memperbarui.',
          );
        }
        session = await ref
            .read(sessionProvider.notifier)
            .refreshLease(pin: pin, password: password);
      }

      final repository = ref.read(syncRepositoryProvider);
      final outletUuid = session.device?.outletUuid ?? data.outlet.uuid;

      var pushed = 0;
      var accepted = 0;
      var conflicts = 0;
      var blocked = 0;

      for (var batch = 0; batch < 12; batch++) {
        final outcome = await repository.pushOnce(
          session: session,
          outletUuid: outletUuid,
        );
        pushed += outcome.sent;
        accepted += outcome.accepted;
        conflicts += outcome.conflicts;
        blocked += outcome.blocked;
        if (outcome.sent == 0 || !outcome.hasMore) break;
      }

      var cursor = (await repository.status()).cursor ?? data.cursor ?? '';
      var pulled = 0;
      var catalogChanged = false;
      var permissionsChanged = false;
      for (var page = 0; page < 20; page++) {
        final outcome = await repository.pullOnce(cursor: cursor);
        pulled += outcome.applied;
        catalogChanged = catalogChanged || outcome.catalogChanged;
        permissionsChanged = permissionsChanged || outcome.permissionsChanged;
        cursor = outcome.cursor ?? cursor;
        if (!outcome.hasMore) break;
      }

      if (permissionsChanged) {
        try {
          await ref.read(sessionProvider.notifier).refreshProfile();
        } on AppException {
          // Permission events are rare and will be re-fetched on next sync.
        }
      }

      if (catalogChanged) {
        try {
          await ref.read(bootstrapProvider.notifier).refresh();
        } on AppException {
          // Catalog events are already applied locally; a full refresh can
          // wait for the next connectivity window.
        }
      }

      // Push/pull may have finalized a closing shift on another device or
      // changed the shared shift owner; refresh the shared state immediately.
      try {
        await ref.read(shiftProvider.notifier).refresh();
      } on AppException {
        // The local shift copy is still usable; the next screen load retries.
      }

      unawaited(ref.read(paymentProofQueueProvider).drain());

      final status = await repository.status();
      state = AsyncData(status);
      return SyncReport(
        pushed: pushed,
        accepted: accepted,
        pulled: pulled,
        catalogChanged: catalogChanged,
        conflicts: conflicts,
        blocked: blocked,
      );
    } on AppException catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      final mapped = AppException.unknown(error);
      state = AsyncError(mapped, stackTrace);
      throw mapped;
    } finally {
      _running = false;
    }
  }

  Future<void> refreshStatus() async {
    state = AsyncData(await ref.read(syncRepositoryProvider).status());
  }
}

final syncProvider = AsyncNotifierProvider<SyncController, SyncStatusSnapshot>(
  SyncController.new,
);
