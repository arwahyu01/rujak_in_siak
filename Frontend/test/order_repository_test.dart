import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/core/database/app_database.dart';
import 'package:rujak_pos/data/repositories/order_repository.dart';
import 'package:rujak_pos/features/pos/state/cart_controller.dart';

void main() {
  late AppDatabase db;
  late OrderRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = OrderRepository(db);
  });

  tearDown(() => db.close());

  test('held summary counts quantities instead of lines', () async {
    await repository.hold(
      const CartState(
        orderType: 'take_away',
        lines: [
          CartLine(
            id: 'l1',
            productUuid: 'p1',
            productName: 'Rujak Cingur',
            unitPrice: 25000,
            quantity: 3,
          ),
          CartLine(
            id: 'l2',
            productUuid: 'p2',
            productName: 'Es Teh',
            unitPrice: 5000,
            quantity: 2,
          ),
        ],
      ),
    );

    final held = await repository.listHeld();
    expect(held, hasLength(1));
    expect(held.single.itemCount, 5);
  });

  test('loadHeld restores notes and transaction discount', () async {
    final uuid = await repository.hold(
      const CartState(
        orderType: 'dine_in',
        tableNumber: 'A1',
        transactionDiscount: 5000,
        lines: [
          CartLine(
            id: 'l1',
            productUuid: 'p1',
            productName: 'Rujak Cingur',
            unitPrice: 25000,
            quantity: 1,
            notes: 'tanpa kacang',
          ),
        ],
      ),
    );

    final loaded = await repository.loadHeld(uuid);
    expect(loaded, isNotNull);
    expect(loaded!.cart.orderType, 'dine_in');
    expect(loaded.cart.tableNumber, 'A1');
    expect(loaded.cart.transactionDiscount, 5000);
    expect(loaded.cart.lines.single.notes, 'tanpa kacang');
  });
}
