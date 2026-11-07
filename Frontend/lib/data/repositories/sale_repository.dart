import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/database/app_database.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import '../../core/pricing/pricing_calculator.dart';
import '../../core/utils/app_uuid.dart';
import '../../core/utils/json_utils.dart';
import '../../features/pos/state/cart_controller.dart';
import '../models/auth.dart';
import '../models/sale.dart';
import '../models/shift.dart';
import 'bootstrap_repository.dart';
import '../services/payment_proof_queue.dart';
import '../services/proof_matcher.dart';
import '../services/receipt_number_service.dart';
import '../sync/outbox_writer.dart';
import '../sync/sync_repository.dart';

class CheckoutOutcome {
  const CheckoutOutcome({
    required this.sale,
    required this.offline,
    this.replayed = false,
    this.printQueued = true,
  });

  final SaleRecord sale;

  /// True when the sale was finalized locally and is waiting in the outbox.
  final bool offline;

  /// True when the server reported the order was already converted and the
  /// existing sale was loaded instead of creating a second one.
  final bool replayed;

  final bool printQueued;
}

class SaleRepository {
  SaleRepository(
    this._db,
    this._api,
    this._outbox,
    this._receipts,
    this._proofs,
  );

  static const _allowedMethods = {'cash', 'qris', 'transfer', 'ewallet'};

  final AppDatabase _db;
  final ApiClient _api;
  final OutboxWriter _outbox;
  final ReceiptNumberService _receipts;
  final PaymentProofQueue _proofs;

