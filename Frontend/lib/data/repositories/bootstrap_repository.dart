import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/config/app_config.dart';
import '../../core/database/app_database.dart'
    hide CatalogAddon, CatalogCategory, CatalogProduct, CatalogVariant;
import '../../core/network/api_client.dart';
import '../../core/utils/json_utils.dart';
import '../models/catalog.dart';

enum CatalogFreshness { missing, fresh, warning, expired }

class CatalogSnapshot {
  const CatalogSnapshot({
    required this.data,
    required this.catalogSyncedAt,
    required this.freshness,
  });

  final BootstrapData? data;
  final DateTime? catalogSyncedAt;
  final CatalogFreshness freshness;

  bool get hasData => data != null;

  bool get offlineCheckoutAllowed => freshness != CatalogFreshness.expired;

  Duration? get age {
    if (catalogSyncedAt == null) return null;
    return DateTime.now().difference(catalogSyncedAt!);
  }
}

class BootstrapRepository {
  BootstrapRepository(this._db, this._api);

  static const _metaKey = 'bootstrap_meta';

  final AppDatabase _db;
  final ApiClient _api;

  Future<CatalogSnapshot> loadSnapshot() async {
    final meta = await _db.setting(_metaKey);
    final syncState = await (_db.select(
      _db.syncState,
    )..where((row) => row.id.equals(1))).getSingleOrNull();
    final catalogSyncedAt = syncState?.catalogSyncedAt;

    if (meta == null || meta.isEmpty) {
      return CatalogSnapshot(
        data: null,
        catalogSyncedAt: catalogSyncedAt,
        freshness: CatalogFreshness.missing,
      );
    }

    final decoded = jsonDecode(meta);
    final json = asMap(decoded);
    if (json.isEmpty) {
      return CatalogSnapshot(
        data: null,
        catalogSyncedAt: catalogSyncedAt,
        freshness: CatalogFreshness.missing,
      );
    }

    json['catalog'] = {
      ...asMap(json['catalog']),
      'categories': const <dynamic>[],
      'products': const <dynamic>[],
    };

    final base = BootstrapData.fromJson(json);
    final categories = await _loadCategories();
    final products = await _loadProducts();

    final staleSince = catalogSyncedAt ?? base.serverTime;
    final freshness = _freshness(staleSince);

    return CatalogSnapshot(
      data: base.copyWith(
        categories: categories,
        products: products,
        openShift: base.openShift,
        cursor: syncState?.cursor ?? base.cursor,
      ),
      catalogSyncedAt: catalogSyncedAt,
      freshness: freshness,
    );
  }

  Future<CatalogSnapshot> refresh() async {
    final result = await _api.get('sync/bootstrap');
    final data = BootstrapData.fromJson(asMap(result.data));
    if (data.products.isEmpty) {
      // A bootstrap without products is still valid (new outlet), but never
      // replace a previously working catalog with an empty transient response.
      final existing = await _db.setting(_metaKey);
      if (existing != null && existing.isNotEmpty) {
        final snapshot = await loadSnapshot();
        if (snapshot.data != null && snapshot.data!.products.isNotEmpty) {
          return snapshot;
        }
      }
    }

    await _writeBootstrap(data);
    return loadSnapshot();
  }

