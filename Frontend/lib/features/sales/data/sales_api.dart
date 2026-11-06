import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_uuid.dart';
import '../../../core/utils/json_utils.dart';
import '../../../data/models/sale.dart';
import '../../../data/repositories/sale_repository.dart';

class SalesPage {
  const SalesPage({
    required this.records,
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  final List<SaleRecord> records;
  final int currentPage;
  final int lastPage;
  final int total;
}

class SalesApi {
  SalesApi(this._api, this._sales);

  final ApiClient _api;
  final SaleRepository _sales;

  Future<SalesPage> fetch({
    String? search,
    String? paymentStatus,
    int page = 1,
    int perPage = 20,
  }) async {
    final result = await _api.get(
      'sales',
      query: {
        'page': page,
        'per_page': perPage,
        if (search != null && search.trim().isNotEmpty) 'q': search.trim(),
        if (paymentStatus != null && paymentStatus.isNotEmpty)
          'payment_status': paymentStatus,
      },
    );

    final records = asMapList(
      result.data,
    ).map(SaleRecord.fromServer).toList(growable: false);
    for (final record in records) {
      await _sales.saveRemoteSale(record);
    }

    final pagination = asMap(result.meta['pagination']);
    return SalesPage(
      records: records,
      currentPage: asIntOr(pagination['current_page'], page),
      lastPage: asIntOr(pagination['last_page'], 1),
      total: asIntOr(pagination['total'], records.length),
    );
  }

  Future<SaleRecord> refresh(String uuid) async {
    final record = await _sales.fetchRemote(uuid);
    if (record == null) {
      throw const AppException('NOT_FOUND', 'Transaksi tidak ditemukan.');
    }
    await _sales.saveRemoteSale(record);
    return record;
  }

  Future<SaleRecord> voidSale(String uuid, String reason) async {
    final result = await _api.post(
      'sales/$uuid/void',
      body: {'reason': reason, 'idempotency_key': newUuid()},
    );
    final sale = SaleRecord.fromServer(asMap(result.data));
    await _sales.saveRemoteSale(sale);
    return sale;
  }

  Future<SaleRecord> refundSale(
    String uuid, {
    required int amount,
    required String reason,
    String? method,
  }) async {
    final result = await _api.post(
      'sales/$uuid/refund',
      body: {
        'amount': amount,
        'reason': reason,
        if (method != null && method.isNotEmpty) 'method': method,
        'idempotency_key': newUuid(),
      },
    );
    final sale = SaleRecord.fromServer(asMap(result.data));
    await _sales.saveRemoteSale(sale);
    return sale;
  }
}