  Future<CheckoutOutcome> checkout({
    required CartState cart,
    required PricingResult pricing,
    required List<LocalPaymentDraft> payments,
    required ShiftRecord shift,
    required CatalogSnapshot snapshot,
    required AuthSession session,
    bool allowOffline = true,
    bool forceOffline = false,
  }) async {
    if (cart.lines.isEmpty) {
      throw const AppException('ORDER_EMPTY', 'Keranjang masih kosong.');
    }
    if (!shift.isOpen) {
      throw const AppException(
        'SHIFT_NOT_OPEN',
        'Shift tidak aktif. Buka shift sebelum checkout.',
      );
    }
    _validatePayments(
      payments,
      pricing.total,
      requireProof:
          (snapshot.data?.nonCashProofRequired ?? false) &&
          !session.user.isOwner,
    );

    final config = snapshot.data?.pricingConfig ?? const PricingConfig();
    final goOffline = forceOffline || !shift.synced;

    if (goOffline || !allowOffline) {
      await _assertOfflineReady(snapshot: snapshot, session: session);
      if (!allowOffline) {
        throw const AppException(
          'OFFLINE_CHECKOUT_DISABLED',
          'Checkout offline dinonaktifkan pada perangkat ini.',
        );
      }
      return _offlineCheckout(
        cart: cart,
        pricing: pricing,
        config: config,
        payments: payments,
        shift: shift,
        snapshot: snapshot,
        session: session,
      );
    }

    String? orderUuid = cart.serverOrderUuid;
    var orderVersion = cart.serverOrderVersion;

    if (orderUuid == null) {
      try {
        final result = await _api.post(
          'orders',
          body: {
            'order_type': cart.orderType,
            if (cart.tableNumber != null && cart.tableNumber!.isNotEmpty)
              'table_number': cart.tableNumber,
            if (cart.notes != null && cart.notes!.isNotEmpty)
              'notes': cart.notes,
            'transaction_discount': cart.transactionDiscount,
            'items': cart.lines
                .map(
                  (line) => {
                    'product_uuid': line.productUuid,
                    if (line.variantUuid != null)
                      'variant_uuid': line.variantUuid,
                    'addon_uuids': line.addons
                        .map((addon) => addon.uuid)
                        .toList(growable: false),
                    'quantity': line.quantity,
                    'item_discount': line.itemDiscount,
                    if (line.notes != null && line.notes!.isNotEmpty)
                      'notes': line.notes,
                  },
                )
                .toList(growable: false),
          },
        );
        final data = asMap(result.data);
        orderUuid = asStringOrNull(data['uuid']);
        orderVersion = asIntOr(data['version'], 1);
        if (orderUuid == null || orderUuid.isEmpty) {
          throw const AppException(
            'ORDER_INVALID',
            'Server tidak mengembalikan order yang valid.',
          );
        }
      } on AppException catch (error) {
        if (!error.isNetwork) rethrow;
        if (!allowOffline) rethrow;
        await _assertOfflineReady(snapshot: snapshot, session: session);
        return _offlineCheckout(
          cart: cart,
          pricing: pricing,
          config: config,
          payments: payments,
          shift: shift,
          snapshot: snapshot,
          session: session,
        );
      }
    }

    final now = DateTime.now();
    final checkoutKey = newUuid();
    final paymentKeys = [
      for (final payment in payments) payment.idempotencyKey ?? newUuid(),
    ];
    final body = {
      'order_uuid': orderUuid,
      'base_version': orderVersion ?? 1,
      if (cart.notes != null && cart.notes!.isNotEmpty) 'notes': cart.notes,
      'client_created_at': now.toIso8601String(),
      'payments': [
        for (var index = 0; index < payments.length; index++)
          payments[index].toCheckoutJson(paymentKeys[index]),
      ],
    };

    try {
      final result = await _api.post(
        'sales/checkout',
        body: body,
        headers: {'Idempotency-Key': checkoutKey},
      );
      final sale = SaleRecord.fromServer(asMap(result.data));
      final proofs = _proofSeeds(payments, paymentKeys, sale);
      final printQueued = await _saveAndQueue(sale, proofs: proofs);
      await _discardHeldOrder(cart.heldOrderUuid);
      return CheckoutOutcome(
        sale: sale,
        offline: false,
        printQueued: printQueued,
      );
    } on AppException catch (error) {
      if (error.code == 'ORDER_ALREADY_CONVERTED') {
        final saleUuid = asStringOrNull(error.details?['sale_uuid']);
        if (saleUuid != null && saleUuid.isNotEmpty) {
          final existing = await fetchRemote(saleUuid);
          if (existing != null) {
            final proofs = _proofSeeds(payments, paymentKeys, existing);
            final printQueued = await _saveAndQueue(existing, proofs: proofs);
            await _discardHeldOrder(cart.heldOrderUuid);
            return CheckoutOutcome(
              sale: existing,
              offline: false,
              replayed: true,
              printQueued: printQueued,
            );
          }
        }
      }
      if (error.isNetwork) {
        throw AppException(
          'CHECKOUT_UNCONFIRMED',
          'Order sudah dibuat di server tetapi checkout belum terkonfirmasi. '
              'Periksa koneksi lalu coba lagi dengan order yang sama.',
          retryable: true,
          details: {
            'order_uuid': orderUuid,
            'order_version': orderVersion ?? 1,
          },
        );
      }
      throw AppException(
        error.code,
        error.message,
        statusCode: error.statusCode,
        retryable: error.retryable,
        details: {
          ...?error.details,
          'order_uuid': orderUuid,
          'order_version': orderVersion ?? 1,
        },
      );
    }
  }

  void _validatePayments(
    List<LocalPaymentDraft> payments,
    int total, {
    required bool requireProof,
  }) {
    if (total <= 0) {
      if (payments.isNotEmpty) {
        throw const AppException(
          'PAYMENT_TOTAL_MISMATCH',
          'Transaksi tanpa nilai tidak memerlukan pembayaran.',
        );
      }
      return;
    }
    if (payments.isEmpty) {
      throw const AppException(
        'PAYMENT_REQUIRED',
        'Pembayaran wajib diisi sebelum checkout.',
      );
    }

    var sum = 0;
    for (final payment in payments) {
      if (!_allowedMethods.contains(payment.method)) {
        throw const AppException(
          'PAYMENT_METHOD_INVALID',
          'Metode pembayaran tidak valid.',
        );
      }
      if (payment.amount <= 0) {
        throw const AppException(
          'PAYMENT_AMOUNT_INVALID',
          'Nominal pembayaran harus lebih besar dari nol.',
        );
      }
      if (payment.isCash) {
        final tendered = payment.tenderedAmount ?? payment.amount;
        if (tendered < payment.amount) {
          throw const AppException(
            'CASH_TENDERED_INSUFFICIENT',
            'Uang tunai diterima kurang dari nominal pembayaran.',
          );
        }
      } else if (requireProof &&
          (payment.proofPath == null || payment.proofPath!.isEmpty)) {
        throw const AppException(
          'PAYMENT_PROOF_REQUIRED',
          'Foto bukti pembayaran wajib dilampirkan untuk pembayaran '
          'non-tunai sesuai pengaturan Owner.',
        );
      }
      sum += payment.amount;
    }

    if (sum != total) {
      throw AppException(
        'PAYMENT_TOTAL_MISMATCH',
        'Total pembayaran harus sama dengan total transaksi.',
        details: {'total': total, 'paid': sum},
      );
    }
  }

