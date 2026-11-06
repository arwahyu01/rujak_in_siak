import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/utils/app_uuid.dart';
import '../../core/utils/json_utils.dart';
import '../../features/pos/state/cart_controller.dart';

class HeldOrderSummary {
  const HeldOrderSummary({
    required this.uuid,
    required this.orderType,
    required this.tableNumber,
    required this.itemCount,
    required this.updatedAt,
    this.notes,
  });

  final String uuid;
  final String orderType;
  final String? tableNumber;
  final int itemCount;
  final DateTime updatedAt;
  final String? notes;
}

class HeldOrder {
  const HeldOrder({required this.cart, required this.updatedAt});

  final CartState cart;
  final DateTime updatedAt;
}

class OrderRepository {
  OrderRepository(this._db);

  final AppDatabase _db;

  Future<String> hold(CartState cart) async {
    if (cart.lines.isEmpty) {
      throw StateError('Cart is empty');
    }
    final now = DateTime.now();
    final uuid = cart.heldOrderUuid ?? newUuid();

    await _db.transaction(() async {
      final existing = await (_db.select(
        _db.localOrders,
      )..where((row) => row.uuid.equals(uuid))).getSingleOrNull();

      await _db
          .into(_db.localOrders)
          .insertOnConflictUpdate(
            LocalOrdersCompanion(
              uuid: Value(uuid),
              orderType: Value(cart.orderType),
              tableNumber: Value(cart.tableNumber),
              notes: Value(cart.notes),
              status: const Value('held'),
              transactionDiscount: Value(cart.transactionDiscount),
              createdAt: Value(existing?.createdAt ?? now),
              updatedAt: Value(now),
            ),
          );

      await (_db.delete(
        _db.orderItems,
      )..where((row) => row.orderUuid.equals(uuid))).go();

      for (final line in cart.lines) {
        final pricing = line.toPricingInput();
        await _db
            .into(_db.orderItems)
            .insert(
              OrderItemsCompanion.insert(
                orderUuid: uuid,
                productUuid: line.productUuid,
                productName: line.productName,
                variantUuid: Value(line.variantUuid),
                variantName: Value(line.variantName),
                addonsJson: Value(
                  jsonEncode(
                    line.addons.map((addon) => addon.toJson()).toList(),
                  ),
                ),
                unitPrice: line.unitPrice,
                quantity: line.quantity,
                itemDiscount: Value(line.itemDiscount),
                taxRateBasisPoints: Value(line.taxRateBasisPoints),
                lineSubtotal: Value(pricing.unitPrice * pricing.quantity),
                lineTotal: const Value(0),
                notes: Value(line.notes),
              ),
            );
      }
    });

    return uuid;
  }

  Future<List<HeldOrderSummary>> listHeld() async {
    final orders =
        await (_db.select(_db.localOrders)
              ..where((row) => row.status.equals('held'))
              ..orderBy([(row) => OrderingTerm.desc(row.updatedAt)]))
            .get();

    final result = <HeldOrderSummary>[];
    for (final order in orders) {
      final count = await _db
          .customSelect(
            'SELECT COUNT(*) AS total FROM order_items WHERE order_uuid = ?',
            variables: [Variable<String>(order.uuid)],
            readsFrom: {_db.orderItems},
          )
          .map((row) => row.read<int>('total'))
          .getSingle();
      result.add(
        HeldOrderSummary(
          uuid: order.uuid,
          orderType: order.orderType,
          tableNumber: order.tableNumber,
          itemCount: count,
          updatedAt: order.updatedAt,
          notes: order.notes,
        ),
      );
    }
    return result;
  }

  Future<HeldOrder?> loadHeld(String uuid) async {
    final order = await (_db.select(
      _db.localOrders,
    )..where((row) => row.uuid.equals(uuid))).getSingleOrNull();
    if (order == null) return null;

    final items =
        await (_db.select(_db.orderItems)
              ..where((row) => row.orderUuid.equals(uuid))
              ..orderBy([(row) => OrderingTerm.asc(row.id)]))
            .get();

    final lines = items
        .map(
          (item) => CartLine(
            id: newUuid(),
            productUuid: item.productUuid,
            productName: item.productName,
            variantUuid: item.variantUuid,
            variantName: item.variantName,
            addons: asMapList(
              _decode(item.addonsJson),
            ).map(CartAddon.fromJson).toList(growable: false),
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            itemDiscount: item.itemDiscount,
            taxRateBasisPoints: item.taxRateBasisPoints,
            notes: item.notes,
          ),
        )
        .toList(growable: false);

    return HeldOrder(
      cart: CartState(
        lines: lines,
        orderType: order.orderType,
        tableNumber: order.tableNumber,
        notes: order.notes,
        transactionDiscount: order.transactionDiscount,
        heldOrderUuid: order.uuid,
      ),
      updatedAt: order.updatedAt,
    );
  }

  Future<void> deleteHeld(String uuid) async {
    await (_db.delete(
      _db.localOrders,
    )..where((row) => row.uuid.equals(uuid))).go();
  }

  Future<int> heldCount() async {
    return (_db.selectOnly(_db.localOrders)
          ..addColumns([_db.localOrders.uuid.count()])
          ..where(_db.localOrders.status.equals('held')))
        .map((row) => row.read(_db.localOrders.uuid.count()) ?? 0)
        .getSingle();
  }

  dynamic _decode(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return const <dynamic>[];
    }
  }
}
