import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pricing/pricing_calculator.dart';
import '../../../core/utils/app_uuid.dart';

class CartAddon {
  const CartAddon({
    required this.uuid,
    required this.name,
    required this.price,
  });

  final String uuid;
  final String name;
  final int price;

  Map<String, dynamic> toJson() => {'uuid': uuid, 'name': name, 'price': price};

  factory CartAddon.fromJson(Map<String, dynamic> json) {
    return CartAddon(
      uuid: (json['uuid'] ?? '').toString(),
      name: (json['name'] ?? 'Tambahan').toString(),
      price: json['price'] is num ? (json['price'] as num).toInt() : 0,
    );
  }
}

class CartLine {
  const CartLine({
    required this.id,
    required this.productUuid,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    this.variantUuid,
    this.variantName,
    this.addons = const [],
    this.itemDiscount = 0,
    this.taxRateBasisPoints = 0,
    this.notes,
  });

  final String id;
  final String productUuid;
  final String productName;
  final String? variantUuid;
  final String? variantName;
  final List<CartAddon> addons;
  final int unitPrice;
  final int quantity;
  final int itemDiscount;
  final int taxRateBasisPoints;
  final String? notes;

  int get gross => unitPrice * quantity;

  String get signature {
    final addonIds = addons.map((addon) => addon.uuid).toList()..sort();
    return '$productUuid|${variantUuid ?? ''}|${addonIds.join(',')}|'
        '${notes?.trim() ?? ''}';
  }

