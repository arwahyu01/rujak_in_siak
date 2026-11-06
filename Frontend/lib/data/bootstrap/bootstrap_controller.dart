import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exception.dart';
import '../../core/providers.dart';
import '../models/catalog.dart';
import '../repositories/bootstrap_repository.dart';

class BootstrapState {
  const BootstrapState({
    required this.snapshot,
    this.refreshing = false,
    this.lastError,
  });

  final CatalogSnapshot snapshot;
  final bool refreshing;
  final AppException? lastError;

  BootstrapData? get data => snapshot.data;

  bool get hasData => snapshot.data != null;

  BootstrapState copyWith({
    CatalogSnapshot? snapshot,
    bool? refreshing,
    AppException? lastError,
    bool clearError = false,
  }) {
    return BootstrapState(
      snapshot: snapshot ?? this.snapshot,
      refreshing: refreshing ?? this.refreshing,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class BootstrapController extends AsyncNotifier<BootstrapState> {
  @override
  Future<BootstrapState> build() async {
    final repository = ref.read(bootstrapRepositoryProvider);
    final snapshot = await repository.loadSnapshot();
    return BootstrapState(snapshot: snapshot);
  }

  Future<void> refresh({bool throwOnError = false}) async {
    final current = state.value;
    if (current == null) {
      state = const AsyncLoading();
    } else {
      state = AsyncData(current.copyWith(refreshing: true, clearError: true));
    }

    try {
      final snapshot = await ref.read(bootstrapRepositoryProvider).refresh();
      state = AsyncData(BootstrapState(snapshot: snapshot));
    } on AppException catch (error, stackTrace) {
      if (current == null) {
        state = AsyncError(error, stackTrace);
      } else {
        state = AsyncData(
          current.copyWith(refreshing: false, lastError: error),
        );
      }
      if (throwOnError) rethrow;
    } catch (error, stackTrace) {
      final mapped = AppException.unknown(error);
      if (current == null) {
        state = AsyncError(mapped, stackTrace);
      } else {
        state = AsyncData(
          current.copyWith(refreshing: false, lastError: mapped),
        );
      }
      if (throwOnError) throw mapped;
    }
  }
}

final bootstrapProvider =
    AsyncNotifierProvider<BootstrapController, BootstrapState>(
      BootstrapController.new,
    );
