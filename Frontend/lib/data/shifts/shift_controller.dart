import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers.dart';
import '../models/shift.dart';

class ShiftViewState {
  const ShiftViewState({this.shift, this.summary, this.storedOffline = false});

  final ShiftRecord? shift;
  final ShiftSummary? summary;
  final bool storedOffline;

  bool get hasOpenShift => shift?.acceptsTransactions ?? false;

  bool get isClosing => shift?.isClosing ?? false;

  ShiftViewState copyWith({
    ShiftRecord? shift,
    ShiftSummary? summary,
    bool? storedOffline,
    bool clear = false,
  }) {
    return ShiftViewState(
      shift: clear ? null : (shift ?? this.shift),
      summary: clear ? null : (summary ?? this.summary),
      storedOffline: clear ? false : (storedOffline ?? this.storedOffline),
    );
  }
}

class ShiftController extends AsyncNotifier<ShiftViewState> {
  @override
  Future<ShiftViewState> build() async {
    return _load();
  }

  Future<ShiftViewState> _load() async {
    final repository = ref.read(shiftRepositoryProvider);
    ShiftRecord? shift;
    try {
      shift = await repository.refreshActiveFromServer();
    } on AppException {
      // Keep working from the last known local shift while offline.
      shift = await repository.activeShift();
    }
    if (shift == null) return const ShiftViewState();
    final summary = await repository.summary(shift);
    return ShiftViewState(
      shift: shift,
      summary: summary,
      storedOffline: !shift.synced,
    );
  }

  Future<ShiftRecord> open({
    required int openingCash,
    required String openingNotes,
  }) async {
    final repository = ref.read(shiftRepositoryProvider);
    final result = await repository.open(
      openingCash: openingCash,
      openingNotes: openingNotes,
    );
    final summary = await repository.summary(result.shift);
    state = AsyncData(
      ShiftViewState(
        shift: result.shift,
        summary: summary,
        storedOffline: result.storedOffline,
      ),
    );
    return result.shift;
  }

  Future<void> recordMovement({
    required String type,
    required int amount,
    required String reason,
  }) async {
    final current = state.value;
    final shift = current?.shift;
    if (shift == null) {
      throw const AppException('SHIFT_NOT_OPEN', 'Tidak ada shift aktif.');
    }
    final repository = ref.read(shiftRepositoryProvider);
    await repository.recordCashMovement(
      shift: shift,
      type: type,
      amount: amount,
      reason: reason,
    );
    await refresh();
  }

  Future<ShiftRecord> close({
    required int actualCash,
    String? closingNotes,
  }) async {
    final current = state.value;
    final summary = current?.summary;
    if (summary == null) {
      throw const AppException(
        'SHIFT_NOT_OPEN',
        'Tidak ada shift aktif untuk ditutup.',
      );
    }
    final held = await ref.read(orderRepositoryProvider).heldCount();
    if (held > 0) {
      throw AppException(
        'HELD_ORDERS_PENDING',
        'Selesaikan atau batalkan $held order ditahan sebelum menutup shift.',
        statusCode: 409,
      );
    }
    final repository = ref.read(shiftRepositoryProvider);
    final closed = await repository.close(
      summary: summary,
      actualCash: actualCash,
      closingNotes: closingNotes,
    );

    if (closed.isActive) {
      final refreshed = await repository.summary(closed);
      state = AsyncData(
        ShiftViewState(shift: closed, summary: refreshed),
      );
    } else {
      state = const AsyncData(ShiftViewState());
    }
    return closed;
  }

  Future<ShiftRecord> checkpoint() async {
    final shift = state.value?.shift;
    if (shift == null) {
      throw const AppException('SHIFT_NOT_OPEN', 'Tidak ada shift aktif.');
    }
    final repository = ref.read(shiftRepositoryProvider);
    final updated = await repository.checkpoint(shift);
    if (updated.isActive) {
      final summary = await repository.summary(updated);
      state = AsyncData(
        ShiftViewState(shift: updated, summary: summary),
      );
    } else {
      state = const AsyncData(ShiftViewState());
    }
    return updated;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }
}

final shiftProvider = AsyncNotifierProvider<ShiftController, ShiftViewState>(
  ShiftController.new,
);