  CartLine copyWith({
    int? quantity,
    int? itemDiscount,
    String? notes,
    bool clearNotes = false,
  }) {
    return CartLine(
      id: id,
      productUuid: productUuid,
      productName: productName,
      variantUuid: variantUuid,
      variantName: variantName,
      addons: addons,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      taxRateBasisPoints: taxRateBasisPoints,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  PricingLineInput toPricingInput() {
    return PricingLineInput(
      unitPrice: unitPrice,
      quantity: quantity,
      itemDiscount: itemDiscount,
      taxRateBasisPoints: taxRateBasisPoints > 0 ? taxRateBasisPoints : null,
    );
  }
}

class CartState {
  const CartState({
    this.lines = const [],
    this.orderType = 'dine_in',
    this.tableNumber,
    this.notes,
    this.transactionDiscount = 0,
    this.heldOrderUuid,
    this.serverOrderUuid,
    this.serverOrderVersion,
  });

  final List<CartLine> lines;
  final String orderType;
  final String? tableNumber;
  final String? notes;
  final int transactionDiscount;
  final String? heldOrderUuid;
  final String? serverOrderUuid;
  final int? serverOrderVersion;

  bool get isEmpty => lines.isEmpty;

  int get itemCount => lines.fold(0, (sum, line) => sum + line.quantity);

  PricingResult? calculate(PricingConfig config) {
    if (lines.isEmpty) return null;
    return const PricingCalculator().calculate(
      items: lines.map((line) => line.toPricingInput()).toList(),
      config: config,
      transactionDiscount: transactionDiscount,
    );
  }

  int totalFor(PricingConfig config) => calculate(config)?.total ?? 0;

  CartState copyWith({
    List<CartLine>? lines,
    String? orderType,
    String? tableNumber,
    String? notes,
    int? transactionDiscount,
    String? heldOrderUuid,
    String? serverOrderUuid,
    int? serverOrderVersion,
    bool clearTable = false,
    bool clearNotes = false,
    bool clearHeldOrder = false,
    bool clearServerOrder = false,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      orderType: orderType ?? this.orderType,
      tableNumber: clearTable ? null : (tableNumber ?? this.tableNumber),
      notes: clearNotes ? null : (notes ?? this.notes),
      transactionDiscount: transactionDiscount ?? this.transactionDiscount,
      heldOrderUuid: clearHeldOrder
          ? null
          : (heldOrderUuid ?? this.heldOrderUuid),
      serverOrderUuid: clearServerOrder
          ? null
          : (serverOrderUuid ?? this.serverOrderUuid),
      serverOrderVersion: clearServerOrder
          ? null
          : (serverOrderVersion ?? this.serverOrderVersion),
    );
  }
}

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addLine({
    required String productUuid,
    required String productName,
    required int unitPrice,
    String? variantUuid,
    String? variantName,
    List<CartAddon> addons = const [],
    int taxRateBasisPoints = 0,
    int quantity = 1,
    String? notes,
  }) {
    final lineNotes = _cleanNotes(notes);
    final signature = CartLine(
      id: '',
      productUuid: productUuid,
      productName: productName,
      unitPrice: unitPrice,
      quantity: quantity,
      variantUuid: variantUuid,
      variantName: variantName,
      addons: addons,
      taxRateBasisPoints: taxRateBasisPoints,
      notes: lineNotes,
    ).signature;

    final index = state.lines.indexWhere((line) => line.signature == signature);
    final updated = List<CartLine>.from(state.lines);
    if (index >= 0) {
      final existing = updated[index];
      updated[index] = existing.copyWith(
        quantity: (existing.quantity + quantity).clamp(1, 100),
      );
    } else {
      updated.add(
        CartLine(
          id: newUuid(),
          productUuid: productUuid,
          productName: productName,
          unitPrice: unitPrice,
          quantity: quantity.clamp(1, 100),
          variantUuid: variantUuid,
          variantName: variantName,
          addons: List.unmodifiable(addons),
          taxRateBasisPoints: taxRateBasisPoints,
          notes: lineNotes,
        ),
      );
    }
    state = _normalize(state.copyWith(lines: updated));
  }

  void setQuantity(String lineId, int quantity) {
    if (quantity <= 0) {
      removeLine(lineId);
      return;
    }
    state = _normalize(
      state.copyWith(
        lines: state.lines
            .map(
              (line) => line.id == lineId
                  ? line.copyWith(quantity: quantity.clamp(1, 100))
                  : line,
            )
            .toList(growable: false),
      ),
    );
  }

  void increment(String lineId) {
    final line = _find(lineId);
    if (line != null) setQuantity(lineId, line.quantity + 1);
  }

  void decrement(String lineId) {
    final line = _find(lineId);
    if (line != null) setQuantity(lineId, line.quantity - 1);
  }

  void removeLine(String lineId) {
    state = _normalize(
      state.copyWith(
        lines: state.lines
            .where((line) => line.id != lineId)
            .toList(growable: false),
      ),
    );
  }

  void setLineDiscount(String lineId, int discount) {
    state = _normalize(
      state.copyWith(
        lines: state.lines
            .map(
              (line) => line.id == lineId
                  ? line.copyWith(itemDiscount: discount < 0 ? 0 : discount)
                  : line,
            )
            .toList(growable: false),
      ),
    );
  }

  void setLineNotes(String lineId, String? notes) {
    final text = _cleanNotes(notes);
    state = _withoutServerOrder(
      state.copyWith(
        lines: state.lines
            .map(
              (line) => line.id == lineId
                  ? line.copyWith(notes: text, clearNotes: text == null)
                  : line,
            )
            .toList(growable: false),
      ),
    );
  }

  void insertLine(int index, CartLine line) {
    if (state.lines.any((item) => item.id == line.id)) return;
    final lines = List<CartLine>.from(state.lines);
    final position = index.clamp(0, lines.length);
    lines.insert(position, line);
    state = _normalize(state.copyWith(lines: lines));
  }

  void setOrderType(String value) {
    state = _withoutServerOrder(
      state.copyWith(orderType: value, clearTable: value != 'dine_in'),
    );
  }

  void setTableNumber(String? value) {
    final text = value?.trim();
    state = _withoutServerOrder(
      state.copyWith(
        tableNumber: text == null || text.isEmpty ? null : text,
        clearTable: text == null || text.isEmpty,
      ),
    );
  }

  void setNotes(String? value) {
    final text = value?.trim();
    state = _withoutServerOrder(
      state.copyWith(
        notes: text == null || text.isEmpty ? null : text,
        clearNotes: text == null || text.isEmpty,
      ),
    );
  }

  void setTransactionDiscount(int value) {
    final maxDiscount = _maxTransactionDiscount(state.lines);
    final next = value < 0 ? 0 : (value > maxDiscount ? maxDiscount : value);
    state = _withoutServerOrder(state.copyWith(transactionDiscount: next));
  }

  void linkServerOrder({required String uuid, required int version}) {
    state = state.copyWith(serverOrderUuid: uuid, serverOrderVersion: version);
  }

  void unlinkServerOrder() {
    state = state.copyWith(clearServerOrder: true);
  }

  void restore(CartState value) {
    state = _normalize(value);
  }

  void clear() {
    state = const CartState();
  }

  /// Keeps every discount within the amount it applies to. This prevents the
  /// pricing calculator from throwing inside widget builds and covers carts
  /// restored from older local data.
  CartState _normalize(CartState value) {
    final lines = value.lines
        .map((line) {
          final maxDiscount = line.gross;
          final discount = line.itemDiscount < 0
              ? 0
              : (line.itemDiscount > maxDiscount
                    ? maxDiscount
                    : line.itemDiscount);
          return discount == line.itemDiscount
              ? line
              : line.copyWith(itemDiscount: discount);
        })
        .toList(growable: false);

    final maxDiscount = _maxTransactionDiscount(lines);
    final transactionDiscount = value.transactionDiscount < 0
        ? 0
        : (value.transactionDiscount > maxDiscount
              ? maxDiscount
              : value.transactionDiscount);

    return _withoutServerOrder(
      value.copyWith(lines: lines, transactionDiscount: transactionDiscount),
    );
  }

  /// A server order is a snapshot of the cart that was sent at checkout time.
  /// Any later local change makes that snapshot stale, so the next checkout
  /// must create a fresh order instead of reusing the old items.
  CartState _withoutServerOrder(CartState value) {
    return value.serverOrderUuid == null
        ? value
        : value.copyWith(clearServerOrder: true);
  }

  int _maxTransactionDiscount(List<CartLine> lines) {
    return lines.fold<int>(
      0,
      (sum, line) => sum + (line.gross - line.itemDiscount),
    );
  }

  String? _cleanNotes(String? notes) {
    final text = notes?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  CartLine? _find(String lineId) {
    for (final line in state.lines) {
      if (line.id == lineId) return line;
    }
    return null;
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(
  CartController.new,
);
