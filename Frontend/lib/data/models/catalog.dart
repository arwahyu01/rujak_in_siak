import '../../core/pricing/pricing_calculator.dart';
import '../../core/utils/json_utils.dart';
import 'auth.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.uuid,
    required this.name,
    this.sortOrder = 0,
    this.isActive = true,
    this.updatedAt,
  });

  final String uuid;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime? updatedAt;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Kategori'),
      sortOrder: asIntOr(json['sort_order'], 0),
      isActive: asBool(json['is_active'], true),
      updatedAt: asDate(json['updated_at']),
    );
  }
}

class CatalogVariant {
  const CatalogVariant({
    required this.uuid,
    required this.name,
    this.sku,
    this.priceDelta = 0,
    this.isActive = true,
  });

  final String uuid;
  final String name;
  final String? sku;
  final int priceDelta;
  final bool isActive;

  factory CatalogVariant.fromJson(Map<String, dynamic> json) {
    return CatalogVariant(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Varian'),
      sku: asStringOrNull(json['sku']),
      priceDelta: asIntOr(json['price_delta'], 0),
      isActive: asBool(json['is_active'], true),
    );
  }
}

class CatalogAddon {
  const CatalogAddon({
    required this.uuid,
    required this.name,
    this.price = 0,
    this.isActive = true,
  });

  final String uuid;
  final String name;
  final int price;
  final bool isActive;

  factory CatalogAddon.fromJson(Map<String, dynamic> json) {
    return CatalogAddon(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Tambahan'),
      price: asIntOr(json['price'], 0),
      isActive: asBool(json['is_active'], true),
    );
  }
}

class CatalogProduct {
  const CatalogProduct({
    required this.uuid,
    required this.name,
    this.sku = '',
    this.barcode,
    this.description,
    this.unit = 'pcs',
    this.price = 0,
    this.taxRateBasisPoints = 0,
    this.isActive = true,
    this.isAvailable = true,
    this.imageUrl,
    this.categoryUuid,
    this.categoryName,
    this.variants = const [],
    this.addons = const [],
    this.updatedAt,
  });

  final String uuid;
  final String name;
  final String sku;
  final String? barcode;
  final String? description;
  final String unit;
  final int price;
  final int taxRateBasisPoints;
  final bool isActive;
  final bool isAvailable;
  final String? imageUrl;
  final String? categoryUuid;
  final String? categoryName;
  final List<CatalogVariant> variants;
  final List<CatalogAddon> addons;
  final DateTime? updatedAt;

  /// Products without a configured price (e.g. prasmanan items) never appear
  /// as sellable items, even if the backend still flags them as available.
  bool get sellable => isActive && isAvailable && price > 0;

  List<CatalogVariant> get activeVariants =>
      variants.where((variant) => variant.isActive).toList(growable: false);

  List<CatalogAddon> get activeAddons =>
      addons.where((addon) => addon.isActive).toList(growable: false);

  CatalogVariant? variant(String uuid) {
    for (final item in variants) {
      if (item.uuid == uuid) return item;
    }
    return null;
  }

  int unitPrice({String? variantUuid, Iterable<String> addonUuids = const []}) {
    var value = price;
    final selected = variantUuid == null ? null : variant(variantUuid);
    if (selected != null) value += selected.priceDelta;
    for (final addon in addons) {
      if (addonUuids.contains(addon.uuid)) value += addon.price;
    }
    return value;
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    final category = asMapOrNull(json['category']);
    return CatalogProduct(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Produk'),
      sku: asStringOr(json['sku'], ''),
      barcode: asStringOrNull(json['barcode']),
      description: asStringOrNull(json['description']),
      unit: asStringOr(json['unit'], 'pcs'),
      price: asIntOr(json['price'], 0),
      taxRateBasisPoints: asIntOr(json['tax_rate_basis_points'], 0),
      isActive: asBool(json['is_active'], true),
      isAvailable: asBool(json['is_available'], true),
      imageUrl: asStringOrNull(json['image_url']),
      categoryUuid: category == null
          ? asStringOrNull(json['category_uuid'])
          : asStringOrNull(category['uuid']),
      categoryName: category == null ? null : asStringOrNull(category['name']),
      variants: asMapList(
        json['variants'],
      ).map(CatalogVariant.fromJson).toList(growable: false),
      addons: asMapList(
        json['addons'],
      ).map(CatalogAddon.fromJson).toList(growable: false),
      updatedAt: asDate(json['updated_at']),
    );
  }
}

class AppBusiness {
  const AppBusiness({
    required this.uuid,
    required this.name,
    this.address,
    this.phone,
    this.currency = 'IDR',
    this.timezone = 'Asia/Jakarta',
  });

  final String uuid;
  final String name;
  final String? address;
  final String? phone;
  final String currency;
  final String timezone;