  Future<void> _assertOfflineReady({
    required CatalogSnapshot snapshot,
    required AuthSession session,
  }) async {
    final device = session.device;
    if (device == null || device.uuid.isEmpty) {
      throw const AppException(
        'DEVICE_REQUIRED',
        'Perangkat belum terdaftar. Selesaikan pengaturan perangkat.',
      );
    }
    if (!session.leaseValid) {
      throw const AppException(
        'OFFLINE_LEASE_EXPIRED',
        'Lisensi offline telah berakhir. Sambungkan ke internet dan perbarui lisensi.',
      );
    }
    if (snapshot.data == null) {
      throw const AppException(
        'CATALOG_MISSING',
        'Katalog lokal belum tersedia. Sambungkan ke internet untuk memuat katalog.',
      );
    }
    if (snapshot.freshness == CatalogFreshness.expired) {
      throw const AppException(
        'CATALOG_EXPIRED',
        'Katalog lokal sudah kedaluwarsa. Sambungkan ke internet untuk memperbarui katalog sebelum transaksi offline.',
      );
    }
    if (await _clockUntrusted()) {
      throw const AppException(
        'CLOCK_UNTRUSTED',
        'Waktu perangkat tidak tepercaya. Sambungkan ke internet dan sinkronkan ulang sebelum transaksi offline.',
      );
    }
  }

  Future<bool> _clockUntrusted() async {
    if (await _db.setting(SyncRepository.clockUntrustedKey) == '1') {
      return true;
    }
    final anchorRaw = await _db.setting(SyncRepository.clockAnchorKey);
    final anchor = DateTime.tryParse(anchorRaw ?? '');
    if (anchor == null) return false;
    final earliest = anchor.toUtc().subtract(const Duration(minutes: 5));
    return DateTime.now().toUtc().isBefore(earliest);
  }

