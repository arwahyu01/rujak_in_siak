import '../errors/app_exception.dart';

class PricingConfig {
  const PricingConfig({
    this.taxEnabled = false,
    this.taxRateBasisPoints = 0,
    this.serviceChargeEnabled = false,
    this.serviceChargeRateBasisPoints = 0,
    this.taxIncludesServiceCharge = false,
  });

  final bool taxEnabled;
  final int taxRateBasisPoints;
  final bool serviceChargeEnabled;
  final int serviceChargeRateBasisPoints;
  final bool taxIncludesServiceCharge;

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    final tax = json['tax'] is Map ? json['tax'] as Map : const {};
    final service = json['service_charge'] is Map
        ? json['service_charge'] as Map
        : const {};
    return PricingConfig(
      taxEnabled: tax['enabled'] == true,
      taxRateBasisPoints: _int(tax['rate_basis_points']),
      serviceChargeEnabled: service['enabled'] == true,
      serviceChargeRateBasisPoints: _int(service['rate_basis_points']),
      taxIncludesServiceCharge: tax['includes_service_charge'] == true,
    );
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

class PricingLineInput {
  const PricingLineInput({
    required this.unitPrice,
    required this.quantity,
    this.itemDiscount = 0,
    this.taxRateBasisPoints,
  });

  final int unitPrice;
  final int quantity;
  final int itemDiscount;
  final int? taxRateBasisPoints;
}

class PricingLineResult {
  const PricingLineResult({
    required this.index,
    required this.unitPrice,
    required this.quantity,
    required this.gross,
    required this.itemDiscount,
    required this.afterItemDiscount,
    required this.taxRateBasisPoints,
    required this.transactionDiscountAllocation,
    required this.discountAmount,
    required this.serviceChargeAmount,
    required this.taxableBase,
    required this.taxAmount,
    required this.lineNet,
    required this.total,
  });

  final int index;
  final int unitPrice;
  final int quantity;
  final int gross;
  final int itemDiscount;
  final int afterItemDiscount;
  final int taxRateBasisPoints;
  final int transactionDiscountAllocation;
  final int discountAmount;
  final int serviceChargeAmount;
  final int taxableBase;
  final int taxAmount;
  final int lineNet;
  final int total;
}

class PricingResult {
  const PricingResult({
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.transactionDiscountTotal,
    required this.discountTotal,
    required this.netSubtotal,
    required this.serviceCharge,
    required this.taxTotal,
    required this.total,
    required this.lines,
  });

  final int subtotal;
  final int itemDiscountTotal;
  final int transactionDiscountTotal;
  final int discountTotal;
  final int netSubtotal;
  final int serviceCharge;
  final int taxTotal;
  final int total;
  final List<PricingLineResult> lines;

  Map<String, dynamic> toSnapshot(PricingConfig config) => {
    'subtotal': subtotal,
    'item_discount_total': itemDiscountTotal,
    'transaction_discount_total': transactionDiscountTotal,
    'discount_total': discountTotal,
    'net_subtotal': netSubtotal,
    'service_charge': serviceCharge,
    'tax_total': taxTotal,
    'total': total,
    'lines': lines
        .map(
          (line) => {
            'index': line.index,
            'unit_price': line.unitPrice,
            'quantity': line.quantity,
            'gross': line.gross,
            'item_discount': line.itemDiscount,
            'after_item_discount': line.afterItemDiscount,
            'tax_rate_basis_points': line.taxRateBasisPoints,
            'transaction_discount_allocation':
                line.transactionDiscountAllocation,
            'discount_amount': line.discountAmount,
            'service_charge_amount': line.serviceChargeAmount,
            'taxable_base': line.taxableBase,
            'tax_amount': line.taxAmount,
            'line_net': line.lineNet,
            'total': line.total,
          },
        )
        .toList(),
    'config': {
      'tax_enabled': config.taxEnabled,
      'tax_rate_basis_points': config.taxRateBasisPoints,
      'service_charge_enabled': config.serviceChargeEnabled,
      'service_charge_rate_basis_points': config.serviceChargeRateBasisPoints,
      'tax_includes_service_charge': config.taxIncludesServiceCharge,
      'rounding': 'half_up_to_rupiah',
      'transaction_discount_allocation': 'proportional_largest_remainder',
    },
  };
}

/// Mirrors Backend/app/Services/PricingCalculator.php exactly. All money is
/// integer rupiah; never use doubles for monetary values.
class PricingCalculator {
  const PricingCalculator();