  Future<void> _writeBootstrap(BootstrapData data) async {
    final now = DateTime.now();
    final meta = data.toJson()..remove('catalog');

    await _db.transaction(() async {
      await _db.delete(_db.catalogAddons).go();
      await _db.delete(_db.catalogVariants).go();
      await _db.delete(_db.catalogProducts).go();
      await _db.delete(_db.catalogCategories).go();

      for (final category in data.categories) {
        await _db
            .into(_db.catalogCategories)
            .insert(
              CatalogCategoriesCompanion.insert(
                uuid: category.uuid,
                name: category.name,
                sortOrder: Value(category.sortOrder),
                updatedAt: Value(category.updatedAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      for (final product in data.products) {
        await _db
            .into(_db.catalogProducts)
            .insert(
              CatalogProductsCompanion.insert(
                uuid: product.uuid,
                sku: Value(product.sku),
                barcode: Value(product.barcode),
                name: product.name,
                description: Value(product.description),
                unit: Value(product.unit),
                price: Value(product.price),
                taxRateBasisPoints: Value(product.taxRateBasisPoints),
                isActive: Value(product.isActive),
                isAvailable: Value(product.isAvailable),
                imageUrl: Value(product.imageUrl),
                categoryUuid: Value(
                  data.categories.any((c) => c.uuid == product.categoryUuid)
                      ? product.categoryUuid
                      : null,
                ),
                updatedAt: Value(product.updatedAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
        await _replaceVariants(product);
        await _replaceAddons(product);
      }

      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: _metaKey, value: jsonEncode(meta)),
          );

      await _db
          .into(_db.syncState)
          .insertOnConflictUpdate(
            SyncStateCompanion(
              id: const Value(1),
              cursor: Value(data.cursor),
              catalogSyncedAt: Value(now),
              catalogVersion: Value(data.catalogVersion),
              lastServerTime: Value(data.serverTime?.toIso8601String()),
            ),
          );

      final openShift = data.openShift;
      if (openShift != null && openShift.uuid.isNotEmpty) {
        // The server shift always wins over a stale local copy. Existing cash
        // movements and sales keep their own shift UUID.
        await _db
            .into(_db.localShifts)
            .insertOnConflictUpdate(
              LocalShiftsCompanion(
                uuid: Value(openShift.uuid),
                status: Value(openShift.status),
                openingCash: Value(openShift.openingCash),
                openingNotes: Value(openShift.notes),
                openedAt: Value(openShift.openedAt ?? now),
                expectedCash: Value(openShift.expectedCash),
                synced: const Value(true),
                closeEpoch: Value(openShift.closeEpoch),
                isClosing: Value(
                  openShift.isClosing || openShift.status == 'closing',
                ),
                openedByName: Value(openShift.openedByName),
                openedDeviceName: Value(openShift.openedDeviceName),
                canFinalize: Value(openShift.canFinalize),
                pendingDevicesJson: Value(
                  jsonEncode(
                    openShift.pendingDevices
                        .map((device) => device.toJson())
                        .toList(),
                  ),
                ),
                serverSummaryJson: Value(
                  openShift.serverSummary == null
                      ? null
                      : jsonEncode(openShift.serverSummary!.toJson()),
                ),
              ),
            );
      } else {
        // No active outlet shift on the server. A synced local shift must not
        // keep accepting transactions; an unsynced one stays until pushed.
        await (_db.update(_db.localShifts)..where(
              (row) =>
                  row.status.isIn(const ['open', 'closing']) &
                  row.synced.equals(true),
            ))
            .write(
              const LocalShiftsCompanion(
                status: Value('closed_remote'),
                isClosing: Value(false),
                canFinalize: Value(false),
                pendingDevicesJson: Value('[]'),
              ),
            );
      }
    });
  }

  Future<List<CatalogCategory>> _loadCategories() async {
    final rows =
        await (_db.select(_db.catalogCategories)..orderBy([
              (row) => OrderingTerm(expression: row.sortOrder),
              (row) => OrderingTerm(expression: row.name),
            ]))
            .get();
    return rows
        .map(
          (row) => CatalogCategory(
            uuid: row.uuid,
            name: row.name,
            sortOrder: row.sortOrder,
            updatedAt: row.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  Future<List<CatalogProduct>> _loadProducts() async {
    final products = await _db.select(_db.catalogProducts).get();
    final variants = await _db.select(_db.catalogVariants).get();
    final addons = await _db.select(_db.catalogAddons).get();
    final categories = await _db.select(_db.catalogCategories).get();
    final categoryNames = {
      for (final category in categories) category.uuid: category.name,
    };

    final variantsByProduct = <String, List<CatalogVariant>>{};
    for (final row in variants) {
      variantsByProduct
          .putIfAbsent(row.productUuid, () => [])
          .add(
            CatalogVariant(
              uuid: row.uuid,
              name: row.name,
              sku: row.sku,
              priceDelta: row.priceDelta,
              isActive: row.isActive,
            ),
          );
    }
    final addonsByProduct = <String, List<CatalogAddon>>{};
    for (final row in addons) {
      addonsByProduct
          .putIfAbsent(row.productUuid, () => [])
          .add(
            CatalogAddon(
              uuid: row.uuid,
              name: row.name,
              price: row.price,
              isActive: row.isActive,
            ),
          );
    }

    final result = products
        .map(
          (row) => CatalogProduct(
            uuid: row.uuid,
            sku: row.sku,
            barcode: row.barcode,
            name: row.name,
            description: row.description,
            unit: row.unit,
            price: row.price,
            taxRateBasisPoints: row.taxRateBasisPoints,
            isActive: row.isActive,
            isAvailable: row.isAvailable,
            imageUrl: row.imageUrl,
            categoryUuid: row.categoryUuid,
            categoryName: row.categoryUuid == null
                ? null
                : categoryNames[row.categoryUuid],
            variants: variantsByProduct[row.uuid] ?? const [],
            addons: addonsByProduct[row.uuid] ?? const [],
            updatedAt: row.updatedAt,
          ),
        )
        .toList();
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<void> importProduct(Map<String, dynamic> payload) async {
    final product = CatalogProduct.fromJson(payload);
    if (product.uuid.isEmpty) return;
    await _db.transaction(() async {
      final categoryUuid = product.categoryUuid;
      if (categoryUuid != null && product.categoryName != null) {
        await _db
            .into(_db.catalogCategories)
            .insertOnConflictUpdate(
              CatalogCategoriesCompanion.insert(
                uuid: categoryUuid,
                name: product.categoryName!,
              ),
            );
      }
      await _db
          .into(_db.catalogProducts)
          .insertOnConflictUpdate(
            CatalogProductsCompanion.insert(
              uuid: product.uuid,
              sku: Value(product.sku),
              barcode: Value(product.barcode),
              name: product.name,
              description: Value(product.description),
              unit: Value(product.unit),
              price: Value(product.price),
              taxRateBasisPoints: Value(product.taxRateBasisPoints),
              isActive: Value(product.isActive),
              isAvailable: Value(product.isAvailable),
              imageUrl: Value(product.imageUrl),
              categoryUuid: Value(categoryUuid),
              updatedAt: Value(product.updatedAt),
            ),
          );
      await _replaceVariants(product);
      await _replaceAddons(product);
    });
  }

  Future<void> importCategory(Map<String, dynamic> payload) async {
    final category = CatalogCategory.fromJson(payload);
    if (category.uuid.isEmpty) return;
    await _db
        .into(_db.catalogCategories)
        .insertOnConflictUpdate(
          CatalogCategoriesCompanion.insert(
            uuid: category.uuid,
            name: category.name,
            sortOrder: Value(category.sortOrder),
            updatedAt: Value(category.updatedAt),
          ),
        );
  }

  Future<void> _replaceVariants(CatalogProduct product) async {
    await (_db.delete(
      _db.catalogVariants,
    )..where((row) => row.productUuid.equals(product.uuid))).go();
    for (final variant in product.variants) {
      await _db
          .into(_db.catalogVariants)
          .insert(
            CatalogVariantsCompanion.insert(
              uuid: variant.uuid,
              productUuid: product.uuid,
              name: variant.name,
              sku: Value(variant.sku),
              priceDelta: Value(variant.priceDelta),
              isActive: Value(variant.isActive),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  Future<void> _replaceAddons(CatalogProduct product) async {
    await (_db.delete(
      _db.catalogAddons,
    )..where((row) => row.productUuid.equals(product.uuid))).go();
    for (final addon in product.addons) {
      await _db
          .into(_db.catalogAddons)
          .insert(
            CatalogAddonsCompanion.insert(
              uuid: addon.uuid,
              productUuid: product.uuid,
              name: addon.name,
              price: Value(addon.price),
              isActive: Value(addon.isActive),
            ),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  CatalogFreshness _freshness(DateTime? syncedAt) {
    if (syncedAt == null) return CatalogFreshness.missing;
    final age = DateTime.now().difference(syncedAt);
    if (age > AppConfig.catalogBlockAfter) return CatalogFreshness.expired;
    if (age > AppConfig.catalogWarnAfter) return CatalogFreshness.warning;
    return CatalogFreshness.fresh;
  }
}
