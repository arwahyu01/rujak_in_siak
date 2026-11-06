import '../../../core/format/dates.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/json_utils.dart';

class SalesReportSummary {
  const SalesReportSummary({
    required this.transactions,
    required this.total,
    required this.discounts,
    required this.tax,
    required this.serviceCharge,
    required this.voidedTransactions,
    required this.voidedTotal,
  });

  final int transactions;
  final int total;
  final int discounts;
  final int tax;
  final int serviceCharge;
  final int voidedTransactions;
  final int voidedTotal;
}

class DailySales {
  const DailySales({
    required this.date,
    required this.transactions,
    required this.total,
    required this.discounts,
  });

  final DateTime date;
  final int transactions;
  final int total;
  final int discounts;
}

class CashierSales {
  const CashierSales({
    required this.name,
    required this.transactions,
    required this.total,
  });

  final String name;
  final int transactions;
  final int total;
}

class OrderTypeSales {
  const OrderTypeSales({
    required this.orderType,
    required this.transactions,
    required this.total,
  });

  final String orderType;
  final int transactions;
  final int total;
}

class SalesReport {
  const SalesReport({
    required this.summary,
    required this.daily,
    required this.byCashier,
    required this.byOrderType,
  });

  final SalesReportSummary summary;
  final List<DailySales> daily;
  final List<CashierSales> byCashier;
  final List<OrderTypeSales> byOrderType;
}

class PaymentMethodReport {
  const PaymentMethodReport({
    required this.method,
    required this.entries,
    required this.recorded,
    required this.confirmed,
  });

  final String method;
  final int entries;
  final int recorded;
  final int confirmed;
}

class ProductReportRow {
  const ProductReportRow({
    required this.name,
    required this.quantity,
    required this.total,
    this.sku,
  });

  final String name;
  final String? sku;
  final int quantity;
  final int total;
}

class ReportsApi {
  ReportsApi(this._api);

  final ApiClient _api;

  Future<SalesReport> sales({
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _api.get('reports/sales', query: _range(from, to));
    final data = asMap(result.data);
    final summary = asMap(data['summary']);
    return SalesReport(
      summary: SalesReportSummary(
        transactions: asIntOr(summary['transactions'], 0),
        total: asIntOr(summary['total'], 0),
        discounts: asIntOr(summary['discounts'], 0),
        tax: asIntOr(summary['tax'], 0),
        serviceCharge: asIntOr(summary['service_charge'], 0),
        voidedTransactions: asIntOr(summary['voided_transactions'], 0),
        voidedTotal: asIntOr(summary['voided_total'], 0),
      ),
      daily: asMapList(data['daily'])
          .map(
            (row) => DailySales(
              date: DateTime.parse(asStringOr(row['date'], '1970-01-01')),
              transactions: asIntOr(row['transactions'], 0),
              total: asIntOr(row['total'], 0),
              discounts: asIntOr(row['discounts'], 0),
            ),
          )
          .toList(growable: false),
      byCashier: asMapList(data['by_cashier'])
          .map(
            (row) => CashierSales(
              name: asStringOr(row['name'], 'Kasir'),
              transactions: asIntOr(row['transactions'], 0),
              total: asIntOr(row['total'], 0),
            ),
          )
          .toList(growable: false),
      byOrderType: asMapList(data['by_order_type'])
          .map(
            (row) => OrderTypeSales(
              orderType: asStringOr(row['order_type'], 'dine_in'),
              transactions: asIntOr(row['transactions'], 0),
              total: asIntOr(row['total'], 0),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<PaymentMethodReport>> payments({
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _api.get('reports/payments', query: _range(from, to));
    return asMapList(asMap(result.data)['by_method'])
        .map(
          (row) => PaymentMethodReport(
            method: asStringOr(row['method'], 'cash'),
            entries: asIntOr(row['entries'], 0),
            recorded: asIntOr(row['recorded'], 0),
            confirmed: asIntOr(row['confirmed'], 0),
          ),
        )
        .toList(growable: false);
  }

  Future<List<ProductReportRow>> products({
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _api.get('reports/products', query: _range(from, to));
    return asMapList(asMap(result.data)['rows'])
        .map(
          (row) => ProductReportRow(
            name: asStringOr(row['name'], 'Produk'),
            sku: asStringOrNull(row['sku']),
            quantity: asIntOr(row['quantity'], 0),
            total: asIntOr(row['total'], 0),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _range(DateTime from, DateTime to) => {
    'date_from': toApiDate(from),
    'date_to': toApiDate(to),
  };
}
