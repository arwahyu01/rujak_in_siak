import 'dart:convert';

import '../../core/database/app_database.dart';

class OutboxWriter {
  OutboxWriter(this._db);

  final AppDatabase _db;

  /// Must be called inside a database transaction together with the local
  /// business change so an event can never be lost or duplicated.
  Future<int> append({
    required String eventId,
    required String eventType,
    required String aggregateType,
    required String aggregateId,
    required Map<String, dynamic> payload,
    DateTime? occurredAt,
  }) async {
    final sequence = await _nextSequence();
    final now = occurredAt ?? DateTime.now();
    await _db
        .into(_db.outboxEvents)
        .insert(
          OutboxEventsCompanion.insert(
            eventId: eventId,
            eventType: eventType,
            aggregateType: aggregateType,
            aggregateId: aggregateId,
            sequence: sequence,
            payloadJson: jsonEncode(payload),
            occurredAt: now,
            createdAt: now,
          ),
        );
    return sequence;
  }

  Future<int> _nextSequence() async {
    final row = await _db
        .customSelect(
          'SELECT COALESCE(MAX(sequence), 0) AS max_sequence FROM outbox_events',
          readsFrom: {_db.outboxEvents},
        )
        .getSingle();
    return row.read<int>('max_sequence') + 1;
  }

  Future<int> pendingCount() async {
    return _db
        .customSelect(
          '''
          SELECT COUNT(*) AS total FROM outbox_events
          WHERE status IN ('pending', 'blocked_dependency')
             OR (status = 'rejected' AND retryable = 1)
          ''',
          readsFrom: {_db.outboxEvents},
        )
        .map((row) => row.read<int>('total'))
        .getSingle();
  }

  Future<int> conflictCount() async {
    return _db
        .customSelect(
          "SELECT COUNT(*) AS total FROM outbox_events WHERE status = 'conflict'",
          readsFrom: {_db.outboxEvents},
        )
        .map((row) => row.read<int>('total'))
        .getSingle();
  }

  Future<int> maxSequence() async {
    return _db
        .customSelect(
          'SELECT COALESCE(MAX(sequence), 0) AS seq FROM outbox_events',
          readsFrom: {_db.outboxEvents},
        )
        .map((row) => row.read<int>('seq'))
        .getSingle();
  }
}