  Future<CheckoutOutcome> _offlineCheckout({
    required CartState cart,
    required PricingResult pricing,
    required PricingConfig config,
    required List<LocalPaymentDraft> payments,
    required ShiftRecord shift,
    required CatalogSnapshot snapshot,
    required AuthSession session,
  }) async {
    final data = snapshot.data!;
    final device = session.device!;
    final now = DateTime.now();
    final orderUuid = newUuid();
    final saleUuid = newUuid();
    final outletCode = device.outletCode?.isNotEmpty == true
        ? device.outletCode!
        : data.outlet.code;
    final receiptNumber = await _receipts.nextOffline(
      outletCode: outletCode,
      terminalCode: device.terminalCode,
      format: data.receiptNumberFormat,
    );

    final pricingSnapshot = _pricingSnapshot(pricing, config, now);
    final products = {for (final item in data.products) item.uuid: item};
    final orderItems = <Map<String, dynamic>>[];
    final saleItems = <Map<String, dynamic>>[];

    for (var index = 0; index < cart.lines.length; index++) {
      final line = cart.lines[index];
      final result = pricing.lines[index];
      final product = products[line.productUuid];
      final addonSummary = line.addons.map((addon) => addon.name).join(', ');
      orderItems.add({
        'item_uuid': newUuid(),
        'product_uuid': line.productUuid,
        'sku': product?.sku,
        'product_name': line.productName,
        'variant_uuid': line.variantUuid,
        'variant_name': line.variantName,
        'addons': line.addons
            .map(
              (addon) => {
                'uuid': addon.uuid,
                'name': addon.name,
                'price': addon.price,
              },
            )
            .toList(growable: false),
        'unit_price': line.unitPrice,
        'quantity': line.quantity,
        'item_discount': result.itemDiscount,
        'tax_rate_basis_points': result.taxRateBasisPoints,
        'notes': line.notes,
        'line_subtotal': result.gross,
        'line_total': result.total,
        'snapshot': {
          'product_uuid': line.productUuid,
          'product_name': line.productName,
          'variant_name': line.variantName,
          'addon_summary': addonSummary,
        },
        'modifiers': line.addons
            .map(
              (addon) => {
                'type': 'addon',
                'modifier_uuid': addon.uuid,
                'name': addon.name,
                'price': addon.price,
                'quantity': 1,
              },
            )
            .toList(growable: false),
      });
      saleItems.add({
        'product_uuid': line.productUuid,
        'sku': product?.sku,
        'product_name': line.productName,
        'variant_uuid': line.variantUuid,
        'variant_name': line.variantName,
        'addon_summary': addonSummary.isEmpty ? null : addonSummary,
        'unit_price': line.unitPrice,
        'quantity': line.quantity,
        'discount_amount': result.discountAmount,
        'tax_rate_basis_points': result.taxRateBasisPoints,
        'tax_amount': result.taxAmount,
        'service_charge_amount': result.serviceChargeAmount,
        'subtotal': result.gross,
        'total': result.total,
        'snapshot': {
          'transaction_discount_allocation':
              result.transactionDiscountAllocation,
          'taxable_base': result.taxableBase,
        },
      });
    }

    final paymentPayloads = <Map<String, dynamic>>[];
    final confirmed = payments
        .where((payment) => payment.status == 'confirmed')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final awaiting = payments
        .where((payment) => payment.status == 'awaiting_verification')
        .fold<int>(0, (sum, payment) => sum + payment.amount);
    final paymentStatus = _paymentStatus(
      total: pricing.total,
      confirmed: confirmed,
      awaiting: awaiting,
    );
    final outstanding = (pricing.total - confirmed).clamp(0, pricing.total);

    final paymentUuids = [for (final _ in payments) newUuid()];
    final paymentKeys = [
      for (final payment in payments) payment.idempotencyKey ?? newUuid(),
    ];
    for (var index = 0; index < payments.length; index++) {
      final payment = payments[index];
      paymentPayloads.add({
        'payment_uuid': paymentUuids[index],
        'idempotency_key': paymentKeys[index],
        'method': payment.method,
        'amount': payment.amount,
        'tendered_amount': payment.isCash
            ? payment.tenderedAmount ?? payment.amount
            : null,
        'change_amount': payment.changeAmount,
        'status': payment.status,
        'provider_reference': payment.providerReference,
        'notes': payment.notes,
        'recorded_at': now.toIso8601String(),
      });
    }
    final proofSeeds = [
      for (var index = 0; index < payments.length; index++)
        if (!payments[index].isCash && payments[index].proofPath != null)
          ProofUploadSeed(
            saleUuid: saleUuid,
            paymentUuid: paymentUuids[index],
            idempotencyKey: paymentKeys[index],
            localPath: payments[index].proofPath!,
          ),
    ];

    final sale = SaleRecord(
      uuid: saleUuid,
      receiptNumber: receiptNumber,
      orderUuid: orderUuid,
      sourceOrderVersion: 1,
      origin: 'offline',
      orderType: cart.orderType,
      tableNumber: cart.tableNumber,
      lifecycleStatus: 'finalized',
      paymentStatus: paymentStatus,
      subtotal: pricing.subtotal,
      itemDiscountTotal: pricing.itemDiscountTotal,
      transactionDiscountTotal: pricing.transactionDiscountTotal,
      discountTotal: pricing.discountTotal,
      serviceCharge: pricing.serviceCharge,
      taxTotal: pricing.taxTotal,
      total: pricing.total,
      confirmedAmount: confirmed,
      awaitingAmount: awaiting,
      outstandingAmount: outstanding,
      refundedAmount: 0,
      shiftUuid: shift.uuid,
      cashierName: session.user.name,
      notes: cart.notes,
      synced: false,
      transactedAt: now,
      createdAt: now,
      items: saleItems
          .map(
            (item) => SaleItemRecord(
              productName: asStringOr(item['product_name'], 'Produk'),
              productUuid: asStringOrNull(item['product_uuid']),
              variantName: asStringOrNull(item['variant_name']),
              addonsSummary: asStringOrNull(item['addon_summary']),
              quantity: asIntOr(item['quantity'], 1),
              unitPrice: asIntOr(item['unit_price'], 0),
              discountAmount: asIntOr(item['discount_amount'], 0),
              taxAmount: asIntOr(item['tax_amount'], 0),
              lineTotal: asIntOr(item['total'], 0),
            ),
          )
          .toList(growable: false),
      payments: [
        for (var index = 0; index < payments.length; index++)
          SalePaymentRecord(
            uuid: paymentUuids[index],
            method: payments[index].method,
            amount: payments[index].amount,
            tenderedAmount: payments[index].isCash
                ? payments[index].tenderedAmount ?? payments[index].amount
                : null,
            changeAmount: payments[index].changeAmount,
            status: payments[index].status,
            providerReference: payments[index].providerReference,
            idempotencyKey: paymentKeys[index],
            notes: payments[index].notes,
            recordedAt: now,
          ),
      ],
    );

    await _db.transaction(() async {
      final orderUuidValue = orderUuid;
      await _db
          .into(_db.localOrders)
          .insert(
            LocalOrdersCompanion.insert(
              uuid: orderUuidValue,
              orderType: Value(cart.orderType),
              tableNumber: Value(cart.tableNumber),
              notes: Value(cart.notes),
              status: const Value('converted'),
              transactionDiscount: Value(cart.transactionDiscount),
              baseVersion: const Value(1),
              synced: const Value(false),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrReplace,
          );

      for (var i = 0; i < cart.lines.length; i++) {
        final line = cart.lines[i];
        final result = pricing.lines[i];
        await _db
            .into(_db.orderItems)
            .insert(
              OrderItemsCompanion.insert(
                orderUuid: orderUuidValue,
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
                itemDiscount: Value(result.itemDiscount),
                taxRateBasisPoints: Value(result.taxRateBasisPoints),
                lineSubtotal: Value(result.gross),
                lineTotal: Value(result.total),
                notes: Value(line.notes),
              ),
            );
      }

      await _insertSale(
        sale,
        localOrderUuid: orderUuid,
        synced: false,
        payments: paymentPayloads,
      );
      await _proofs.enqueueAll(proofSeeds);

      await _outbox.append(
        eventId: newUuid(),
        eventType: 'order.created',
        aggregateType: 'order',
        aggregateId: orderUuid,
        occurredAt: now,
        payload: {
          'order_uuid': orderUuid,
          'status': 'converted',
          'version': 1,
          'order_type': cart.orderType,
          'table_number': cart.tableNumber,
          'notes': cart.notes,
          'shift_uuid': shift.uuid,
          'device_uuid': device.uuid,
          'user_uuid': session.user.uuid,
          'subtotal': pricing.subtotal,
          'item_discount_total': pricing.itemDiscountTotal,
          'transaction_discount_total': pricing.transactionDiscountTotal,
          'discount_total': pricing.discountTotal,
          'service_charge': pricing.serviceCharge,
          'tax_total': pricing.taxTotal,
          'total': pricing.total,
          'pricing_snapshot': pricingSnapshot,
          'items': orderItems,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'converted_at': now.toIso8601String(),
        },
      );

      await _outbox.append(
        eventId: newUuid(),
        eventType: 'sale.finalized',
        aggregateType: 'sale',
        aggregateId: saleUuid,
        occurredAt: now,
        payload: {
          'sale_uuid': saleUuid,
          'order_uuid': orderUuid,
          'source_order_uuid': orderUuid,
          'source_order_version': 1,
          'receipt_number': receiptNumber,
          'order_type': cart.orderType,
          'table_number': cart.tableNumber,
          'notes': cart.notes,
          'lifecycle_status': 'finalized',
          'payment_status': paymentStatus,
          'subtotal': pricing.subtotal,
          'item_discount_total': pricing.itemDiscountTotal,
          'transaction_discount_total': pricing.transactionDiscountTotal,
          'discount_total': pricing.discountTotal,
          'service_charge': pricing.serviceCharge,
          'tax_total': pricing.taxTotal,
          'total': pricing.total,
          'shift_uuid': shift.uuid,
          'device_uuid': device.uuid,
          'pricing_snapshot': pricingSnapshot,
          'items': saleItems,
          'payments': paymentPayloads,
          'transacted_at': now.toIso8601String(),
          'client_created_at': now.toIso8601String(),
        },
      );

      if (cart.heldOrderUuid != null) {
        await (_db.delete(
          _db.localOrders,
        )..where((row) => row.uuid.equals(cart.heldOrderUuid!))).go();
      }
    });

    final printQueued = await _enqueuePrint(saleUuid);
    return CheckoutOutcome(sale: sale, offline: true, printQueued: printQueued);
  }

  List<ProofUploadSeed> _proofSeeds(
    List<LocalPaymentDraft> drafts,
    List<String> paymentKeys,
    SaleRecord sale,
  ) => matchProofUploads(
    saleUuid: sale.uuid,
    drafts: drafts,
    paymentKeys: paymentKeys,
    payments: sale.payments,
  );

  Future<bool> _saveAndQueue(
    SaleRecord sale, {
    List<ProofUploadSeed> proofs = const [],
  }) async {
    await _db.transaction(() async {
      await _insertSale(sale, synced: true);
      await _proofs.enqueueAll(proofs);
    });
    final terminal = _terminalCodeFromReceipt(sale.receiptNumber);
    if (terminal != null) {
      await _receipts.alignFromServerReceipt(sale.receiptNumber, terminal);
    }
    return _enqueuePrint(sale.uuid);
  }

  Future<void> _discardHeldOrder(String? uuid) async {
    if (uuid == null) return;
    await (_db.delete(
      _db.localOrders,
    )..where((row) => row.uuid.equals(uuid))).go();
  }

  String? _terminalCodeFromReceipt(String receiptNumber) {
    final parts = receiptNumber.split('-');
    if (parts.length < 4) return null;
    return parts[parts.length - 2];
  }

  Future<void> _insertSale(
    SaleRecord sale, {
    required bool synced,
    String? localOrderUuid,
    List<Map<String, dynamic>>? payments,
  }) async {
    await (_db.delete(
      _db.localSales,
    )..where((row) => row.uuid.equals(sale.uuid))).go();

    await _db
        .into(_db.localSales)
        .insert(
          LocalSalesCompanion.insert(
            uuid: sale.uuid,
            receiptNumber: sale.receiptNumber,
            orderUuid: Value(localOrderUuid),
            serverOrderUuid: Value(sale.orderUuid),
            sourceOrderVersion: Value(sale.sourceOrderVersion ?? 0),
            origin: Value(sale.origin),
            orderType: sale.orderType,
            tableNumber: Value(sale.tableNumber),
            lifecycleStatus: Value(sale.lifecycleStatus),
            paymentStatus: Value(sale.paymentStatus),
            subtotal: sale.subtotal,
            itemDiscountTotal: Value(sale.itemDiscountTotal),
            transactionDiscountTotal: Value(sale.transactionDiscountTotal),
            discountTotal: Value(sale.discountTotal),
            netSubtotal: Value(
              sale.subtotal -
                  sale.itemDiscountTotal -
                  sale.transactionDiscountTotal,
            ),
            serviceCharge: Value(sale.serviceCharge),
            taxTotal: Value(sale.taxTotal),
            total: sale.total,
            confirmedAmount: Value(sale.confirmedAmount),
            awaitingAmount: Value(sale.awaitingAmount),
            refundedAmount: Value(sale.refundedAmount),
            shiftUuid: Value(sale.shiftUuid),
            cashierName: Value(sale.cashierName),
            notes: Value(sale.notes),
            synced: Value(synced),
            transactedAt: sale.transactedAt,
            createdAt: sale.createdAt ?? DateTime.now(),
          ),
        );

    for (final item in sale.items) {
      await _db
          .into(_db.saleItems)
          .insert(
            SaleItemsCompanion.insert(
              saleUuid: sale.uuid,
              productUuid: item.productUuid ?? '',
              productName: item.productName,
              variantName: Value(item.variantName),
              addonsJson: Value(
                jsonEncode(
                  item.addonsSummary == null
                      ? const <dynamic>[]
                      : [
                          {'uuid': '', 'name': item.addonsSummary, 'price': 0},
                        ],
                ),
              ),
              unitPrice: item.unitPrice,
              quantity: item.quantity,
              itemDiscount: Value(item.discountAmount),
              lineSubtotal: Value(item.unitPrice * item.quantity),
              lineTotal: Value(item.lineTotal),
            ),
          );
    }

    if (payments != null) {
      for (final payment in payments) {
        await _db
            .into(_db.salePayments)
            .insert(
              SalePaymentsCompanion.insert(
                saleUuid: sale.uuid,
                paymentUuid: Value(asStringOrNull(payment['payment_uuid'])),
                method: asStringOr(payment['method'], 'cash'),
                amount: asIntOr(payment['amount'], 0),
                tenderedAmount: Value(asIntOrNull(payment['tendered_amount'])),
                changeAmount: Value(asIntOr(payment['change_amount'], 0)),
                verifiedAmount: Value(
                  asStringOr(payment['status'], '') == 'confirmed'
                      ? asIntOr(payment['amount'], 0)
                      : null,
                ),
                status: asStringOr(payment['status'], 'confirmed'),
                providerReference: Value(
                  asStringOrNull(payment['provider_reference']),
                ),
                idempotencyKey: Value(
                  asStringOrNull(payment['idempotency_key']),
                ),
                notes: Value(asStringOrNull(payment['notes'])),
                createdAt: DateTime.now(),
                confirmedAt: Value(
                  asStringOr(payment['status'], '') == 'confirmed'
                      ? DateTime.now()
                      : null,
                ),
              ),
            );
      }
      return;
    }

    for (final payment in sale.payments) {
      await _db
          .into(_db.salePayments)
          .insert(
            SalePaymentsCompanion.insert(
              saleUuid: sale.uuid,
              paymentUuid: Value(payment.uuid),
              method: payment.method,
              amount: payment.amount,
              tenderedAmount: Value(payment.tenderedAmount),
              changeAmount: Value(payment.changeAmount),
              verifiedAmount: Value(
                payment.isConfirmed ? payment.amount : null,
              ),
              status: payment.status,
              providerReference: Value(payment.providerReference),
              idempotencyKey: Value(payment.idempotencyKey),
              notes: Value(payment.notes),
              createdAt: payment.recordedAt ?? DateTime.now(),
              confirmedAt: Value(
                payment.isConfirmed
                    ? payment.recordedAt ?? DateTime.now()
                    : null,
              ),
            ),
          );
    }
  }

  Future<bool> _enqueuePrint(String saleUuid) async {
    try {
      return await _db.transaction(() async {
        final existing =
            await (_db.select(_db.printJobs)
                  ..where((row) => row.saleUuid.equals(saleUuid))
                  ..limit(1))
                .getSingleOrNull();
        if (existing != null) return false;
        await _db
            .into(_db.printJobs)
            .insert(
              PrintJobsCompanion.insert(
                saleUuid: saleUuid,
                createdAt: DateTime.now(),
              ),
            );
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _pricingSnapshot(
    PricingResult pricing,
    PricingConfig config,
    DateTime now,
  ) {
    final snapshot = pricing.toSnapshot(config);
    return {
      'config': snapshot['config'],
      'lines': snapshot['lines'],
      'calculated_at': now.toIso8601String(),
    };
  }

  String _paymentStatus({
    required int total,
    required int confirmed,
    required int awaiting,
  }) {
    if (total == 0 || confirmed >= total) return 'paid';
    if (awaiting > 0) return 'awaiting_verification';
    if (confirmed > 0) return 'partially_paid';
    return 'unpaid';
  }

  Future<SaleRecord?> byUuid(String uuid) async {
    final row = await (_db.select(
      _db.localSales,
    )..where((sale) => sale.uuid.equals(uuid))).getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  Future<List<SaleRecord>> recent({int limit = 50}) async {
    final rows =
        await (_db.select(_db.localSales)
              ..orderBy([(sale) => OrderingTerm.desc(sale.transactedAt)])
              ..limit(limit))
            .get();
    return rows.map(_toRecord).toList(growable: false);
  }

  Future<SaleRecord?> fetchRemote(String uuid) async {
    try {
      final result = await _api.get('sales/$uuid');
      return SaleRecord.fromServer(asMap(result.data));
    } on AppException catch (error) {
      if (error.code == 'NOT_FOUND' || error.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Used by sync pull and payment verification to replace a locally cached
  /// sale with the authoritative server snapshot.
  Future<void> saveRemoteSale(SaleRecord sale) async {
    await _db.transaction(() async {
      await _insertSale(sale, synced: true);
    });
  }

  Future<SaleRecord> _hydrate(LocalSale row) async {
    final items =
        await (_db.select(_db.saleItems)
              ..where((item) => item.saleUuid.equals(row.uuid))
              ..orderBy([(item) => OrderingTerm.asc(item.id)]))
            .get();
    final payments =
        await (_db.select(_db.salePayments)
              ..where((item) => item.saleUuid.equals(row.uuid))
              ..orderBy([(item) => OrderingTerm.asc(item.id)]))
            .get();

    return _toRecord(row).copyWith(
      items: items
          .map(
            (item) => SaleItemRecord(
              productName: item.productName,
              productUuid: item.productUuid.isEmpty ? null : item.productUuid,
              variantName: item.variantName,
              addonsSummary: _addonSummary(item.addonsJson),
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              discountAmount: item.itemDiscount,
              lineTotal: item.lineTotal,
            ),
          )
          .toList(growable: false),
      payments: payments
          .map(
            (payment) => SalePaymentRecord(
              uuid: payment.paymentUuid,
              method: payment.method,
              amount: payment.amount,
              tenderedAmount: payment.tenderedAmount,
              changeAmount: payment.changeAmount ?? 0,
              status: payment.status,
              providerReference: payment.providerReference,
              idempotencyKey: payment.idempotencyKey,
              notes: payment.notes,
              recordedAt: payment.createdAt,
            ),
          )
          .toList(growable: false),
    );
  }

  String? _addonSummary(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) return null;
      final names = decoded
          .whereType<Map>()
          .map((item) => item['name'])
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .join(', ');
      return names.isEmpty ? null : names;
    } catch (_) {
      return null;
    }
  }

  SaleRecord _toRecord(LocalSale row) {
    return SaleRecord(
      uuid: row.uuid,
      receiptNumber: row.receiptNumber,
      orderUuid: row.serverOrderUuid ?? row.orderUuid,
      sourceOrderVersion: row.sourceOrderVersion == 0
          ? null
          : row.sourceOrderVersion,
      origin: row.origin,
      orderType: row.orderType,
      tableNumber: row.tableNumber,
      lifecycleStatus: row.lifecycleStatus,
      paymentStatus: row.paymentStatus,
      subtotal: row.subtotal,
      itemDiscountTotal: row.itemDiscountTotal,
      transactionDiscountTotal: row.transactionDiscountTotal,
      discountTotal: row.discountTotal,
      serviceCharge: row.serviceCharge,
      taxTotal: row.taxTotal,
      total: row.total,
      confirmedAmount: row.confirmedAmount,
      awaitingAmount: row.awaitingAmount,
      outstandingAmount: (row.total - row.confirmedAmount).clamp(0, row.total),
      refundedAmount: row.refundedAmount,
      shiftUuid: row.shiftUuid,
      cashierName: row.cashierName,
      notes: row.notes,
      synced: row.synced,
      transactedAt: row.transactedAt,
      createdAt: row.createdAt,
    );
  }
}