  factory AppBusiness.fromJson(Map<String, dynamic> json) {
    return AppBusiness(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'RUJAK.IN.SIAK'),
      address: asStringOrNull(json['address']),
      phone: asStringOrNull(json['phone']),
      currency: asStringOr(json['currency'], 'IDR'),
      timezone: asStringOr(json['timezone'], 'Asia/Jakarta'),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'address': address,
    'phone': phone,
    'currency': currency,
    'timezone': timezone,
  };
}

class AppOutlet {
  const AppOutlet({
    required this.uuid,
    required this.name,
    required this.code,
    this.address,
    this.phone,
  });

  final String uuid;
  final String name;
  final String code;
  final String? address;
  final String? phone;

  factory AppOutlet.fromJson(Map<String, dynamic> json) {
    return AppOutlet(
      uuid: asStringOr(json['uuid'], ''),
      name: asStringOr(json['name'], 'Outlet'),
      code: asStringOr(json['code'], 'OUT'),
      address: asStringOrNull(json['address']),
      phone: asStringOrNull(json['phone']),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'code': code,
    'address': address,
    'phone': phone,
  };
}

class RemoteShift {
  const RemoteShift({
    required this.uuid,
    required this.status,
    this.openingCash = 0,
    this.openedAt,
    this.expectedCash,
    this.notes,
  });

  final String uuid;
  final String status;
  final int openingCash;
  final DateTime? openedAt;
  final int? expectedCash;
  final String? notes;

  bool get isOpen => status == 'open';

  factory RemoteShift.fromJson(Map<String, dynamic> json) {
    return RemoteShift(
      uuid: asStringOr(json['uuid'], ''),
      status: asStringOr(json['status'], 'open'),
      openingCash: asIntOr(json['opening_cash'], 0),
      openedAt: asDate(json['opened_at']),
      expectedCash: asIntOrNull(json['expected_cash']),
      notes: asStringOrNull(json['opening_notes']),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'status': status,
    'opening_cash': openingCash,
    'opened_at': openedAt?.toIso8601String(),
    'expected_cash': expectedCash,
    'opening_notes': notes,
  };
}

class SyncLimits {
  const SyncLimits({
    this.protocolVersion = 1,
    this.schemaVersion = 1,
    this.maxBatchEvents = 50,
    this.maxBatchBytes = 1048576,
    this.pullLimit = 500,
  });

  final int protocolVersion;
  final int schemaVersion;
  final int maxBatchEvents;
  final int maxBatchBytes;
  final int pullLimit;

  factory SyncLimits.fromJson(Map<String, dynamic> json) {
    return SyncLimits(
      protocolVersion: asIntOr(json['protocol_version'], 1),
      schemaVersion: asIntOr(json['schema_version'], 1),
      maxBatchEvents: asIntOr(json['max_batch_events'], 50),
      maxBatchBytes: asIntOr(json['max_batch_bytes'], 1048576),
      pullLimit: asIntOr(json['pull_limit'], 500),
    );
  }

  Map<String, dynamic> toJson() => {
    'protocol_version': protocolVersion,
    'schema_version': schemaVersion,
    'max_batch_events': maxBatchEvents,
    'max_batch_bytes': maxBatchBytes,
    'pull_limit': pullLimit,
  };
}

class BootstrapData {
  const BootstrapData({
    required this.business,
    required this.outlet,
    required this.user,
    required this.categories,
    required this.products,
    required this.pricingConfig,
    this.paymentMethods = const ['cash', 'qris', 'transfer', 'ewallet'],
    this.orderTypes = const ['dine_in', 'take_away', 'delivery'],
    this.receiptNumberFormat = 'RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}',
    this.offlineLeaseMaxHours = 72,
    this.offlineCatalogMaxAgeHours = 72,
    this.syncLimits = const SyncLimits(),
    this.openShift,
    this.cursor,
    this.catalogVersion,
    this.serverTime,
  });

  final AppBusiness business;
  final AppOutlet outlet;
  final AppUser user;
  final List<CatalogCategory> categories;
  final List<CatalogProduct> products;
  final PricingConfig pricingConfig;
  final List<String> paymentMethods;
  final List<String> orderTypes;
  final String receiptNumberFormat;
  final int offlineLeaseMaxHours;
  final int offlineCatalogMaxAgeHours;
  final SyncLimits syncLimits;
  final RemoteShift? openShift;
  final String? cursor;
  final String? catalogVersion;
  final DateTime? serverTime;

  String get currency => business.currency;

  BootstrapData copyWith({
    AppBusiness? business,
    AppOutlet? outlet,
    AppUser? user,
    List<CatalogCategory>? categories,
    List<CatalogProduct>? products,
    PricingConfig? pricingConfig,
    List<String>? paymentMethods,
    List<String>? orderTypes,
    String? receiptNumberFormat,
    int? offlineLeaseMaxHours,
    int? offlineCatalogMaxAgeHours,
    SyncLimits? syncLimits,
    RemoteShift? openShift,
    String? cursor,
    String? catalogVersion,
    DateTime? serverTime,
  }) {
    return BootstrapData(
      business: business ?? this.business,
      outlet: outlet ?? this.outlet,
      user: user ?? this.user,
      categories: categories ?? this.categories,
      products: products ?? this.products,
      pricingConfig: pricingConfig ?? this.pricingConfig,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      orderTypes: orderTypes ?? this.orderTypes,
      receiptNumberFormat: receiptNumberFormat ?? this.receiptNumberFormat,
      offlineLeaseMaxHours: offlineLeaseMaxHours ?? this.offlineLeaseMaxHours,
      offlineCatalogMaxAgeHours:
          offlineCatalogMaxAgeHours ?? this.offlineCatalogMaxAgeHours,
      syncLimits: syncLimits ?? this.syncLimits,
      openShift: openShift ?? this.openShift,
      cursor: cursor ?? this.cursor,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      serverTime: serverTime ?? this.serverTime,
    );
  }