  PricingResult calculate({
    required List<PricingLineInput> items,
    required PricingConfig config,
    int transactionDiscount = 0,
  }) {
    if (items.isEmpty) {
      throw const AppException(
        'ORDER_EMPTY',
        'Order harus memiliki minimal satu item.',
        statusCode: 422,
      );
    }

    final taxRate = config.taxEnabled ? config.taxRateBasisPoints : 0;
    final lines = <_Line>[];
    var subtotal = 0;
    var itemDiscountTotal = 0;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final unitPrice = item.unitPrice;
      final quantity = item.quantity;
      final itemDiscount = item.itemDiscount < 0 ? 0 : item.itemDiscount;
      final lineTaxRate = config.taxEnabled
          ? (item.taxRateBasisPoints ?? taxRate).clamp(0, 1000000)
          : 0;

      if (unitPrice < 0) {
        throw AppException(
          'PRICE_INVALID',
          'Harga item #$index tidak valid.',
          statusCode: 422,
        );
      }
      if (quantity < 1 || quantity > 100) {
        throw AppException(
          'QUANTITY_INVALID',
          'Kuantitas item #$index harus antara 1 dan 100.',
          statusCode: 422,
        );
      }

      final gross = unitPrice * quantity;
      if (itemDiscount > gross) {
        throw const AppException(
          'ITEM_DISCOUNT_EXCEEDS_LINE',
          'Diskon item tidak boleh melebihi nilai baris.',
          statusCode: 422,
        );
      }

      subtotal += gross;
      itemDiscountTotal += itemDiscount;
      lines.add(
        _Line(
          index: index,
          unitPrice: unitPrice,
          quantity: quantity,
          gross: gross,
          itemDiscount: itemDiscount,
          afterItemDiscount: gross - itemDiscount,
          taxRateBasisPoints: lineTaxRate,
        ),
      );
    }

    final netAfterItemDiscount = subtotal - itemDiscountTotal;
    if (transactionDiscount < 0) {
      throw const AppException(
        'TRANSACTION_DISCOUNT_INVALID',
        'Diskon transaksi tidak valid.',
        statusCode: 422,
      );
    }
    if (transactionDiscount > netAfterItemDiscount) {
      throw const AppException(
        'DISCOUNT_EXCEEDS_SUBTOTAL',
        'Diskon transaksi melebihi subtotal setelah diskon item.',
        statusCode: 422,
      );
    }

    final transactionAllocations = _allocate(
      transactionDiscount,
      lines.map((line) => line.afterItemDiscount).toList(),
    );

    final netSubtotal = netAfterItemDiscount - transactionDiscount;
    final serviceTotal = config.serviceChargeEnabled
        ? _applyRate(netSubtotal, config.serviceChargeRateBasisPoints)
        : 0;

    final serviceWeights = <int>[];
    for (var i = 0; i < lines.length; i++) {
      serviceWeights.add(
        lines[i].afterItemDiscount - transactionAllocations[i],
      );
    }
    final serviceAllocations = _allocate(serviceTotal, serviceWeights);

    var taxTotal = 0;
    final resultLines = <PricingLineResult>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNet = line.afterItemDiscount - transactionAllocations[i];
      final lineService = serviceAllocations[i];
      final taxableBase =
          lineNet + (config.taxIncludesServiceCharge ? lineService : 0);
      final lineTax = line.taxRateBasisPoints > 0
          ? _applyRate(taxableBase, line.taxRateBasisPoints)
          : 0;

      taxTotal += lineTax;
      resultLines.add(
        PricingLineResult(
          index: line.index,
          unitPrice: line.unitPrice,
          quantity: line.quantity,
          gross: line.gross,
          itemDiscount: line.itemDiscount,
          afterItemDiscount: line.afterItemDiscount,
          taxRateBasisPoints: line.taxRateBasisPoints,
          transactionDiscountAllocation: transactionAllocations[i],
          discountAmount: line.itemDiscount + transactionAllocations[i],
          serviceChargeAmount: lineService,
          taxableBase: taxableBase,
          taxAmount: lineTax,
          lineNet: lineNet,
          total: lineNet + lineService + lineTax,
        ),
      );
    }

    return PricingResult(
      subtotal: subtotal,
      itemDiscountTotal: itemDiscountTotal,
      transactionDiscountTotal: transactionDiscount,
      discountTotal: itemDiscountTotal + transactionDiscount,
      netSubtotal: netSubtotal,
      serviceCharge: serviceTotal,
      taxTotal: taxTotal,
      total: netSubtotal + serviceTotal + taxTotal,
      lines: resultLines,
    );
  }

  List<int> _allocate(int amount, List<int> weights) {
    final result = List<int>.filled(weights.length, 0);
    if (amount == 0 || weights.isEmpty) return result;

    final totalWeight = weights.fold<int>(0, (sum, value) => sum + value);
    if (totalWeight <= 0) return result;

    final remainders = <int, int>{};
    var allocated = 0;
    for (var i = 0; i < weights.length; i++) {
      final numerator = amount * (weights[i] < 0 ? 0 : weights[i]);
      result[i] = numerator ~/ totalWeight;
      remainders[i] = numerator % totalWeight;
      allocated += result[i];
    }

    var remaining = amount - allocated;
    // PHP arsort is stable, so equal remainders keep rising index order.
    final sorted = remainders.entries.toList()
      ..sort((a, b) {
        final byRemainder = b.value.compareTo(a.value);
        return byRemainder != 0 ? byRemainder : a.key.compareTo(b.key);
      });
    for (final entry in sorted) {
      if (remaining <= 0) break;
      result[entry.key]++;
      remaining--;
    }
    return result;
  }

  int _applyRate(int base, int basisPoints) =>
      ((base * basisPoints) + 5000) ~/ 10000;
}

class _Line {
  const _Line({
    required this.index,
    required this.unitPrice,
    required this.quantity,
    required this.gross,
    required this.itemDiscount,
    required this.afterItemDiscount,
    required this.taxRateBasisPoints,
  });

  final int index;
  final int unitPrice;
  final int quantity;
  final int gross;
  final int itemDiscount;
  final int afterItemDiscount;
  final int taxRateBasisPoints;
}