  CatalogProduct? product(String uuid) {
    for (final item in products) {
      if (item.uuid == uuid) return item;
    }
    return null;
  }

  factory BootstrapData.fromJson(Map<String, dynamic> json) {
    final catalog = asMap(json['catalog']);
    final config = asMap(json['config']);
    final sync = asMap(json['sync']);
    final syncConfig = asMap(config['sync']);
    return BootstrapData(
      business: AppBusiness.fromJson(asMap(json['business'])),
      outlet: AppOutlet.fromJson(asMap(json['outlet'])),
      user: AppUser.fromJson(asMap(json['user'])),
      categories: asMapList(
        catalog['categories'],
      ).map(CatalogCategory.fromJson).toList(growable: false),
      products: asMapList(
        catalog['products'],
      ).map(CatalogProduct.fromJson).toList(growable: false),
      pricingConfig: PricingConfig.fromJson(config),
      paymentMethods: asStringList(config['payment_methods']),
      orderTypes: asStringList(config['order_types']),
      receiptNumberFormat: asStringOr(
        config['receipt_number_format'],
        'RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}',
      ),
      offlineLeaseMaxHours: asIntOr(config['offline_lease_max_hours'], 72),
      offlineCatalogMaxAgeHours: asIntOr(
        catalog['offline_catalog_max_age_hours'],
        72,
      ),
      syncLimits: SyncLimits.fromJson(syncConfig),
      openShift: json['open_shift'] == null
          ? null
          : RemoteShift.fromJson(asMap(json['open_shift'])),
      cursor: asStringOrNull(sync['cursor']),
      catalogVersion: asStringOrNull(catalog['catalog_version']),
      serverTime: asDate(sync['server_time']),
    );
  }

  Map<String, dynamic> toJson() => {
    'business': business.toJson(),
    'outlet': outlet.toJson(),
    'user': user.toJson(),
    'catalog': {
      'categories': categories
          .map(
            (item) => {
              'uuid': item.uuid,
              'name': item.name,
              'sort_order': item.sortOrder,
              'is_active': item.isActive,
              'updated_at': item.updatedAt?.toIso8601String(),
            },
          )
          .toList(),
      'products': products
          .map(
            (item) => {
              'uuid': item.uuid,
              'sku': item.sku,
              'barcode': item.barcode,
              'name': item.name,
              'description': item.description,
              'unit': item.unit,
              'price': item.price,
              'tax_rate_basis_points': item.taxRateBasisPoints,
              'is_active': item.isActive,
              'is_available': item.isAvailable,
              'image_url': item.imageUrl,
              'category': item.categoryUuid == null
                  ? null
                  : {'uuid': item.categoryUuid, 'name': item.categoryName},
              'variants': item.variants
                  .map(
                    (variant) => {
                      'uuid': variant.uuid,
                      'name': variant.name,
                      'sku': variant.sku,
                      'price_delta': variant.priceDelta,
                      'is_active': variant.isActive,
                    },
                  )
                  .toList(),
              'addons': item.addons
                  .map(
                    (addon) => {
                      'uuid': addon.uuid,
                      'name': addon.name,
                      'price': addon.price,
                      'is_active': addon.isActive,
                    },
                  )
                  .toList(),
              'updated_at': item.updatedAt?.toIso8601String(),
            },
          )
          .toList(),
      'catalog_version': catalogVersion,
      'offline_catalog_max_age_hours': offlineCatalogMaxAgeHours,
    },
    'config': {
      'currency': business.currency,
      'timezone': business.timezone,
      'tax': {
        'enabled': pricingConfig.taxEnabled,
        'rate_basis_points': pricingConfig.taxRateBasisPoints,
        'includes_service_charge': pricingConfig.taxIncludesServiceCharge,
      },
      'service_charge': {
        'enabled': pricingConfig.serviceChargeEnabled,
        'rate_basis_points': pricingConfig.serviceChargeRateBasisPoints,
      },
      'receipt_number_format': receiptNumberFormat,
      'payment_methods': paymentMethods,
      'order_types': orderTypes,
      'offline_lease_max_hours': offlineLeaseMaxHours,
      'sync': syncLimits.toJson(),
    },
    'open_shift': openShift?.toJson(),
    'sync': {'cursor': cursor, 'server_time': serverTime?.toIso8601String()},
  };
}
