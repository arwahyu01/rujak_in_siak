// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CatalogCategoriesTable extends CatalogCategories
    with TableInfo<$CatalogCategoriesTable, CatalogCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [uuid, name, sortOrder, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  CatalogCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogCategory(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $CatalogCategoriesTable createAlias(String alias) {
    return $CatalogCategoriesTable(attachedDatabase, alias);
  }
}

class CatalogCategory extends DataClass implements Insertable<CatalogCategory> {
  final String uuid;
  final String name;
  final int sortOrder;
  final DateTime? updatedAt;
  const CatalogCategory({
    required this.uuid,
    required this.name,
    required this.sortOrder,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  CatalogCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CatalogCategoriesCompanion(
      uuid: Value(uuid),
      name: Value(name),
      sortOrder: Value(sortOrder),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CatalogCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogCategory(
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  CatalogCategory copyWith({
    String? uuid,
    String? name,
    int? sortOrder,
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => CatalogCategory(
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  CatalogCategory copyWithCompanion(CatalogCategoriesCompanion data) {
    return CatalogCategory(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCategory(')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uuid, name, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogCategory &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class CatalogCategoriesCompanion extends UpdateCompanion<CatalogCategory> {
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const CatalogCategoriesCompanion({
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogCategoriesCompanion.insert({
    required String uuid,
    required String name,
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       name = Value(name);
  static Insertable<CatalogCategory> custom({
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogCategoriesCompanion copyWith({
    Value<String>? uuid,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return CatalogCategoriesCompanion(
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCategoriesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogProductsTable extends CatalogProducts
    with TableInfo<$CatalogProductsTable, CatalogProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pcs'),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxRateBasisPointsMeta =
      const VerificationMeta('taxRateBasisPoints');
  @override
  late final GeneratedColumn<int> taxRateBasisPoints = GeneratedColumn<int>(
    'tax_rate_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryUuidMeta = const VerificationMeta(
    'categoryUuid',
  );
  @override
  late final GeneratedColumn<String> categoryUuid = GeneratedColumn<String>(
    'category_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES catalog_categories (uuid) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    sku,
    barcode,
    name,
    description,
    unit,
    price,
    taxRateBasisPoints,
    isActive,
    isAvailable,
    imageUrl,
    categoryUuid,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('tax_rate_basis_points')) {
      context.handle(
        _taxRateBasisPointsMeta,
        taxRateBasisPoints.isAcceptableOrUnknown(
          data['tax_rate_basis_points']!,
          _taxRateBasisPointsMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('category_uuid')) {
      context.handle(
        _categoryUuidMeta,
        categoryUuid.isAcceptableOrUnknown(
          data['category_uuid']!,
          _categoryUuidMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  CatalogProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogProduct(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      taxRateBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_basis_points'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      categoryUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_uuid'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $CatalogProductsTable createAlias(String alias) {
    return $CatalogProductsTable(attachedDatabase, alias);
  }
}

class CatalogProduct extends DataClass implements Insertable<CatalogProduct> {
  final String uuid;
  final String sku;
  final String? barcode;
  final String name;
  final String? description;
  final String unit;
  final int price;
  final int taxRateBasisPoints;
  final bool isActive;
  final bool isAvailable;
  final String? imageUrl;
  final String? categoryUuid;
  final DateTime? updatedAt;
  const CatalogProduct({
    required this.uuid,
    required this.sku,
    this.barcode,
    required this.name,
    this.description,
    required this.unit,
    required this.price,
    required this.taxRateBasisPoints,
    required this.isActive,
    required this.isAvailable,
    this.imageUrl,
    this.categoryUuid,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['sku'] = Variable<String>(sku);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['unit'] = Variable<String>(unit);
    map['price'] = Variable<int>(price);
    map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints);
    map['is_active'] = Variable<bool>(isActive);
    map['is_available'] = Variable<bool>(isAvailable);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    if (!nullToAbsent || categoryUuid != null) {
      map['category_uuid'] = Variable<String>(categoryUuid);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  CatalogProductsCompanion toCompanion(bool nullToAbsent) {
    return CatalogProductsCompanion(
      uuid: Value(uuid),
      sku: Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      unit: Value(unit),
      price: Value(price),
      taxRateBasisPoints: Value(taxRateBasisPoints),
      isActive: Value(isActive),
      isAvailable: Value(isAvailable),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      categoryUuid: categoryUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryUuid),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CatalogProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogProduct(
      uuid: serializer.fromJson<String>(json['uuid']),
      sku: serializer.fromJson<String>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      unit: serializer.fromJson<String>(json['unit']),
      price: serializer.fromJson<int>(json['price']),
      taxRateBasisPoints: serializer.fromJson<int>(json['taxRateBasisPoints']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      categoryUuid: serializer.fromJson<String?>(json['categoryUuid']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'sku': serializer.toJson<String>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'unit': serializer.toJson<String>(unit),
      'price': serializer.toJson<int>(price),
      'taxRateBasisPoints': serializer.toJson<int>(taxRateBasisPoints),
      'isActive': serializer.toJson<bool>(isActive),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'categoryUuid': serializer.toJson<String?>(categoryUuid),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  CatalogProduct copyWith({
    String? uuid,
    String? sku,
    Value<String?> barcode = const Value.absent(),
    String? name,
    Value<String?> description = const Value.absent(),
    String? unit,
    int? price,
    int? taxRateBasisPoints,
    bool? isActive,
    bool? isAvailable,
    Value<String?> imageUrl = const Value.absent(),
    Value<String?> categoryUuid = const Value.absent(),
    Value<DateTime?> updatedAt = const Value.absent(),
  }) => CatalogProduct(
    uuid: uuid ?? this.uuid,
    sku: sku ?? this.sku,
    barcode: barcode.present ? barcode.value : this.barcode,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    unit: unit ?? this.unit,
    price: price ?? this.price,
    taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
    isActive: isActive ?? this.isActive,
    isAvailable: isAvailable ?? this.isAvailable,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    categoryUuid: categoryUuid.present ? categoryUuid.value : this.categoryUuid,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  CatalogProduct copyWithCompanion(CatalogProductsCompanion data) {
    return CatalogProduct(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      unit: data.unit.present ? data.unit.value : this.unit,
      price: data.price.present ? data.price.value : this.price,
      taxRateBasisPoints: data.taxRateBasisPoints.present
          ? data.taxRateBasisPoints.value
          : this.taxRateBasisPoints,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      categoryUuid: data.categoryUuid.present
          ? data.categoryUuid.value
          : this.categoryUuid,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogProduct(')
          ..write('uuid: $uuid, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('unit: $unit, ')
          ..write('price: $price, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('isActive: $isActive, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('categoryUuid: $categoryUuid, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    sku,
    barcode,
    name,
    description,
    unit,
    price,
    taxRateBasisPoints,
    isActive,
    isAvailable,
    imageUrl,
    categoryUuid,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogProduct &&
          other.uuid == this.uuid &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.name == this.name &&
          other.description == this.description &&
          other.unit == this.unit &&
          other.price == this.price &&
          other.taxRateBasisPoints == this.taxRateBasisPoints &&
          other.isActive == this.isActive &&
          other.isAvailable == this.isAvailable &&
          other.imageUrl == this.imageUrl &&
          other.categoryUuid == this.categoryUuid &&
          other.updatedAt == this.updatedAt);
}

class CatalogProductsCompanion extends UpdateCompanion<CatalogProduct> {
  final Value<String> uuid;
  final Value<String> sku;
  final Value<String?> barcode;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> unit;
  final Value<int> price;
  final Value<int> taxRateBasisPoints;
  final Value<bool> isActive;
  final Value<bool> isAvailable;
  final Value<String?> imageUrl;
  final Value<String?> categoryUuid;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const CatalogProductsCompanion({
    this.uuid = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.unit = const Value.absent(),
    this.price = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.categoryUuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogProductsCompanion.insert({
    required String uuid,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.unit = const Value.absent(),
    this.price = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.categoryUuid = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       name = Value(name);
  static Insertable<CatalogProduct> custom({
    Expression<String>? uuid,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? unit,
    Expression<int>? price,
    Expression<int>? taxRateBasisPoints,
    Expression<bool>? isActive,
    Expression<bool>? isAvailable,
    Expression<String>? imageUrl,
    Expression<String>? categoryUuid,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (unit != null) 'unit': unit,
      if (price != null) 'price': price,
      if (taxRateBasisPoints != null)
        'tax_rate_basis_points': taxRateBasisPoints,
      if (isActive != null) 'is_active': isActive,
      if (isAvailable != null) 'is_available': isAvailable,
      if (imageUrl != null) 'image_url': imageUrl,
      if (categoryUuid != null) 'category_uuid': categoryUuid,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogProductsCompanion copyWith({
    Value<String>? uuid,
    Value<String>? sku,
    Value<String?>? barcode,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? unit,
    Value<int>? price,
    Value<int>? taxRateBasisPoints,
    Value<bool>? isActive,
    Value<bool>? isAvailable,
    Value<String?>? imageUrl,
    Value<String?>? categoryUuid,
    Value<DateTime?>? updatedAt,
    Value<int>? rowid,
  }) {
    return CatalogProductsCompanion(
      uuid: uuid ?? this.uuid,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      price: price ?? this.price,
      taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
      isActive: isActive ?? this.isActive,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryUuid: categoryUuid ?? this.categoryUuid,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (taxRateBasisPoints.present) {
      map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (categoryUuid.present) {
      map['category_uuid'] = Variable<String>(categoryUuid.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogProductsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('unit: $unit, ')
          ..write('price: $price, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('isActive: $isActive, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('categoryUuid: $categoryUuid, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogVariantsTable extends CatalogVariants
    with TableInfo<$CatalogVariantsTable, CatalogVariant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogVariantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productUuidMeta = const VerificationMeta(
    'productUuid',
  );
  @override
  late final GeneratedColumn<String> productUuid = GeneratedColumn<String>(
    'product_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES catalog_products (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priceDeltaMeta = const VerificationMeta(
    'priceDelta',
  );
  @override
  late final GeneratedColumn<int> priceDelta = GeneratedColumn<int>(
    'price_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    productUuid,
    name,
    sku,
    priceDelta,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_variants';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogVariant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('product_uuid')) {
      context.handle(
        _productUuidMeta,
        productUuid.isAcceptableOrUnknown(
          data['product_uuid']!,
          _productUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productUuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('price_delta')) {
      context.handle(
        _priceDeltaMeta,
        priceDelta.isAcceptableOrUnknown(data['price_delta']!, _priceDeltaMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  CatalogVariant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogVariant(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      productUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      priceDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_delta'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $CatalogVariantsTable createAlias(String alias) {
    return $CatalogVariantsTable(attachedDatabase, alias);
  }
}

class CatalogVariant extends DataClass implements Insertable<CatalogVariant> {
  final String uuid;
  final String productUuid;
  final String name;
  final String? sku;
  final int priceDelta;
  final bool isActive;
  const CatalogVariant({
    required this.uuid,
    required this.productUuid,
    required this.name,
    this.sku,
    required this.priceDelta,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['product_uuid'] = Variable<String>(productUuid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['price_delta'] = Variable<int>(priceDelta);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CatalogVariantsCompanion toCompanion(bool nullToAbsent) {
    return CatalogVariantsCompanion(
      uuid: Value(uuid),
      productUuid: Value(productUuid),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      priceDelta: Value(priceDelta),
      isActive: Value(isActive),
    );
  }

  factory CatalogVariant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogVariant(
      uuid: serializer.fromJson<String>(json['uuid']),
      productUuid: serializer.fromJson<String>(json['productUuid']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      priceDelta: serializer.fromJson<int>(json['priceDelta']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'productUuid': serializer.toJson<String>(productUuid),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'priceDelta': serializer.toJson<int>(priceDelta),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CatalogVariant copyWith({
    String? uuid,
    String? productUuid,
    String? name,
    Value<String?> sku = const Value.absent(),
    int? priceDelta,
    bool? isActive,
  }) => CatalogVariant(
    uuid: uuid ?? this.uuid,
    productUuid: productUuid ?? this.productUuid,
    name: name ?? this.name,
    sku: sku.present ? sku.value : this.sku,
    priceDelta: priceDelta ?? this.priceDelta,
    isActive: isActive ?? this.isActive,
  );
  CatalogVariant copyWithCompanion(CatalogVariantsCompanion data) {
    return CatalogVariant(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      productUuid: data.productUuid.present
          ? data.productUuid.value
          : this.productUuid,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      priceDelta: data.priceDelta.present
          ? data.priceDelta.value
          : this.priceDelta,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogVariant(')
          ..write('uuid: $uuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('priceDelta: $priceDelta, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, productUuid, name, sku, priceDelta, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogVariant &&
          other.uuid == this.uuid &&
          other.productUuid == this.productUuid &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.priceDelta == this.priceDelta &&
          other.isActive == this.isActive);
}

class CatalogVariantsCompanion extends UpdateCompanion<CatalogVariant> {
  final Value<String> uuid;
  final Value<String> productUuid;
  final Value<String> name;
  final Value<String?> sku;
  final Value<int> priceDelta;
  final Value<bool> isActive;
  final Value<int> rowid;
  const CatalogVariantsCompanion({
    this.uuid = const Value.absent(),
    this.productUuid = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.priceDelta = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogVariantsCompanion.insert({
    required String uuid,
    required String productUuid,
    required String name,
    this.sku = const Value.absent(),
    this.priceDelta = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       productUuid = Value(productUuid),
       name = Value(name);
  static Insertable<CatalogVariant> custom({
    Expression<String>? uuid,
    Expression<String>? productUuid,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<int>? priceDelta,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (productUuid != null) 'product_uuid': productUuid,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (priceDelta != null) 'price_delta': priceDelta,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogVariantsCompanion copyWith({
    Value<String>? uuid,
    Value<String>? productUuid,
    Value<String>? name,
    Value<String?>? sku,
    Value<int>? priceDelta,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return CatalogVariantsCompanion(
      uuid: uuid ?? this.uuid,
      productUuid: productUuid ?? this.productUuid,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      priceDelta: priceDelta ?? this.priceDelta,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (productUuid.present) {
      map['product_uuid'] = Variable<String>(productUuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (priceDelta.present) {
      map['price_delta'] = Variable<int>(priceDelta.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogVariantsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('priceDelta: $priceDelta, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogAddonsTable extends CatalogAddons
    with TableInfo<$CatalogAddonsTable, CatalogAddon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogAddonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productUuidMeta = const VerificationMeta(
    'productUuid',
  );
  @override
  late final GeneratedColumn<String> productUuid = GeneratedColumn<String>(
    'product_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES catalog_products (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<int> price = GeneratedColumn<int>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    productUuid,
    name,
    price,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_addons';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogAddon> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('product_uuid')) {
      context.handle(
        _productUuidMeta,
        productUuid.isAcceptableOrUnknown(
          data['product_uuid']!,
          _productUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productUuidMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  CatalogAddon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogAddon(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      productUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $CatalogAddonsTable createAlias(String alias) {
    return $CatalogAddonsTable(attachedDatabase, alias);
  }
}

class CatalogAddon extends DataClass implements Insertable<CatalogAddon> {
  final String uuid;
  final String productUuid;
  final String name;
  final int price;
  final bool isActive;
  const CatalogAddon({
    required this.uuid,
    required this.productUuid,
    required this.name,
    required this.price,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['product_uuid'] = Variable<String>(productUuid);
    map['name'] = Variable<String>(name);
    map['price'] = Variable<int>(price);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CatalogAddonsCompanion toCompanion(bool nullToAbsent) {
    return CatalogAddonsCompanion(
      uuid: Value(uuid),
      productUuid: Value(productUuid),
      name: Value(name),
      price: Value(price),
      isActive: Value(isActive),
    );
  }

  factory CatalogAddon.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogAddon(
      uuid: serializer.fromJson<String>(json['uuid']),
      productUuid: serializer.fromJson<String>(json['productUuid']),
      name: serializer.fromJson<String>(json['name']),
      price: serializer.fromJson<int>(json['price']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'productUuid': serializer.toJson<String>(productUuid),
      'name': serializer.toJson<String>(name),
      'price': serializer.toJson<int>(price),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  CatalogAddon copyWith({
    String? uuid,
    String? productUuid,
    String? name,
    int? price,
    bool? isActive,
  }) => CatalogAddon(
    uuid: uuid ?? this.uuid,
    productUuid: productUuid ?? this.productUuid,
    name: name ?? this.name,
    price: price ?? this.price,
    isActive: isActive ?? this.isActive,
  );
  CatalogAddon copyWithCompanion(CatalogAddonsCompanion data) {
    return CatalogAddon(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      productUuid: data.productUuid.present
          ? data.productUuid.value
          : this.productUuid,
      name: data.name.present ? data.name.value : this.name,
      price: data.price.present ? data.price.value : this.price,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogAddon(')
          ..write('uuid: $uuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(uuid, productUuid, name, price, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogAddon &&
          other.uuid == this.uuid &&
          other.productUuid == this.productUuid &&
          other.name == this.name &&
          other.price == this.price &&
          other.isActive == this.isActive);
}

class CatalogAddonsCompanion extends UpdateCompanion<CatalogAddon> {
  final Value<String> uuid;
  final Value<String> productUuid;
  final Value<String> name;
  final Value<int> price;
  final Value<bool> isActive;
  final Value<int> rowid;
  const CatalogAddonsCompanion({
    this.uuid = const Value.absent(),
    this.productUuid = const Value.absent(),
    this.name = const Value.absent(),
    this.price = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogAddonsCompanion.insert({
    required String uuid,
    required String productUuid,
    required String name,
    this.price = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       productUuid = Value(productUuid),
       name = Value(name);
  static Insertable<CatalogAddon> custom({
    Expression<String>? uuid,
    Expression<String>? productUuid,
    Expression<String>? name,
    Expression<int>? price,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (productUuid != null) 'product_uuid': productUuid,
      if (name != null) 'name': name,
      if (price != null) 'price': price,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogAddonsCompanion copyWith({
    Value<String>? uuid,
    Value<String>? productUuid,
    Value<String>? name,
    Value<int>? price,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return CatalogAddonsCompanion(
      uuid: uuid ?? this.uuid,
      productUuid: productUuid ?? this.productUuid,
      name: name ?? this.name,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (productUuid.present) {
      map['product_uuid'] = Variable<String>(productUuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (price.present) {
      map['price'] = Variable<int>(price.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogAddonsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('name: $name, ')
          ..write('price: $price, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOrdersTable extends LocalOrders
    with TableInfo<$LocalOrdersTable, LocalOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderNumberMeta = const VerificationMeta(
    'orderNumber',
  );
  @override
  late final GeneratedColumn<String> orderNumber = GeneratedColumn<String>(
    'order_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dine_in'),
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
    'table_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('held'),
  );
  static const VerificationMeta _transactionDiscountMeta =
      const VerificationMeta('transactionDiscount');
  @override
  late final GeneratedColumn<int> transactionDiscount = GeneratedColumn<int>(
    'transaction_discount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serverUuidMeta = const VerificationMeta(
    'serverUuid',
  );
  @override
  late final GeneratedColumn<String> serverUuid = GeneratedColumn<String>(
    'server_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    orderNumber,
    orderType,
    tableNumber,
    notes,
    status,
    transactionDiscount,
    baseVersion,
    serverUuid,
    synced,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('transaction_discount')) {
      context.handle(
        _transactionDiscountMeta,
        transactionDiscount.isAcceptableOrUnknown(
          data['transaction_discount']!,
          _transactionDiscountMeta,
        ),
      );
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('server_uuid')) {
      context.handle(
        _serverUuidMeta,
        serverUuid.isAcceptableOrUnknown(data['server_uuid']!, _serverUuidMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  LocalOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOrder(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      orderNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_number'],
      ),
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_type'],
      )!,
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_number'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      transactionDiscount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_discount'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      )!,
      serverUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_uuid'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalOrdersTable createAlias(String alias) {
    return $LocalOrdersTable(attachedDatabase, alias);
  }
}

class LocalOrder extends DataClass implements Insertable<LocalOrder> {
  final String uuid;
  final String? orderNumber;
  final String orderType;
  final String? tableNumber;
  final String? notes;
  final String status;
  final int transactionDiscount;
  final int baseVersion;
  final String? serverUuid;
  final bool synced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalOrder({
    required this.uuid,
    this.orderNumber,
    required this.orderType,
    this.tableNumber,
    this.notes,
    required this.status,
    required this.transactionDiscount,
    required this.baseVersion,
    this.serverUuid,
    required this.synced,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    if (!nullToAbsent || orderNumber != null) {
      map['order_number'] = Variable<String>(orderNumber);
    }
    map['order_type'] = Variable<String>(orderType);
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<String>(tableNumber);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['transaction_discount'] = Variable<int>(transactionDiscount);
    map['base_version'] = Variable<int>(baseVersion);
    if (!nullToAbsent || serverUuid != null) {
      map['server_uuid'] = Variable<String>(serverUuid);
    }
    map['synced'] = Variable<bool>(synced);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalOrdersCompanion toCompanion(bool nullToAbsent) {
    return LocalOrdersCompanion(
      uuid: Value(uuid),
      orderNumber: orderNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(orderNumber),
      orderType: Value(orderType),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      transactionDiscount: Value(transactionDiscount),
      baseVersion: Value(baseVersion),
      serverUuid: serverUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUuid),
      synced: Value(synced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOrder(
      uuid: serializer.fromJson<String>(json['uuid']),
      orderNumber: serializer.fromJson<String?>(json['orderNumber']),
      orderType: serializer.fromJson<String>(json['orderType']),
      tableNumber: serializer.fromJson<String?>(json['tableNumber']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      transactionDiscount: serializer.fromJson<int>(
        json['transactionDiscount'],
      ),
      baseVersion: serializer.fromJson<int>(json['baseVersion']),
      serverUuid: serializer.fromJson<String?>(json['serverUuid']),
      synced: serializer.fromJson<bool>(json['synced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'orderNumber': serializer.toJson<String?>(orderNumber),
      'orderType': serializer.toJson<String>(orderType),
      'tableNumber': serializer.toJson<String?>(tableNumber),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'transactionDiscount': serializer.toJson<int>(transactionDiscount),
      'baseVersion': serializer.toJson<int>(baseVersion),
      'serverUuid': serializer.toJson<String?>(serverUuid),
      'synced': serializer.toJson<bool>(synced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalOrder copyWith({
    String? uuid,
    Value<String?> orderNumber = const Value.absent(),
    String? orderType,
    Value<String?> tableNumber = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    int? transactionDiscount,
    int? baseVersion,
    Value<String?> serverUuid = const Value.absent(),
    bool? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalOrder(
    uuid: uuid ?? this.uuid,
    orderNumber: orderNumber.present ? orderNumber.value : this.orderNumber,
    orderType: orderType ?? this.orderType,
    tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    transactionDiscount: transactionDiscount ?? this.transactionDiscount,
    baseVersion: baseVersion ?? this.baseVersion,
    serverUuid: serverUuid.present ? serverUuid.value : this.serverUuid,
    synced: synced ?? this.synced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalOrder copyWithCompanion(LocalOrdersCompanion data) {
    return LocalOrder(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      orderNumber: data.orderNumber.present
          ? data.orderNumber.value
          : this.orderNumber,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      transactionDiscount: data.transactionDiscount.present
          ? data.transactionDiscount.value
          : this.transactionDiscount,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      serverUuid: data.serverUuid.present
          ? data.serverUuid.value
          : this.serverUuid,
      synced: data.synced.present ? data.synced.value : this.synced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrder(')
          ..write('uuid: $uuid, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('transactionDiscount: $transactionDiscount, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('serverUuid: $serverUuid, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    orderNumber,
    orderType,
    tableNumber,
    notes,
    status,
    transactionDiscount,
    baseVersion,
    serverUuid,
    synced,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOrder &&
          other.uuid == this.uuid &&
          other.orderNumber == this.orderNumber &&
          other.orderType == this.orderType &&
          other.tableNumber == this.tableNumber &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.transactionDiscount == this.transactionDiscount &&
          other.baseVersion == this.baseVersion &&
          other.serverUuid == this.serverUuid &&
          other.synced == this.synced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalOrdersCompanion extends UpdateCompanion<LocalOrder> {
  final Value<String> uuid;
  final Value<String?> orderNumber;
  final Value<String> orderType;
  final Value<String?> tableNumber;
  final Value<String?> notes;
  final Value<String> status;
  final Value<int> transactionDiscount;
  final Value<int> baseVersion;
  final Value<String?> serverUuid;
  final Value<bool> synced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalOrdersCompanion({
    this.uuid = const Value.absent(),
    this.orderNumber = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.transactionDiscount = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.serverUuid = const Value.absent(),
    this.synced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOrdersCompanion.insert({
    required String uuid,
    this.orderNumber = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.transactionDiscount = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.serverUuid = const Value.absent(),
    this.synced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalOrder> custom({
    Expression<String>? uuid,
    Expression<String>? orderNumber,
    Expression<String>? orderType,
    Expression<String>? tableNumber,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<int>? transactionDiscount,
    Expression<int>? baseVersion,
    Expression<String>? serverUuid,
    Expression<bool>? synced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (orderNumber != null) 'order_number': orderNumber,
      if (orderType != null) 'order_type': orderType,
      if (tableNumber != null) 'table_number': tableNumber,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (transactionDiscount != null)
        'transaction_discount': transactionDiscount,
      if (baseVersion != null) 'base_version': baseVersion,
      if (serverUuid != null) 'server_uuid': serverUuid,
      if (synced != null) 'synced': synced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOrdersCompanion copyWith({
    Value<String>? uuid,
    Value<String?>? orderNumber,
    Value<String>? orderType,
    Value<String?>? tableNumber,
    Value<String?>? notes,
    Value<String>? status,
    Value<int>? transactionDiscount,
    Value<int>? baseVersion,
    Value<String?>? serverUuid,
    Value<bool>? synced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalOrdersCompanion(
      uuid: uuid ?? this.uuid,
      orderNumber: orderNumber ?? this.orderNumber,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      transactionDiscount: transactionDiscount ?? this.transactionDiscount,
      baseVersion: baseVersion ?? this.baseVersion,
      serverUuid: serverUuid ?? this.serverUuid,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (orderNumber.present) {
      map['order_number'] = Variable<String>(orderNumber.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (transactionDiscount.present) {
      map['transaction_discount'] = Variable<int>(transactionDiscount.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (serverUuid.present) {
      map['server_uuid'] = Variable<String>(serverUuid.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOrdersCompanion(')
          ..write('uuid: $uuid, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('transactionDiscount: $transactionDiscount, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('serverUuid: $serverUuid, ')
          ..write('synced: $synced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderItemsTable extends OrderItems
    with TableInfo<$OrderItemsTable, OrderItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _orderUuidMeta = const VerificationMeta(
    'orderUuid',
  );
  @override
  late final GeneratedColumn<String> orderUuid = GeneratedColumn<String>(
    'order_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_orders (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productUuidMeta = const VerificationMeta(
    'productUuid',
  );
  @override
  late final GeneratedColumn<String> productUuid = GeneratedColumn<String>(
    'product_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantUuidMeta = const VerificationMeta(
    'variantUuid',
  );
  @override
  late final GeneratedColumn<String> variantUuid = GeneratedColumn<String>(
    'variant_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addonsJsonMeta = const VerificationMeta(
    'addonsJson',
  );
  @override
  late final GeneratedColumn<String> addonsJson = GeneratedColumn<String>(
    'addons_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDiscountMeta = const VerificationMeta(
    'itemDiscount',
  );
  @override
  late final GeneratedColumn<int> itemDiscount = GeneratedColumn<int>(
    'item_discount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxRateBasisPointsMeta =
      const VerificationMeta('taxRateBasisPoints');
  @override
  late final GeneratedColumn<int> taxRateBasisPoints = GeneratedColumn<int>(
    'tax_rate_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineSubtotalMeta = const VerificationMeta(
    'lineSubtotal',
  );
  @override
  late final GeneratedColumn<int> lineSubtotal = GeneratedColumn<int>(
    'line_subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<int> lineTotal = GeneratedColumn<int>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    orderUuid,
    productUuid,
    productName,
    variantUuid,
    variantName,
    addonsJson,
    unitPrice,
    quantity,
    itemDiscount,
    taxRateBasisPoints,
    lineSubtotal,
    lineTotal,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('order_uuid')) {
      context.handle(
        _orderUuidMeta,
        orderUuid.isAcceptableOrUnknown(data['order_uuid']!, _orderUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_orderUuidMeta);
    }
    if (data.containsKey('product_uuid')) {
      context.handle(
        _productUuidMeta,
        productUuid.isAcceptableOrUnknown(
          data['product_uuid']!,
          _productUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productUuidMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_uuid')) {
      context.handle(
        _variantUuidMeta,
        variantUuid.isAcceptableOrUnknown(
          data['variant_uuid']!,
          _variantUuidMeta,
        ),
      );
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    }
    if (data.containsKey('addons_json')) {
      context.handle(
        _addonsJsonMeta,
        addonsJson.isAcceptableOrUnknown(data['addons_json']!, _addonsJsonMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('item_discount')) {
      context.handle(
        _itemDiscountMeta,
        itemDiscount.isAcceptableOrUnknown(
          data['item_discount']!,
          _itemDiscountMeta,
        ),
      );
    }
    if (data.containsKey('tax_rate_basis_points')) {
      context.handle(
        _taxRateBasisPointsMeta,
        taxRateBasisPoints.isAcceptableOrUnknown(
          data['tax_rate_basis_points']!,
          _taxRateBasisPointsMeta,
        ),
      );
    }
    if (data.containsKey('line_subtotal')) {
      context.handle(
        _lineSubtotalMeta,
        lineSubtotal.isAcceptableOrUnknown(
          data['line_subtotal']!,
          _lineSubtotalMeta,
        ),
      );
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      orderUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_uuid'],
      )!,
      productUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_uuid'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_uuid'],
      ),
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      ),
      addonsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addons_json'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      itemDiscount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_discount'],
      )!,
      taxRateBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_rate_basis_points'],
      )!,
      lineSubtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_subtotal'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_total'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $OrderItemsTable createAlias(String alias) {
    return $OrderItemsTable(attachedDatabase, alias);
  }
}

class OrderItem extends DataClass implements Insertable<OrderItem> {
  final int id;
  final String orderUuid;
  final String productUuid;
  final String productName;
  final String? variantUuid;
  final String? variantName;
  final String addonsJson;
  final int unitPrice;
  final int quantity;
  final int itemDiscount;
  final int taxRateBasisPoints;
  final int lineSubtotal;
  final int lineTotal;
  final String? notes;
  const OrderItem({
    required this.id,
    required this.orderUuid,
    required this.productUuid,
    required this.productName,
    this.variantUuid,
    this.variantName,
    required this.addonsJson,
    required this.unitPrice,
    required this.quantity,
    required this.itemDiscount,
    required this.taxRateBasisPoints,
    required this.lineSubtotal,
    required this.lineTotal,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['order_uuid'] = Variable<String>(orderUuid);
    map['product_uuid'] = Variable<String>(productUuid);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || variantUuid != null) {
      map['variant_uuid'] = Variable<String>(variantUuid);
    }
    if (!nullToAbsent || variantName != null) {
      map['variant_name'] = Variable<String>(variantName);
    }
    map['addons_json'] = Variable<String>(addonsJson);
    map['unit_price'] = Variable<int>(unitPrice);
    map['quantity'] = Variable<int>(quantity);
    map['item_discount'] = Variable<int>(itemDiscount);
    map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints);
    map['line_subtotal'] = Variable<int>(lineSubtotal);
    map['line_total'] = Variable<int>(lineTotal);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  OrderItemsCompanion toCompanion(bool nullToAbsent) {
    return OrderItemsCompanion(
      id: Value(id),
      orderUuid: Value(orderUuid),
      productUuid: Value(productUuid),
      productName: Value(productName),
      variantUuid: variantUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(variantUuid),
      variantName: variantName == null && nullToAbsent
          ? const Value.absent()
          : Value(variantName),
      addonsJson: Value(addonsJson),
      unitPrice: Value(unitPrice),
      quantity: Value(quantity),
      itemDiscount: Value(itemDiscount),
      taxRateBasisPoints: Value(taxRateBasisPoints),
      lineSubtotal: Value(lineSubtotal),
      lineTotal: Value(lineTotal),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory OrderItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderItem(
      id: serializer.fromJson<int>(json['id']),
      orderUuid: serializer.fromJson<String>(json['orderUuid']),
      productUuid: serializer.fromJson<String>(json['productUuid']),
      productName: serializer.fromJson<String>(json['productName']),
      variantUuid: serializer.fromJson<String?>(json['variantUuid']),
      variantName: serializer.fromJson<String?>(json['variantName']),
      addonsJson: serializer.fromJson<String>(json['addonsJson']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      quantity: serializer.fromJson<int>(json['quantity']),
      itemDiscount: serializer.fromJson<int>(json['itemDiscount']),
      taxRateBasisPoints: serializer.fromJson<int>(json['taxRateBasisPoints']),
      lineSubtotal: serializer.fromJson<int>(json['lineSubtotal']),
      lineTotal: serializer.fromJson<int>(json['lineTotal']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'orderUuid': serializer.toJson<String>(orderUuid),
      'productUuid': serializer.toJson<String>(productUuid),
      'productName': serializer.toJson<String>(productName),
      'variantUuid': serializer.toJson<String?>(variantUuid),
      'variantName': serializer.toJson<String?>(variantName),
      'addonsJson': serializer.toJson<String>(addonsJson),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'quantity': serializer.toJson<int>(quantity),
      'itemDiscount': serializer.toJson<int>(itemDiscount),
      'taxRateBasisPoints': serializer.toJson<int>(taxRateBasisPoints),
      'lineSubtotal': serializer.toJson<int>(lineSubtotal),
      'lineTotal': serializer.toJson<int>(lineTotal),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  OrderItem copyWith({
    int? id,
    String? orderUuid,
    String? productUuid,
    String? productName,
    Value<String?> variantUuid = const Value.absent(),
    Value<String?> variantName = const Value.absent(),
    String? addonsJson,
    int? unitPrice,
    int? quantity,
    int? itemDiscount,
    int? taxRateBasisPoints,
    int? lineSubtotal,
    int? lineTotal,
    Value<String?> notes = const Value.absent(),
  }) => OrderItem(
    id: id ?? this.id,
    orderUuid: orderUuid ?? this.orderUuid,
    productUuid: productUuid ?? this.productUuid,
    productName: productName ?? this.productName,
    variantUuid: variantUuid.present ? variantUuid.value : this.variantUuid,
    variantName: variantName.present ? variantName.value : this.variantName,
    addonsJson: addonsJson ?? this.addonsJson,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    itemDiscount: itemDiscount ?? this.itemDiscount,
    taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
    lineSubtotal: lineSubtotal ?? this.lineSubtotal,
    lineTotal: lineTotal ?? this.lineTotal,
    notes: notes.present ? notes.value : this.notes,
  );
  OrderItem copyWithCompanion(OrderItemsCompanion data) {
    return OrderItem(
      id: data.id.present ? data.id.value : this.id,
      orderUuid: data.orderUuid.present ? data.orderUuid.value : this.orderUuid,
      productUuid: data.productUuid.present
          ? data.productUuid.value
          : this.productUuid,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantUuid: data.variantUuid.present
          ? data.variantUuid.value
          : this.variantUuid,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      addonsJson: data.addonsJson.present
          ? data.addonsJson.value
          : this.addonsJson,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      itemDiscount: data.itemDiscount.present
          ? data.itemDiscount.value
          : this.itemDiscount,
      taxRateBasisPoints: data.taxRateBasisPoints.present
          ? data.taxRateBasisPoints.value
          : this.taxRateBasisPoints,
      lineSubtotal: data.lineSubtotal.present
          ? data.lineSubtotal.value
          : this.lineSubtotal,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderItem(')
          ..write('id: $id, ')
          ..write('orderUuid: $orderUuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('productName: $productName, ')
          ..write('variantUuid: $variantUuid, ')
          ..write('variantName: $variantName, ')
          ..write('addonsJson: $addonsJson, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('itemDiscount: $itemDiscount, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('lineSubtotal: $lineSubtotal, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    orderUuid,
    productUuid,
    productName,
    variantUuid,
    variantName,
    addonsJson,
    unitPrice,
    quantity,
    itemDiscount,
    taxRateBasisPoints,
    lineSubtotal,
    lineTotal,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderItem &&
          other.id == this.id &&
          other.orderUuid == this.orderUuid &&
          other.productUuid == this.productUuid &&
          other.productName == this.productName &&
          other.variantUuid == this.variantUuid &&
          other.variantName == this.variantName &&
          other.addonsJson == this.addonsJson &&
          other.unitPrice == this.unitPrice &&
          other.quantity == this.quantity &&
          other.itemDiscount == this.itemDiscount &&
          other.taxRateBasisPoints == this.taxRateBasisPoints &&
          other.lineSubtotal == this.lineSubtotal &&
          other.lineTotal == this.lineTotal &&
          other.notes == this.notes);
}

class OrderItemsCompanion extends UpdateCompanion<OrderItem> {
  final Value<int> id;
  final Value<String> orderUuid;
  final Value<String> productUuid;
  final Value<String> productName;
  final Value<String?> variantUuid;
  final Value<String?> variantName;
  final Value<String> addonsJson;
  final Value<int> unitPrice;
  final Value<int> quantity;
  final Value<int> itemDiscount;
  final Value<int> taxRateBasisPoints;
  final Value<int> lineSubtotal;
  final Value<int> lineTotal;
  final Value<String?> notes;
  const OrderItemsCompanion({
    this.id = const Value.absent(),
    this.orderUuid = const Value.absent(),
    this.productUuid = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantUuid = const Value.absent(),
    this.variantName = const Value.absent(),
    this.addonsJson = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.itemDiscount = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.lineSubtotal = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.notes = const Value.absent(),
  });
  OrderItemsCompanion.insert({
    this.id = const Value.absent(),
    required String orderUuid,
    required String productUuid,
    required String productName,
    this.variantUuid = const Value.absent(),
    this.variantName = const Value.absent(),
    this.addonsJson = const Value.absent(),
    required int unitPrice,
    required int quantity,
    this.itemDiscount = const Value.absent(),
    this.taxRateBasisPoints = const Value.absent(),
    this.lineSubtotal = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.notes = const Value.absent(),
  }) : orderUuid = Value(orderUuid),
       productUuid = Value(productUuid),
       productName = Value(productName),
       unitPrice = Value(unitPrice),
       quantity = Value(quantity);
  static Insertable<OrderItem> custom({
    Expression<int>? id,
    Expression<String>? orderUuid,
    Expression<String>? productUuid,
    Expression<String>? productName,
    Expression<String>? variantUuid,
    Expression<String>? variantName,
    Expression<String>? addonsJson,
    Expression<int>? unitPrice,
    Expression<int>? quantity,
    Expression<int>? itemDiscount,
    Expression<int>? taxRateBasisPoints,
    Expression<int>? lineSubtotal,
    Expression<int>? lineTotal,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (orderUuid != null) 'order_uuid': orderUuid,
      if (productUuid != null) 'product_uuid': productUuid,
      if (productName != null) 'product_name': productName,
      if (variantUuid != null) 'variant_uuid': variantUuid,
      if (variantName != null) 'variant_name': variantName,
      if (addonsJson != null) 'addons_json': addonsJson,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (quantity != null) 'quantity': quantity,
      if (itemDiscount != null) 'item_discount': itemDiscount,
      if (taxRateBasisPoints != null)
        'tax_rate_basis_points': taxRateBasisPoints,
      if (lineSubtotal != null) 'line_subtotal': lineSubtotal,
      if (lineTotal != null) 'line_total': lineTotal,
      if (notes != null) 'notes': notes,
    });
  }

  OrderItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? orderUuid,
    Value<String>? productUuid,
    Value<String>? productName,
    Value<String?>? variantUuid,
    Value<String?>? variantName,
    Value<String>? addonsJson,
    Value<int>? unitPrice,
    Value<int>? quantity,
    Value<int>? itemDiscount,
    Value<int>? taxRateBasisPoints,
    Value<int>? lineSubtotal,
    Value<int>? lineTotal,
    Value<String?>? notes,
  }) {
    return OrderItemsCompanion(
      id: id ?? this.id,
      orderUuid: orderUuid ?? this.orderUuid,
      productUuid: productUuid ?? this.productUuid,
      productName: productName ?? this.productName,
      variantUuid: variantUuid ?? this.variantUuid,
      variantName: variantName ?? this.variantName,
      addonsJson: addonsJson ?? this.addonsJson,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      taxRateBasisPoints: taxRateBasisPoints ?? this.taxRateBasisPoints,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTotal: lineTotal ?? this.lineTotal,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (orderUuid.present) {
      map['order_uuid'] = Variable<String>(orderUuid.value);
    }
    if (productUuid.present) {
      map['product_uuid'] = Variable<String>(productUuid.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantUuid.present) {
      map['variant_uuid'] = Variable<String>(variantUuid.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (addonsJson.present) {
      map['addons_json'] = Variable<String>(addonsJson.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (itemDiscount.present) {
      map['item_discount'] = Variable<int>(itemDiscount.value);
    }
    if (taxRateBasisPoints.present) {
      map['tax_rate_basis_points'] = Variable<int>(taxRateBasisPoints.value);
    }
    if (lineSubtotal.present) {
      map['line_subtotal'] = Variable<int>(lineSubtotal.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<int>(lineTotal.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderItemsCompanion(')
          ..write('id: $id, ')
          ..write('orderUuid: $orderUuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('productName: $productName, ')
          ..write('variantUuid: $variantUuid, ')
          ..write('variantName: $variantName, ')
          ..write('addonsJson: $addonsJson, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('itemDiscount: $itemDiscount, ')
          ..write('taxRateBasisPoints: $taxRateBasisPoints, ')
          ..write('lineSubtotal: $lineSubtotal, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $LocalSalesTable extends LocalSales
    with TableInfo<$LocalSalesTable, LocalSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receiptNumberMeta = const VerificationMeta(
    'receiptNumber',
  );
  @override
  late final GeneratedColumn<String> receiptNumber = GeneratedColumn<String>(
    'receipt_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orderUuidMeta = const VerificationMeta(
    'orderUuid',
  );
  @override
  late final GeneratedColumn<String> orderUuid = GeneratedColumn<String>(
    'order_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverOrderUuidMeta = const VerificationMeta(
    'serverOrderUuid',
  );
  @override
  late final GeneratedColumn<String> serverOrderUuid = GeneratedColumn<String>(
    'server_order_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceOrderVersionMeta =
      const VerificationMeta('sourceOrderVersion');
  @override
  late final GeneratedColumn<int> sourceOrderVersion = GeneratedColumn<int>(
    'source_order_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('online'),
  );
  static const VerificationMeta _orderTypeMeta = const VerificationMeta(
    'orderType',
  );
  @override
  late final GeneratedColumn<String> orderType = GeneratedColumn<String>(
    'order_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableNumberMeta = const VerificationMeta(
    'tableNumber',
  );
  @override
  late final GeneratedColumn<String> tableNumber = GeneratedColumn<String>(
    'table_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lifecycleStatusMeta = const VerificationMeta(
    'lifecycleStatus',
  );
  @override
  late final GeneratedColumn<String> lifecycleStatus = GeneratedColumn<String>(
    'lifecycle_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('finalized'),
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('unpaid'),
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDiscountTotalMeta = const VerificationMeta(
    'itemDiscountTotal',
  );
  @override
  late final GeneratedColumn<int> itemDiscountTotal = GeneratedColumn<int>(
    'item_discount_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _transactionDiscountTotalMeta =
      const VerificationMeta('transactionDiscountTotal');
  @override
  late final GeneratedColumn<int> transactionDiscountTotal =
      GeneratedColumn<int>(
        'transaction_discount_total',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _discountTotalMeta = const VerificationMeta(
    'discountTotal',
  );
  @override
  late final GeneratedColumn<int> discountTotal = GeneratedColumn<int>(
    'discount_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _netSubtotalMeta = const VerificationMeta(
    'netSubtotal',
  );
  @override
  late final GeneratedColumn<int> netSubtotal = GeneratedColumn<int>(
    'net_subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _serviceChargeMeta = const VerificationMeta(
    'serviceCharge',
  );
  @override
  late final GeneratedColumn<int> serviceCharge = GeneratedColumn<int>(
    'service_charge',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _taxTotalMeta = const VerificationMeta(
    'taxTotal',
  );
  @override
  late final GeneratedColumn<int> taxTotal = GeneratedColumn<int>(
    'tax_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAmountMeta = const VerificationMeta(
    'confirmedAmount',
  );
  @override
  late final GeneratedColumn<int> confirmedAmount = GeneratedColumn<int>(
    'confirmed_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awaitingAmountMeta = const VerificationMeta(
    'awaitingAmount',
  );
  @override
  late final GeneratedColumn<int> awaitingAmount = GeneratedColumn<int>(
    'awaiting_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _refundedAmountMeta = const VerificationMeta(
    'refundedAmount',
  );
  @override
  late final GeneratedColumn<int> refundedAmount = GeneratedColumn<int>(
    'refunded_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _shiftUuidMeta = const VerificationMeta(
    'shiftUuid',
  );
  @override
  late final GeneratedColumn<String> shiftUuid = GeneratedColumn<String>(
    'shift_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cashierNameMeta = const VerificationMeta(
    'cashierName',
  );
  @override
  late final GeneratedColumn<String> cashierName = GeneratedColumn<String>(
    'cashier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _transactedAtMeta = const VerificationMeta(
    'transactedAt',
  );
  @override
  late final GeneratedColumn<DateTime> transactedAt = GeneratedColumn<DateTime>(
    'transacted_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    receiptNumber,
    orderUuid,
    serverOrderUuid,
    sourceOrderVersion,
    origin,
    orderType,
    tableNumber,
    lifecycleStatus,
    paymentStatus,
    subtotal,
    itemDiscountTotal,
    transactionDiscountTotal,
    discountTotal,
    netSubtotal,
    serviceCharge,
    taxTotal,
    total,
    confirmedAmount,
    awaitingAmount,
    refundedAmount,
    shiftUuid,
    cashierName,
    notes,
    synced,
    transactedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('receipt_number')) {
      context.handle(
        _receiptNumberMeta,
        receiptNumber.isAcceptableOrUnknown(
          data['receipt_number']!,
          _receiptNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptNumberMeta);
    }
    if (data.containsKey('order_uuid')) {
      context.handle(
        _orderUuidMeta,
        orderUuid.isAcceptableOrUnknown(data['order_uuid']!, _orderUuidMeta),
      );
    }
    if (data.containsKey('server_order_uuid')) {
      context.handle(
        _serverOrderUuidMeta,
        serverOrderUuid.isAcceptableOrUnknown(
          data['server_order_uuid']!,
          _serverOrderUuidMeta,
        ),
      );
    }
    if (data.containsKey('source_order_version')) {
      context.handle(
        _sourceOrderVersionMeta,
        sourceOrderVersion.isAcceptableOrUnknown(
          data['source_order_version']!,
          _sourceOrderVersionMeta,
        ),
      );
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    }
    if (data.containsKey('order_type')) {
      context.handle(
        _orderTypeMeta,
        orderType.isAcceptableOrUnknown(data['order_type']!, _orderTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_orderTypeMeta);
    }
    if (data.containsKey('table_number')) {
      context.handle(
        _tableNumberMeta,
        tableNumber.isAcceptableOrUnknown(
          data['table_number']!,
          _tableNumberMeta,
        ),
      );
    }
    if (data.containsKey('lifecycle_status')) {
      context.handle(
        _lifecycleStatusMeta,
        lifecycleStatus.isAcceptableOrUnknown(
          data['lifecycle_status']!,
          _lifecycleStatusMeta,
        ),
      );
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('item_discount_total')) {
      context.handle(
        _itemDiscountTotalMeta,
        itemDiscountTotal.isAcceptableOrUnknown(
          data['item_discount_total']!,
          _itemDiscountTotalMeta,
        ),
      );
    }
    if (data.containsKey('transaction_discount_total')) {
      context.handle(
        _transactionDiscountTotalMeta,
        transactionDiscountTotal.isAcceptableOrUnknown(
          data['transaction_discount_total']!,
          _transactionDiscountTotalMeta,
        ),
      );
    }
    if (data.containsKey('discount_total')) {
      context.handle(
        _discountTotalMeta,
        discountTotal.isAcceptableOrUnknown(
          data['discount_total']!,
          _discountTotalMeta,
        ),
      );
    }
    if (data.containsKey('net_subtotal')) {
      context.handle(
        _netSubtotalMeta,
        netSubtotal.isAcceptableOrUnknown(
          data['net_subtotal']!,
          _netSubtotalMeta,
        ),
      );
    }
    if (data.containsKey('service_charge')) {
      context.handle(
        _serviceChargeMeta,
        serviceCharge.isAcceptableOrUnknown(
          data['service_charge']!,
          _serviceChargeMeta,
        ),
      );
    }
    if (data.containsKey('tax_total')) {
      context.handle(
        _taxTotalMeta,
        taxTotal.isAcceptableOrUnknown(data['tax_total']!, _taxTotalMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('confirmed_amount')) {
      context.handle(
        _confirmedAmountMeta,
        confirmedAmount.isAcceptableOrUnknown(
          data['confirmed_amount']!,
          _confirmedAmountMeta,
        ),
      );
    }
    if (data.containsKey('awaiting_amount')) {
      context.handle(
        _awaitingAmountMeta,
        awaitingAmount.isAcceptableOrUnknown(
          data['awaiting_amount']!,
          _awaitingAmountMeta,
        ),
      );
    }
    if (data.containsKey('refunded_amount')) {
      context.handle(
        _refundedAmountMeta,
        refundedAmount.isAcceptableOrUnknown(
          data['refunded_amount']!,
          _refundedAmountMeta,
        ),
      );
    }
    if (data.containsKey('shift_uuid')) {
      context.handle(
        _shiftUuidMeta,
        shiftUuid.isAcceptableOrUnknown(data['shift_uuid']!, _shiftUuidMeta),
      );
    }
    if (data.containsKey('cashier_name')) {
      context.handle(
        _cashierNameMeta,
        cashierName.isAcceptableOrUnknown(
          data['cashier_name']!,
          _cashierNameMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('transacted_at')) {
      context.handle(
        _transactedAtMeta,
        transactedAt.isAcceptableOrUnknown(
          data['transacted_at']!,
          _transactedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  LocalSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSale(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      receiptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_number'],
      )!,
      orderUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_uuid'],
      ),
      serverOrderUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_order_uuid'],
      ),
      sourceOrderVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_order_version'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      orderType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}order_type'],
      )!,
      tableNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_number'],
      ),
      lifecycleStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle_status'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      itemDiscountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_discount_total'],
      )!,
      transactionDiscountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_discount_total'],
      )!,
      discountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_total'],
      )!,
      netSubtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}net_subtotal'],
      )!,
      serviceCharge: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}service_charge'],
      )!,
      taxTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_total'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      confirmedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}confirmed_amount'],
      )!,
      awaitingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}awaiting_amount'],
      )!,
      refundedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}refunded_amount'],
      )!,
      shiftUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_uuid'],
      ),
      cashierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cashier_name'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      transactedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transacted_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalSalesTable createAlias(String alias) {
    return $LocalSalesTable(attachedDatabase, alias);
  }
}

class LocalSale extends DataClass implements Insertable<LocalSale> {
  final String uuid;
  final String receiptNumber;
  final String? orderUuid;
  final String? serverOrderUuid;
  final int sourceOrderVersion;
  final String origin;
  final String orderType;
  final String? tableNumber;
  final String lifecycleStatus;
  final String paymentStatus;
  final int subtotal;
  final int itemDiscountTotal;
  final int transactionDiscountTotal;
  final int discountTotal;
  final int netSubtotal;
  final int serviceCharge;
  final int taxTotal;
  final int total;
  final int confirmedAmount;
  final int awaitingAmount;
  final int refundedAmount;
  final String? shiftUuid;
  final String? cashierName;
  final String? notes;
  final bool synced;
  final DateTime transactedAt;
  final DateTime createdAt;
  const LocalSale({
    required this.uuid,
    required this.receiptNumber,
    this.orderUuid,
    this.serverOrderUuid,
    required this.sourceOrderVersion,
    required this.origin,
    required this.orderType,
    this.tableNumber,
    required this.lifecycleStatus,
    required this.paymentStatus,
    required this.subtotal,
    required this.itemDiscountTotal,
    required this.transactionDiscountTotal,
    required this.discountTotal,
    required this.netSubtotal,
    required this.serviceCharge,
    required this.taxTotal,
    required this.total,
    required this.confirmedAmount,
    required this.awaitingAmount,
    required this.refundedAmount,
    this.shiftUuid,
    this.cashierName,
    this.notes,
    required this.synced,
    required this.transactedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['receipt_number'] = Variable<String>(receiptNumber);
    if (!nullToAbsent || orderUuid != null) {
      map['order_uuid'] = Variable<String>(orderUuid);
    }
    if (!nullToAbsent || serverOrderUuid != null) {
      map['server_order_uuid'] = Variable<String>(serverOrderUuid);
    }
    map['source_order_version'] = Variable<int>(sourceOrderVersion);
    map['origin'] = Variable<String>(origin);
    map['order_type'] = Variable<String>(orderType);
    if (!nullToAbsent || tableNumber != null) {
      map['table_number'] = Variable<String>(tableNumber);
    }
    map['lifecycle_status'] = Variable<String>(lifecycleStatus);
    map['payment_status'] = Variable<String>(paymentStatus);
    map['subtotal'] = Variable<int>(subtotal);
    map['item_discount_total'] = Variable<int>(itemDiscountTotal);
    map['transaction_discount_total'] = Variable<int>(transactionDiscountTotal);
    map['discount_total'] = Variable<int>(discountTotal);
    map['net_subtotal'] = Variable<int>(netSubtotal);
    map['service_charge'] = Variable<int>(serviceCharge);
    map['tax_total'] = Variable<int>(taxTotal);
    map['total'] = Variable<int>(total);
    map['confirmed_amount'] = Variable<int>(confirmedAmount);
    map['awaiting_amount'] = Variable<int>(awaitingAmount);
    map['refunded_amount'] = Variable<int>(refundedAmount);
    if (!nullToAbsent || shiftUuid != null) {
      map['shift_uuid'] = Variable<String>(shiftUuid);
    }
    if (!nullToAbsent || cashierName != null) {
      map['cashier_name'] = Variable<String>(cashierName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['synced'] = Variable<bool>(synced);
    map['transacted_at'] = Variable<DateTime>(transactedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalSalesCompanion toCompanion(bool nullToAbsent) {
    return LocalSalesCompanion(
      uuid: Value(uuid),
      receiptNumber: Value(receiptNumber),
      orderUuid: orderUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(orderUuid),
      serverOrderUuid: serverOrderUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(serverOrderUuid),
      sourceOrderVersion: Value(sourceOrderVersion),
      origin: Value(origin),
      orderType: Value(orderType),
      tableNumber: tableNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(tableNumber),
      lifecycleStatus: Value(lifecycleStatus),
      paymentStatus: Value(paymentStatus),
      subtotal: Value(subtotal),
      itemDiscountTotal: Value(itemDiscountTotal),
      transactionDiscountTotal: Value(transactionDiscountTotal),
      discountTotal: Value(discountTotal),
      netSubtotal: Value(netSubtotal),
      serviceCharge: Value(serviceCharge),
      taxTotal: Value(taxTotal),
      total: Value(total),
      confirmedAmount: Value(confirmedAmount),
      awaitingAmount: Value(awaitingAmount),
      refundedAmount: Value(refundedAmount),
      shiftUuid: shiftUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(shiftUuid),
      cashierName: cashierName == null && nullToAbsent
          ? const Value.absent()
          : Value(cashierName),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      synced: Value(synced),
      transactedAt: Value(transactedAt),
      createdAt: Value(createdAt),
    );
  }

  factory LocalSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSale(
      uuid: serializer.fromJson<String>(json['uuid']),
      receiptNumber: serializer.fromJson<String>(json['receiptNumber']),
      orderUuid: serializer.fromJson<String?>(json['orderUuid']),
      serverOrderUuid: serializer.fromJson<String?>(json['serverOrderUuid']),
      sourceOrderVersion: serializer.fromJson<int>(json['sourceOrderVersion']),
      origin: serializer.fromJson<String>(json['origin']),
      orderType: serializer.fromJson<String>(json['orderType']),
      tableNumber: serializer.fromJson<String?>(json['tableNumber']),
      lifecycleStatus: serializer.fromJson<String>(json['lifecycleStatus']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      itemDiscountTotal: serializer.fromJson<int>(json['itemDiscountTotal']),
      transactionDiscountTotal: serializer.fromJson<int>(
        json['transactionDiscountTotal'],
      ),
      discountTotal: serializer.fromJson<int>(json['discountTotal']),
      netSubtotal: serializer.fromJson<int>(json['netSubtotal']),
      serviceCharge: serializer.fromJson<int>(json['serviceCharge']),
      taxTotal: serializer.fromJson<int>(json['taxTotal']),
      total: serializer.fromJson<int>(json['total']),
      confirmedAmount: serializer.fromJson<int>(json['confirmedAmount']),
      awaitingAmount: serializer.fromJson<int>(json['awaitingAmount']),
      refundedAmount: serializer.fromJson<int>(json['refundedAmount']),
      shiftUuid: serializer.fromJson<String?>(json['shiftUuid']),
      cashierName: serializer.fromJson<String?>(json['cashierName']),
      notes: serializer.fromJson<String?>(json['notes']),
      synced: serializer.fromJson<bool>(json['synced']),
      transactedAt: serializer.fromJson<DateTime>(json['transactedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'receiptNumber': serializer.toJson<String>(receiptNumber),
      'orderUuid': serializer.toJson<String?>(orderUuid),
      'serverOrderUuid': serializer.toJson<String?>(serverOrderUuid),
      'sourceOrderVersion': serializer.toJson<int>(sourceOrderVersion),
      'origin': serializer.toJson<String>(origin),
      'orderType': serializer.toJson<String>(orderType),
      'tableNumber': serializer.toJson<String?>(tableNumber),
      'lifecycleStatus': serializer.toJson<String>(lifecycleStatus),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'subtotal': serializer.toJson<int>(subtotal),
      'itemDiscountTotal': serializer.toJson<int>(itemDiscountTotal),
      'transactionDiscountTotal': serializer.toJson<int>(
        transactionDiscountTotal,
      ),
      'discountTotal': serializer.toJson<int>(discountTotal),
      'netSubtotal': serializer.toJson<int>(netSubtotal),
      'serviceCharge': serializer.toJson<int>(serviceCharge),
      'taxTotal': serializer.toJson<int>(taxTotal),
      'total': serializer.toJson<int>(total),
      'confirmedAmount': serializer.toJson<int>(confirmedAmount),
      'awaitingAmount': serializer.toJson<int>(awaitingAmount),
      'refundedAmount': serializer.toJson<int>(refundedAmount),
      'shiftUuid': serializer.toJson<String?>(shiftUuid),
      'cashierName': serializer.toJson<String?>(cashierName),
      'notes': serializer.toJson<String?>(notes),
      'synced': serializer.toJson<bool>(synced),
      'transactedAt': serializer.toJson<DateTime>(transactedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalSale copyWith({
    String? uuid,
    String? receiptNumber,
    Value<String?> orderUuid = const Value.absent(),
    Value<String?> serverOrderUuid = const Value.absent(),
    int? sourceOrderVersion,
    String? origin,
    String? orderType,
    Value<String?> tableNumber = const Value.absent(),
    String? lifecycleStatus,
    String? paymentStatus,
    int? subtotal,
    int? itemDiscountTotal,
    int? transactionDiscountTotal,
    int? discountTotal,
    int? netSubtotal,
    int? serviceCharge,
    int? taxTotal,
    int? total,
    int? confirmedAmount,
    int? awaitingAmount,
    int? refundedAmount,
    Value<String?> shiftUuid = const Value.absent(),
    Value<String?> cashierName = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? synced,
    DateTime? transactedAt,
    DateTime? createdAt,
  }) => LocalSale(
    uuid: uuid ?? this.uuid,
    receiptNumber: receiptNumber ?? this.receiptNumber,
    orderUuid: orderUuid.present ? orderUuid.value : this.orderUuid,
    serverOrderUuid: serverOrderUuid.present
        ? serverOrderUuid.value
        : this.serverOrderUuid,
    sourceOrderVersion: sourceOrderVersion ?? this.sourceOrderVersion,
    origin: origin ?? this.origin,
    orderType: orderType ?? this.orderType,
    tableNumber: tableNumber.present ? tableNumber.value : this.tableNumber,
    lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    subtotal: subtotal ?? this.subtotal,
    itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
    transactionDiscountTotal:
        transactionDiscountTotal ?? this.transactionDiscountTotal,
    discountTotal: discountTotal ?? this.discountTotal,
    netSubtotal: netSubtotal ?? this.netSubtotal,
    serviceCharge: serviceCharge ?? this.serviceCharge,
    taxTotal: taxTotal ?? this.taxTotal,
    total: total ?? this.total,
    confirmedAmount: confirmedAmount ?? this.confirmedAmount,
    awaitingAmount: awaitingAmount ?? this.awaitingAmount,
    refundedAmount: refundedAmount ?? this.refundedAmount,
    shiftUuid: shiftUuid.present ? shiftUuid.value : this.shiftUuid,
    cashierName: cashierName.present ? cashierName.value : this.cashierName,
    notes: notes.present ? notes.value : this.notes,
    synced: synced ?? this.synced,
    transactedAt: transactedAt ?? this.transactedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalSale copyWithCompanion(LocalSalesCompanion data) {
    return LocalSale(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      orderUuid: data.orderUuid.present ? data.orderUuid.value : this.orderUuid,
      serverOrderUuid: data.serverOrderUuid.present
          ? data.serverOrderUuid.value
          : this.serverOrderUuid,
      sourceOrderVersion: data.sourceOrderVersion.present
          ? data.sourceOrderVersion.value
          : this.sourceOrderVersion,
      origin: data.origin.present ? data.origin.value : this.origin,
      orderType: data.orderType.present ? data.orderType.value : this.orderType,
      tableNumber: data.tableNumber.present
          ? data.tableNumber.value
          : this.tableNumber,
      lifecycleStatus: data.lifecycleStatus.present
          ? data.lifecycleStatus.value
          : this.lifecycleStatus,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      itemDiscountTotal: data.itemDiscountTotal.present
          ? data.itemDiscountTotal.value
          : this.itemDiscountTotal,
      transactionDiscountTotal: data.transactionDiscountTotal.present
          ? data.transactionDiscountTotal.value
          : this.transactionDiscountTotal,
      discountTotal: data.discountTotal.present
          ? data.discountTotal.value
          : this.discountTotal,
      netSubtotal: data.netSubtotal.present
          ? data.netSubtotal.value
          : this.netSubtotal,
      serviceCharge: data.serviceCharge.present
          ? data.serviceCharge.value
          : this.serviceCharge,
      taxTotal: data.taxTotal.present ? data.taxTotal.value : this.taxTotal,
      total: data.total.present ? data.total.value : this.total,
      confirmedAmount: data.confirmedAmount.present
          ? data.confirmedAmount.value
          : this.confirmedAmount,
      awaitingAmount: data.awaitingAmount.present
          ? data.awaitingAmount.value
          : this.awaitingAmount,
      refundedAmount: data.refundedAmount.present
          ? data.refundedAmount.value
          : this.refundedAmount,
      shiftUuid: data.shiftUuid.present ? data.shiftUuid.value : this.shiftUuid,
      cashierName: data.cashierName.present
          ? data.cashierName.value
          : this.cashierName,
      notes: data.notes.present ? data.notes.value : this.notes,
      synced: data.synced.present ? data.synced.value : this.synced,
      transactedAt: data.transactedAt.present
          ? data.transactedAt.value
          : this.transactedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSale(')
          ..write('uuid: $uuid, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('orderUuid: $orderUuid, ')
          ..write('serverOrderUuid: $serverOrderUuid, ')
          ..write('sourceOrderVersion: $sourceOrderVersion, ')
          ..write('origin: $origin, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('lifecycleStatus: $lifecycleStatus, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('subtotal: $subtotal, ')
          ..write('itemDiscountTotal: $itemDiscountTotal, ')
          ..write('transactionDiscountTotal: $transactionDiscountTotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('netSubtotal: $netSubtotal, ')
          ..write('serviceCharge: $serviceCharge, ')
          ..write('taxTotal: $taxTotal, ')
          ..write('total: $total, ')
          ..write('confirmedAmount: $confirmedAmount, ')
          ..write('awaitingAmount: $awaitingAmount, ')
          ..write('refundedAmount: $refundedAmount, ')
          ..write('shiftUuid: $shiftUuid, ')
          ..write('cashierName: $cashierName, ')
          ..write('notes: $notes, ')
          ..write('synced: $synced, ')
          ..write('transactedAt: $transactedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    uuid,
    receiptNumber,
    orderUuid,
    serverOrderUuid,
    sourceOrderVersion,
    origin,
    orderType,
    tableNumber,
    lifecycleStatus,
    paymentStatus,
    subtotal,
    itemDiscountTotal,
    transactionDiscountTotal,
    discountTotal,
    netSubtotal,
    serviceCharge,
    taxTotal,
    total,
    confirmedAmount,
    awaitingAmount,
    refundedAmount,
    shiftUuid,
    cashierName,
    notes,
    synced,
    transactedAt,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSale &&
          other.uuid == this.uuid &&
          other.receiptNumber == this.receiptNumber &&
          other.orderUuid == this.orderUuid &&
          other.serverOrderUuid == this.serverOrderUuid &&
          other.sourceOrderVersion == this.sourceOrderVersion &&
          other.origin == this.origin &&
          other.orderType == this.orderType &&
          other.tableNumber == this.tableNumber &&
          other.lifecycleStatus == this.lifecycleStatus &&
          other.paymentStatus == this.paymentStatus &&
          other.subtotal == this.subtotal &&
          other.itemDiscountTotal == this.itemDiscountTotal &&
          other.transactionDiscountTotal == this.transactionDiscountTotal &&
          other.discountTotal == this.discountTotal &&
          other.netSubtotal == this.netSubtotal &&
          other.serviceCharge == this.serviceCharge &&
          other.taxTotal == this.taxTotal &&
          other.total == this.total &&
          other.confirmedAmount == this.confirmedAmount &&
          other.awaitingAmount == this.awaitingAmount &&
          other.refundedAmount == this.refundedAmount &&
          other.shiftUuid == this.shiftUuid &&
          other.cashierName == this.cashierName &&
          other.notes == this.notes &&
          other.synced == this.synced &&
          other.transactedAt == this.transactedAt &&
          other.createdAt == this.createdAt);
}

class LocalSalesCompanion extends UpdateCompanion<LocalSale> {
  final Value<String> uuid;
  final Value<String> receiptNumber;
  final Value<String?> orderUuid;
  final Value<String?> serverOrderUuid;
  final Value<int> sourceOrderVersion;
  final Value<String> origin;
  final Value<String> orderType;
  final Value<String?> tableNumber;
  final Value<String> lifecycleStatus;
  final Value<String> paymentStatus;
  final Value<int> subtotal;
  final Value<int> itemDiscountTotal;
  final Value<int> transactionDiscountTotal;
  final Value<int> discountTotal;
  final Value<int> netSubtotal;
  final Value<int> serviceCharge;
  final Value<int> taxTotal;
  final Value<int> total;
  final Value<int> confirmedAmount;
  final Value<int> awaitingAmount;
  final Value<int> refundedAmount;
  final Value<String?> shiftUuid;
  final Value<String?> cashierName;
  final Value<String?> notes;
  final Value<bool> synced;
  final Value<DateTime> transactedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalSalesCompanion({
    this.uuid = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.orderUuid = const Value.absent(),
    this.serverOrderUuid = const Value.absent(),
    this.sourceOrderVersion = const Value.absent(),
    this.origin = const Value.absent(),
    this.orderType = const Value.absent(),
    this.tableNumber = const Value.absent(),
    this.lifecycleStatus = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.itemDiscountTotal = const Value.absent(),
    this.transactionDiscountTotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.netSubtotal = const Value.absent(),
    this.serviceCharge = const Value.absent(),
    this.taxTotal = const Value.absent(),
    this.total = const Value.absent(),
    this.confirmedAmount = const Value.absent(),
    this.awaitingAmount = const Value.absent(),
    this.refundedAmount = const Value.absent(),
    this.shiftUuid = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.notes = const Value.absent(),
    this.synced = const Value.absent(),
    this.transactedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSalesCompanion.insert({
    required String uuid,
    required String receiptNumber,
    this.orderUuid = const Value.absent(),
    this.serverOrderUuid = const Value.absent(),
    this.sourceOrderVersion = const Value.absent(),
    this.origin = const Value.absent(),
    required String orderType,
    this.tableNumber = const Value.absent(),
    this.lifecycleStatus = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    required int subtotal,
    this.itemDiscountTotal = const Value.absent(),
    this.transactionDiscountTotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.netSubtotal = const Value.absent(),
    this.serviceCharge = const Value.absent(),
    this.taxTotal = const Value.absent(),
    required int total,
    this.confirmedAmount = const Value.absent(),
    this.awaitingAmount = const Value.absent(),
    this.refundedAmount = const Value.absent(),
    this.shiftUuid = const Value.absent(),
    this.cashierName = const Value.absent(),
    this.notes = const Value.absent(),
    this.synced = const Value.absent(),
    required DateTime transactedAt,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       receiptNumber = Value(receiptNumber),
       orderType = Value(orderType),
       subtotal = Value(subtotal),
       total = Value(total),
       transactedAt = Value(transactedAt),
       createdAt = Value(createdAt);
  static Insertable<LocalSale> custom({
    Expression<String>? uuid,
    Expression<String>? receiptNumber,
    Expression<String>? orderUuid,
    Expression<String>? serverOrderUuid,
    Expression<int>? sourceOrderVersion,
    Expression<String>? origin,
    Expression<String>? orderType,
    Expression<String>? tableNumber,
    Expression<String>? lifecycleStatus,
    Expression<String>? paymentStatus,
    Expression<int>? subtotal,
    Expression<int>? itemDiscountTotal,
    Expression<int>? transactionDiscountTotal,
    Expression<int>? discountTotal,
    Expression<int>? netSubtotal,
    Expression<int>? serviceCharge,
    Expression<int>? taxTotal,
    Expression<int>? total,
    Expression<int>? confirmedAmount,
    Expression<int>? awaitingAmount,
    Expression<int>? refundedAmount,
    Expression<String>? shiftUuid,
    Expression<String>? cashierName,
    Expression<String>? notes,
    Expression<bool>? synced,
    Expression<DateTime>? transactedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (orderUuid != null) 'order_uuid': orderUuid,
      if (serverOrderUuid != null) 'server_order_uuid': serverOrderUuid,
      if (sourceOrderVersion != null)
        'source_order_version': sourceOrderVersion,
      if (origin != null) 'origin': origin,
      if (orderType != null) 'order_type': orderType,
      if (tableNumber != null) 'table_number': tableNumber,
      if (lifecycleStatus != null) 'lifecycle_status': lifecycleStatus,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (subtotal != null) 'subtotal': subtotal,
      if (itemDiscountTotal != null) 'item_discount_total': itemDiscountTotal,
      if (transactionDiscountTotal != null)
        'transaction_discount_total': transactionDiscountTotal,
      if (discountTotal != null) 'discount_total': discountTotal,
      if (netSubtotal != null) 'net_subtotal': netSubtotal,
      if (serviceCharge != null) 'service_charge': serviceCharge,
      if (taxTotal != null) 'tax_total': taxTotal,
      if (total != null) 'total': total,
      if (confirmedAmount != null) 'confirmed_amount': confirmedAmount,
      if (awaitingAmount != null) 'awaiting_amount': awaitingAmount,
      if (refundedAmount != null) 'refunded_amount': refundedAmount,
      if (shiftUuid != null) 'shift_uuid': shiftUuid,
      if (cashierName != null) 'cashier_name': cashierName,
      if (notes != null) 'notes': notes,
      if (synced != null) 'synced': synced,
      if (transactedAt != null) 'transacted_at': transactedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSalesCompanion copyWith({
    Value<String>? uuid,
    Value<String>? receiptNumber,
    Value<String?>? orderUuid,
    Value<String?>? serverOrderUuid,
    Value<int>? sourceOrderVersion,
    Value<String>? origin,
    Value<String>? orderType,
    Value<String?>? tableNumber,
    Value<String>? lifecycleStatus,
    Value<String>? paymentStatus,
    Value<int>? subtotal,
    Value<int>? itemDiscountTotal,
    Value<int>? transactionDiscountTotal,
    Value<int>? discountTotal,
    Value<int>? netSubtotal,
    Value<int>? serviceCharge,
    Value<int>? taxTotal,
    Value<int>? total,
    Value<int>? confirmedAmount,
    Value<int>? awaitingAmount,
    Value<int>? refundedAmount,
    Value<String?>? shiftUuid,
    Value<String?>? cashierName,
    Value<String?>? notes,
    Value<bool>? synced,
    Value<DateTime>? transactedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalSalesCompanion(
      uuid: uuid ?? this.uuid,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      orderUuid: orderUuid ?? this.orderUuid,
      serverOrderUuid: serverOrderUuid ?? this.serverOrderUuid,
      sourceOrderVersion: sourceOrderVersion ?? this.sourceOrderVersion,
      origin: origin ?? this.origin,
      orderType: orderType ?? this.orderType,
      tableNumber: tableNumber ?? this.tableNumber,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      itemDiscountTotal: itemDiscountTotal ?? this.itemDiscountTotal,
      transactionDiscountTotal:
          transactionDiscountTotal ?? this.transactionDiscountTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      netSubtotal: netSubtotal ?? this.netSubtotal,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      taxTotal: taxTotal ?? this.taxTotal,
      total: total ?? this.total,
      confirmedAmount: confirmedAmount ?? this.confirmedAmount,
      awaitingAmount: awaitingAmount ?? this.awaitingAmount,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      shiftUuid: shiftUuid ?? this.shiftUuid,
      cashierName: cashierName ?? this.cashierName,
      notes: notes ?? this.notes,
      synced: synced ?? this.synced,
      transactedAt: transactedAt ?? this.transactedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<String>(receiptNumber.value);
    }
    if (orderUuid.present) {
      map['order_uuid'] = Variable<String>(orderUuid.value);
    }
    if (serverOrderUuid.present) {
      map['server_order_uuid'] = Variable<String>(serverOrderUuid.value);
    }
    if (sourceOrderVersion.present) {
      map['source_order_version'] = Variable<int>(sourceOrderVersion.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (orderType.present) {
      map['order_type'] = Variable<String>(orderType.value);
    }
    if (tableNumber.present) {
      map['table_number'] = Variable<String>(tableNumber.value);
    }
    if (lifecycleStatus.present) {
      map['lifecycle_status'] = Variable<String>(lifecycleStatus.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (itemDiscountTotal.present) {
      map['item_discount_total'] = Variable<int>(itemDiscountTotal.value);
    }
    if (transactionDiscountTotal.present) {
      map['transaction_discount_total'] = Variable<int>(
        transactionDiscountTotal.value,
      );
    }
    if (discountTotal.present) {
      map['discount_total'] = Variable<int>(discountTotal.value);
    }
    if (netSubtotal.present) {
      map['net_subtotal'] = Variable<int>(netSubtotal.value);
    }
    if (serviceCharge.present) {
      map['service_charge'] = Variable<int>(serviceCharge.value);
    }
    if (taxTotal.present) {
      map['tax_total'] = Variable<int>(taxTotal.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (confirmedAmount.present) {
      map['confirmed_amount'] = Variable<int>(confirmedAmount.value);
    }
    if (awaitingAmount.present) {
      map['awaiting_amount'] = Variable<int>(awaitingAmount.value);
    }
    if (refundedAmount.present) {
      map['refunded_amount'] = Variable<int>(refundedAmount.value);
    }
    if (shiftUuid.present) {
      map['shift_uuid'] = Variable<String>(shiftUuid.value);
    }
    if (cashierName.present) {
      map['cashier_name'] = Variable<String>(cashierName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (transactedAt.present) {
      map['transacted_at'] = Variable<DateTime>(transactedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSalesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('orderUuid: $orderUuid, ')
          ..write('serverOrderUuid: $serverOrderUuid, ')
          ..write('sourceOrderVersion: $sourceOrderVersion, ')
          ..write('origin: $origin, ')
          ..write('orderType: $orderType, ')
          ..write('tableNumber: $tableNumber, ')
          ..write('lifecycleStatus: $lifecycleStatus, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('subtotal: $subtotal, ')
          ..write('itemDiscountTotal: $itemDiscountTotal, ')
          ..write('transactionDiscountTotal: $transactionDiscountTotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('netSubtotal: $netSubtotal, ')
          ..write('serviceCharge: $serviceCharge, ')
          ..write('taxTotal: $taxTotal, ')
          ..write('total: $total, ')
          ..write('confirmedAmount: $confirmedAmount, ')
          ..write('awaitingAmount: $awaitingAmount, ')
          ..write('refundedAmount: $refundedAmount, ')
          ..write('shiftUuid: $shiftUuid, ')
          ..write('cashierName: $cashierName, ')
          ..write('notes: $notes, ')
          ..write('synced: $synced, ')
          ..write('transactedAt: $transactedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SaleItemsTable extends SaleItems
    with TableInfo<$SaleItemsTable, SaleItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SaleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleUuidMeta = const VerificationMeta(
    'saleUuid',
  );
  @override
  late final GeneratedColumn<String> saleUuid = GeneratedColumn<String>(
    'sale_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_sales (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productUuidMeta = const VerificationMeta(
    'productUuid',
  );
  @override
  late final GeneratedColumn<String> productUuid = GeneratedColumn<String>(
    'product_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantUuidMeta = const VerificationMeta(
    'variantUuid',
  );
  @override
  late final GeneratedColumn<String> variantUuid = GeneratedColumn<String>(
    'variant_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addonsJsonMeta = const VerificationMeta(
    'addonsJson',
  );
  @override
  late final GeneratedColumn<String> addonsJson = GeneratedColumn<String>(
    'addons_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemDiscountMeta = const VerificationMeta(
    'itemDiscount',
  );
  @override
  late final GeneratedColumn<int> itemDiscount = GeneratedColumn<int>(
    'item_discount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineSubtotalMeta = const VerificationMeta(
    'lineSubtotal',
  );
  @override
  late final GeneratedColumn<int> lineSubtotal = GeneratedColumn<int>(
    'line_subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lineTotalMeta = const VerificationMeta(
    'lineTotal',
  );
  @override
  late final GeneratedColumn<int> lineTotal = GeneratedColumn<int>(
    'line_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleUuid,
    productUuid,
    productName,
    variantUuid,
    variantName,
    addonsJson,
    unitPrice,
    quantity,
    itemDiscount,
    lineSubtotal,
    lineTotal,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SaleItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_uuid')) {
      context.handle(
        _saleUuidMeta,
        saleUuid.isAcceptableOrUnknown(data['sale_uuid']!, _saleUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_saleUuidMeta);
    }
    if (data.containsKey('product_uuid')) {
      context.handle(
        _productUuidMeta,
        productUuid.isAcceptableOrUnknown(
          data['product_uuid']!,
          _productUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productUuidMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_uuid')) {
      context.handle(
        _variantUuidMeta,
        variantUuid.isAcceptableOrUnknown(
          data['variant_uuid']!,
          _variantUuidMeta,
        ),
      );
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    }
    if (data.containsKey('addons_json')) {
      context.handle(
        _addonsJsonMeta,
        addonsJson.isAcceptableOrUnknown(data['addons_json']!, _addonsJsonMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('item_discount')) {
      context.handle(
        _itemDiscountMeta,
        itemDiscount.isAcceptableOrUnknown(
          data['item_discount']!,
          _itemDiscountMeta,
        ),
      );
    }
    if (data.containsKey('line_subtotal')) {
      context.handle(
        _lineSubtotalMeta,
        lineSubtotal.isAcceptableOrUnknown(
          data['line_subtotal']!,
          _lineSubtotalMeta,
        ),
      );
    }
    if (data.containsKey('line_total')) {
      context.handle(
        _lineTotalMeta,
        lineTotal.isAcceptableOrUnknown(data['line_total']!, _lineTotalMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SaleItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SaleItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      saleUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_uuid'],
      )!,
      productUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_uuid'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_uuid'],
      ),
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      ),
      addonsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}addons_json'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      itemDiscount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_discount'],
      )!,
      lineSubtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_subtotal'],
      )!,
      lineTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_total'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $SaleItemsTable createAlias(String alias) {
    return $SaleItemsTable(attachedDatabase, alias);
  }
}

class SaleItem extends DataClass implements Insertable<SaleItem> {
  final int id;
  final String saleUuid;
  final String productUuid;
  final String productName;
  final String? variantUuid;
  final String? variantName;
  final String addonsJson;
  final int unitPrice;
  final int quantity;
  final int itemDiscount;
  final int lineSubtotal;
  final int lineTotal;
  final String? notes;
  const SaleItem({
    required this.id,
    required this.saleUuid,
    required this.productUuid,
    required this.productName,
    this.variantUuid,
    this.variantName,
    required this.addonsJson,
    required this.unitPrice,
    required this.quantity,
    required this.itemDiscount,
    required this.lineSubtotal,
    required this.lineTotal,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_uuid'] = Variable<String>(saleUuid);
    map['product_uuid'] = Variable<String>(productUuid);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || variantUuid != null) {
      map['variant_uuid'] = Variable<String>(variantUuid);
    }
    if (!nullToAbsent || variantName != null) {
      map['variant_name'] = Variable<String>(variantName);
    }
    map['addons_json'] = Variable<String>(addonsJson);
    map['unit_price'] = Variable<int>(unitPrice);
    map['quantity'] = Variable<int>(quantity);
    map['item_discount'] = Variable<int>(itemDiscount);
    map['line_subtotal'] = Variable<int>(lineSubtotal);
    map['line_total'] = Variable<int>(lineTotal);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  SaleItemsCompanion toCompanion(bool nullToAbsent) {
    return SaleItemsCompanion(
      id: Value(id),
      saleUuid: Value(saleUuid),
      productUuid: Value(productUuid),
      productName: Value(productName),
      variantUuid: variantUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(variantUuid),
      variantName: variantName == null && nullToAbsent
          ? const Value.absent()
          : Value(variantName),
      addonsJson: Value(addonsJson),
      unitPrice: Value(unitPrice),
      quantity: Value(quantity),
      itemDiscount: Value(itemDiscount),
      lineSubtotal: Value(lineSubtotal),
      lineTotal: Value(lineTotal),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory SaleItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SaleItem(
      id: serializer.fromJson<int>(json['id']),
      saleUuid: serializer.fromJson<String>(json['saleUuid']),
      productUuid: serializer.fromJson<String>(json['productUuid']),
      productName: serializer.fromJson<String>(json['productName']),
      variantUuid: serializer.fromJson<String?>(json['variantUuid']),
      variantName: serializer.fromJson<String?>(json['variantName']),
      addonsJson: serializer.fromJson<String>(json['addonsJson']),
      unitPrice: serializer.fromJson<int>(json['unitPrice']),
      quantity: serializer.fromJson<int>(json['quantity']),
      itemDiscount: serializer.fromJson<int>(json['itemDiscount']),
      lineSubtotal: serializer.fromJson<int>(json['lineSubtotal']),
      lineTotal: serializer.fromJson<int>(json['lineTotal']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleUuid': serializer.toJson<String>(saleUuid),
      'productUuid': serializer.toJson<String>(productUuid),
      'productName': serializer.toJson<String>(productName),
      'variantUuid': serializer.toJson<String?>(variantUuid),
      'variantName': serializer.toJson<String?>(variantName),
      'addonsJson': serializer.toJson<String>(addonsJson),
      'unitPrice': serializer.toJson<int>(unitPrice),
      'quantity': serializer.toJson<int>(quantity),
      'itemDiscount': serializer.toJson<int>(itemDiscount),
      'lineSubtotal': serializer.toJson<int>(lineSubtotal),
      'lineTotal': serializer.toJson<int>(lineTotal),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  SaleItem copyWith({
    int? id,
    String? saleUuid,
    String? productUuid,
    String? productName,
    Value<String?> variantUuid = const Value.absent(),
    Value<String?> variantName = const Value.absent(),
    String? addonsJson,
    int? unitPrice,
    int? quantity,
    int? itemDiscount,
    int? lineSubtotal,
    int? lineTotal,
    Value<String?> notes = const Value.absent(),
  }) => SaleItem(
    id: id ?? this.id,
    saleUuid: saleUuid ?? this.saleUuid,
    productUuid: productUuid ?? this.productUuid,
    productName: productName ?? this.productName,
    variantUuid: variantUuid.present ? variantUuid.value : this.variantUuid,
    variantName: variantName.present ? variantName.value : this.variantName,
    addonsJson: addonsJson ?? this.addonsJson,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    itemDiscount: itemDiscount ?? this.itemDiscount,
    lineSubtotal: lineSubtotal ?? this.lineSubtotal,
    lineTotal: lineTotal ?? this.lineTotal,
    notes: notes.present ? notes.value : this.notes,
  );
  SaleItem copyWithCompanion(SaleItemsCompanion data) {
    return SaleItem(
      id: data.id.present ? data.id.value : this.id,
      saleUuid: data.saleUuid.present ? data.saleUuid.value : this.saleUuid,
      productUuid: data.productUuid.present
          ? data.productUuid.value
          : this.productUuid,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantUuid: data.variantUuid.present
          ? data.variantUuid.value
          : this.variantUuid,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      addonsJson: data.addonsJson.present
          ? data.addonsJson.value
          : this.addonsJson,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      itemDiscount: data.itemDiscount.present
          ? data.itemDiscount.value
          : this.itemDiscount,
      lineSubtotal: data.lineSubtotal.present
          ? data.lineSubtotal.value
          : this.lineSubtotal,
      lineTotal: data.lineTotal.present ? data.lineTotal.value : this.lineTotal,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SaleItem(')
          ..write('id: $id, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('productName: $productName, ')
          ..write('variantUuid: $variantUuid, ')
          ..write('variantName: $variantName, ')
          ..write('addonsJson: $addonsJson, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('itemDiscount: $itemDiscount, ')
          ..write('lineSubtotal: $lineSubtotal, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleUuid,
    productUuid,
    productName,
    variantUuid,
    variantName,
    addonsJson,
    unitPrice,
    quantity,
    itemDiscount,
    lineSubtotal,
    lineTotal,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SaleItem &&
          other.id == this.id &&
          other.saleUuid == this.saleUuid &&
          other.productUuid == this.productUuid &&
          other.productName == this.productName &&
          other.variantUuid == this.variantUuid &&
          other.variantName == this.variantName &&
          other.addonsJson == this.addonsJson &&
          other.unitPrice == this.unitPrice &&
          other.quantity == this.quantity &&
          other.itemDiscount == this.itemDiscount &&
          other.lineSubtotal == this.lineSubtotal &&
          other.lineTotal == this.lineTotal &&
          other.notes == this.notes);
}

class SaleItemsCompanion extends UpdateCompanion<SaleItem> {
  final Value<int> id;
  final Value<String> saleUuid;
  final Value<String> productUuid;
  final Value<String> productName;
  final Value<String?> variantUuid;
  final Value<String?> variantName;
  final Value<String> addonsJson;
  final Value<int> unitPrice;
  final Value<int> quantity;
  final Value<int> itemDiscount;
  final Value<int> lineSubtotal;
  final Value<int> lineTotal;
  final Value<String?> notes;
  const SaleItemsCompanion({
    this.id = const Value.absent(),
    this.saleUuid = const Value.absent(),
    this.productUuid = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantUuid = const Value.absent(),
    this.variantName = const Value.absent(),
    this.addonsJson = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.itemDiscount = const Value.absent(),
    this.lineSubtotal = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.notes = const Value.absent(),
  });
  SaleItemsCompanion.insert({
    this.id = const Value.absent(),
    required String saleUuid,
    required String productUuid,
    required String productName,
    this.variantUuid = const Value.absent(),
    this.variantName = const Value.absent(),
    this.addonsJson = const Value.absent(),
    required int unitPrice,
    required int quantity,
    this.itemDiscount = const Value.absent(),
    this.lineSubtotal = const Value.absent(),
    this.lineTotal = const Value.absent(),
    this.notes = const Value.absent(),
  }) : saleUuid = Value(saleUuid),
       productUuid = Value(productUuid),
       productName = Value(productName),
       unitPrice = Value(unitPrice),
       quantity = Value(quantity);
  static Insertable<SaleItem> custom({
    Expression<int>? id,
    Expression<String>? saleUuid,
    Expression<String>? productUuid,
    Expression<String>? productName,
    Expression<String>? variantUuid,
    Expression<String>? variantName,
    Expression<String>? addonsJson,
    Expression<int>? unitPrice,
    Expression<int>? quantity,
    Expression<int>? itemDiscount,
    Expression<int>? lineSubtotal,
    Expression<int>? lineTotal,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleUuid != null) 'sale_uuid': saleUuid,
      if (productUuid != null) 'product_uuid': productUuid,
      if (productName != null) 'product_name': productName,
      if (variantUuid != null) 'variant_uuid': variantUuid,
      if (variantName != null) 'variant_name': variantName,
      if (addonsJson != null) 'addons_json': addonsJson,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (quantity != null) 'quantity': quantity,
      if (itemDiscount != null) 'item_discount': itemDiscount,
      if (lineSubtotal != null) 'line_subtotal': lineSubtotal,
      if (lineTotal != null) 'line_total': lineTotal,
      if (notes != null) 'notes': notes,
    });
  }

  SaleItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? saleUuid,
    Value<String>? productUuid,
    Value<String>? productName,
    Value<String?>? variantUuid,
    Value<String?>? variantName,
    Value<String>? addonsJson,
    Value<int>? unitPrice,
    Value<int>? quantity,
    Value<int>? itemDiscount,
    Value<int>? lineSubtotal,
    Value<int>? lineTotal,
    Value<String?>? notes,
  }) {
    return SaleItemsCompanion(
      id: id ?? this.id,
      saleUuid: saleUuid ?? this.saleUuid,
      productUuid: productUuid ?? this.productUuid,
      productName: productName ?? this.productName,
      variantUuid: variantUuid ?? this.variantUuid,
      variantName: variantName ?? this.variantName,
      addonsJson: addonsJson ?? this.addonsJson,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      itemDiscount: itemDiscount ?? this.itemDiscount,
      lineSubtotal: lineSubtotal ?? this.lineSubtotal,
      lineTotal: lineTotal ?? this.lineTotal,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleUuid.present) {
      map['sale_uuid'] = Variable<String>(saleUuid.value);
    }
    if (productUuid.present) {
      map['product_uuid'] = Variable<String>(productUuid.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantUuid.present) {
      map['variant_uuid'] = Variable<String>(variantUuid.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (addonsJson.present) {
      map['addons_json'] = Variable<String>(addonsJson.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (itemDiscount.present) {
      map['item_discount'] = Variable<int>(itemDiscount.value);
    }
    if (lineSubtotal.present) {
      map['line_subtotal'] = Variable<int>(lineSubtotal.value);
    }
    if (lineTotal.present) {
      map['line_total'] = Variable<int>(lineTotal.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SaleItemsCompanion(')
          ..write('id: $id, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('productUuid: $productUuid, ')
          ..write('productName: $productName, ')
          ..write('variantUuid: $variantUuid, ')
          ..write('variantName: $variantName, ')
          ..write('addonsJson: $addonsJson, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('itemDiscount: $itemDiscount, ')
          ..write('lineSubtotal: $lineSubtotal, ')
          ..write('lineTotal: $lineTotal, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $SalePaymentsTable extends SalePayments
    with TableInfo<$SalePaymentsTable, SalePayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalePaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleUuidMeta = const VerificationMeta(
    'saleUuid',
  );
  @override
  late final GeneratedColumn<String> saleUuid = GeneratedColumn<String>(
    'sale_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_sales (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _paymentUuidMeta = const VerificationMeta(
    'paymentUuid',
  );
  @override
  late final GeneratedColumn<String> paymentUuid = GeneratedColumn<String>(
    'payment_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tenderedAmountMeta = const VerificationMeta(
    'tenderedAmount',
  );
  @override
  late final GeneratedColumn<int> tenderedAmount = GeneratedColumn<int>(
    'tendered_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _changeAmountMeta = const VerificationMeta(
    'changeAmount',
  );
  @override
  late final GeneratedColumn<int> changeAmount = GeneratedColumn<int>(
    'change_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAmountMeta = const VerificationMeta(
    'verifiedAmount',
  );
  @override
  late final GeneratedColumn<int> verifiedAmount = GeneratedColumn<int>(
    'verified_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerReferenceMeta = const VerificationMeta(
    'providerReference',
  );
  @override
  late final GeneratedColumn<String> providerReference =
      GeneratedColumn<String>(
        'provider_reference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confirmedAtMeta = const VerificationMeta(
    'confirmedAt',
  );
  @override
  late final GeneratedColumn<DateTime> confirmedAt = GeneratedColumn<DateTime>(
    'confirmed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleUuid,
    paymentUuid,
    method,
    amount,
    tenderedAmount,
    changeAmount,
    verifiedAmount,
    status,
    providerReference,
    idempotencyKey,
    notes,
    createdAt,
    confirmedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sale_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<SalePayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_uuid')) {
      context.handle(
        _saleUuidMeta,
        saleUuid.isAcceptableOrUnknown(data['sale_uuid']!, _saleUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_saleUuidMeta);
    }
    if (data.containsKey('payment_uuid')) {
      context.handle(
        _paymentUuidMeta,
        paymentUuid.isAcceptableOrUnknown(
          data['payment_uuid']!,
          _paymentUuidMeta,
        ),
      );
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('tendered_amount')) {
      context.handle(
        _tenderedAmountMeta,
        tenderedAmount.isAcceptableOrUnknown(
          data['tendered_amount']!,
          _tenderedAmountMeta,
        ),
      );
    }
    if (data.containsKey('change_amount')) {
      context.handle(
        _changeAmountMeta,
        changeAmount.isAcceptableOrUnknown(
          data['change_amount']!,
          _changeAmountMeta,
        ),
      );
    }
    if (data.containsKey('verified_amount')) {
      context.handle(
        _verifiedAmountMeta,
        verifiedAmount.isAcceptableOrUnknown(
          data['verified_amount']!,
          _verifiedAmountMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('provider_reference')) {
      context.handle(
        _providerReferenceMeta,
        providerReference.isAcceptableOrUnknown(
          data['provider_reference']!,
          _providerReferenceMeta,
        ),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('confirmed_at')) {
      context.handle(
        _confirmedAtMeta,
        confirmedAt.isAcceptableOrUnknown(
          data['confirmed_at']!,
          _confirmedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SalePayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SalePayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      saleUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_uuid'],
      )!,
      paymentUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_uuid'],
      ),
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      tenderedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tendered_amount'],
      ),
      changeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_amount'],
      ),
      verifiedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_amount'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      providerReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_reference'],
      ),
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      confirmedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}confirmed_at'],
      ),
    );
  }

  @override
  $SalePaymentsTable createAlias(String alias) {
    return $SalePaymentsTable(attachedDatabase, alias);
  }
}

class SalePayment extends DataClass implements Insertable<SalePayment> {
  final int id;
  final String saleUuid;
  final String? paymentUuid;
  final String method;
  final int amount;
  final int? tenderedAmount;
  final int? changeAmount;
  final int? verifiedAmount;
  final String status;
  final String? providerReference;
  final String? idempotencyKey;
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  const SalePayment({
    required this.id,
    required this.saleUuid,
    this.paymentUuid,
    required this.method,
    required this.amount,
    this.tenderedAmount,
    this.changeAmount,
    this.verifiedAmount,
    required this.status,
    this.providerReference,
    this.idempotencyKey,
    this.notes,
    required this.createdAt,
    this.confirmedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_uuid'] = Variable<String>(saleUuid);
    if (!nullToAbsent || paymentUuid != null) {
      map['payment_uuid'] = Variable<String>(paymentUuid);
    }
    map['method'] = Variable<String>(method);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || tenderedAmount != null) {
      map['tendered_amount'] = Variable<int>(tenderedAmount);
    }
    if (!nullToAbsent || changeAmount != null) {
      map['change_amount'] = Variable<int>(changeAmount);
    }
    if (!nullToAbsent || verifiedAmount != null) {
      map['verified_amount'] = Variable<int>(verifiedAmount);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || providerReference != null) {
      map['provider_reference'] = Variable<String>(providerReference);
    }
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || confirmedAt != null) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt);
    }
    return map;
  }

  SalePaymentsCompanion toCompanion(bool nullToAbsent) {
    return SalePaymentsCompanion(
      id: Value(id),
      saleUuid: Value(saleUuid),
      paymentUuid: paymentUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentUuid),
      method: Value(method),
      amount: Value(amount),
      tenderedAmount: tenderedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(tenderedAmount),
      changeAmount: changeAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(changeAmount),
      verifiedAmount: verifiedAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAmount),
      status: Value(status),
      providerReference: providerReference == null && nullToAbsent
          ? const Value.absent()
          : Value(providerReference),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      confirmedAt: confirmedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(confirmedAt),
    );
  }

  factory SalePayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SalePayment(
      id: serializer.fromJson<int>(json['id']),
      saleUuid: serializer.fromJson<String>(json['saleUuid']),
      paymentUuid: serializer.fromJson<String?>(json['paymentUuid']),
      method: serializer.fromJson<String>(json['method']),
      amount: serializer.fromJson<int>(json['amount']),
      tenderedAmount: serializer.fromJson<int?>(json['tenderedAmount']),
      changeAmount: serializer.fromJson<int?>(json['changeAmount']),
      verifiedAmount: serializer.fromJson<int?>(json['verifiedAmount']),
      status: serializer.fromJson<String>(json['status']),
      providerReference: serializer.fromJson<String?>(
        json['providerReference'],
      ),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      confirmedAt: serializer.fromJson<DateTime?>(json['confirmedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleUuid': serializer.toJson<String>(saleUuid),
      'paymentUuid': serializer.toJson<String?>(paymentUuid),
      'method': serializer.toJson<String>(method),
      'amount': serializer.toJson<int>(amount),
      'tenderedAmount': serializer.toJson<int?>(tenderedAmount),
      'changeAmount': serializer.toJson<int?>(changeAmount),
      'verifiedAmount': serializer.toJson<int?>(verifiedAmount),
      'status': serializer.toJson<String>(status),
      'providerReference': serializer.toJson<String?>(providerReference),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'confirmedAt': serializer.toJson<DateTime?>(confirmedAt),
    };
  }

  SalePayment copyWith({
    int? id,
    String? saleUuid,
    Value<String?> paymentUuid = const Value.absent(),
    String? method,
    int? amount,
    Value<int?> tenderedAmount = const Value.absent(),
    Value<int?> changeAmount = const Value.absent(),
    Value<int?> verifiedAmount = const Value.absent(),
    String? status,
    Value<String?> providerReference = const Value.absent(),
    Value<String?> idempotencyKey = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> confirmedAt = const Value.absent(),
  }) => SalePayment(
    id: id ?? this.id,
    saleUuid: saleUuid ?? this.saleUuid,
    paymentUuid: paymentUuid.present ? paymentUuid.value : this.paymentUuid,
    method: method ?? this.method,
    amount: amount ?? this.amount,
    tenderedAmount: tenderedAmount.present
        ? tenderedAmount.value
        : this.tenderedAmount,
    changeAmount: changeAmount.present ? changeAmount.value : this.changeAmount,
    verifiedAmount: verifiedAmount.present
        ? verifiedAmount.value
        : this.verifiedAmount,
    status: status ?? this.status,
    providerReference: providerReference.present
        ? providerReference.value
        : this.providerReference,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    confirmedAt: confirmedAt.present ? confirmedAt.value : this.confirmedAt,
  );
  SalePayment copyWithCompanion(SalePaymentsCompanion data) {
    return SalePayment(
      id: data.id.present ? data.id.value : this.id,
      saleUuid: data.saleUuid.present ? data.saleUuid.value : this.saleUuid,
      paymentUuid: data.paymentUuid.present
          ? data.paymentUuid.value
          : this.paymentUuid,
      method: data.method.present ? data.method.value : this.method,
      amount: data.amount.present ? data.amount.value : this.amount,
      tenderedAmount: data.tenderedAmount.present
          ? data.tenderedAmount.value
          : this.tenderedAmount,
      changeAmount: data.changeAmount.present
          ? data.changeAmount.value
          : this.changeAmount,
      verifiedAmount: data.verifiedAmount.present
          ? data.verifiedAmount.value
          : this.verifiedAmount,
      status: data.status.present ? data.status.value : this.status,
      providerReference: data.providerReference.present
          ? data.providerReference.value
          : this.providerReference,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      confirmedAt: data.confirmedAt.present
          ? data.confirmedAt.value
          : this.confirmedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SalePayment(')
          ..write('id: $id, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('paymentUuid: $paymentUuid, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('tenderedAmount: $tenderedAmount, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('verifiedAmount: $verifiedAmount, ')
          ..write('status: $status, ')
          ..write('providerReference: $providerReference, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleUuid,
    paymentUuid,
    method,
    amount,
    tenderedAmount,
    changeAmount,
    verifiedAmount,
    status,
    providerReference,
    idempotencyKey,
    notes,
    createdAt,
    confirmedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SalePayment &&
          other.id == this.id &&
          other.saleUuid == this.saleUuid &&
          other.paymentUuid == this.paymentUuid &&
          other.method == this.method &&
          other.amount == this.amount &&
          other.tenderedAmount == this.tenderedAmount &&
          other.changeAmount == this.changeAmount &&
          other.verifiedAmount == this.verifiedAmount &&
          other.status == this.status &&
          other.providerReference == this.providerReference &&
          other.idempotencyKey == this.idempotencyKey &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.confirmedAt == this.confirmedAt);
}

class SalePaymentsCompanion extends UpdateCompanion<SalePayment> {
  final Value<int> id;
  final Value<String> saleUuid;
  final Value<String?> paymentUuid;
  final Value<String> method;
  final Value<int> amount;
  final Value<int?> tenderedAmount;
  final Value<int?> changeAmount;
  final Value<int?> verifiedAmount;
  final Value<String> status;
  final Value<String?> providerReference;
  final Value<String?> idempotencyKey;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> confirmedAt;
  const SalePaymentsCompanion({
    this.id = const Value.absent(),
    this.saleUuid = const Value.absent(),
    this.paymentUuid = const Value.absent(),
    this.method = const Value.absent(),
    this.amount = const Value.absent(),
    this.tenderedAmount = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.verifiedAmount = const Value.absent(),
    this.status = const Value.absent(),
    this.providerReference = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.confirmedAt = const Value.absent(),
  });
  SalePaymentsCompanion.insert({
    this.id = const Value.absent(),
    required String saleUuid,
    this.paymentUuid = const Value.absent(),
    required String method,
    required int amount,
    this.tenderedAmount = const Value.absent(),
    this.changeAmount = const Value.absent(),
    this.verifiedAmount = const Value.absent(),
    required String status,
    this.providerReference = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.confirmedAt = const Value.absent(),
  }) : saleUuid = Value(saleUuid),
       method = Value(method),
       amount = Value(amount),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<SalePayment> custom({
    Expression<int>? id,
    Expression<String>? saleUuid,
    Expression<String>? paymentUuid,
    Expression<String>? method,
    Expression<int>? amount,
    Expression<int>? tenderedAmount,
    Expression<int>? changeAmount,
    Expression<int>? verifiedAmount,
    Expression<String>? status,
    Expression<String>? providerReference,
    Expression<String>? idempotencyKey,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? confirmedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleUuid != null) 'sale_uuid': saleUuid,
      if (paymentUuid != null) 'payment_uuid': paymentUuid,
      if (method != null) 'method': method,
      if (amount != null) 'amount': amount,
      if (tenderedAmount != null) 'tendered_amount': tenderedAmount,
      if (changeAmount != null) 'change_amount': changeAmount,
      if (verifiedAmount != null) 'verified_amount': verifiedAmount,
      if (status != null) 'status': status,
      if (providerReference != null) 'provider_reference': providerReference,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (confirmedAt != null) 'confirmed_at': confirmedAt,
    });
  }

  SalePaymentsCompanion copyWith({
    Value<int>? id,
    Value<String>? saleUuid,
    Value<String?>? paymentUuid,
    Value<String>? method,
    Value<int>? amount,
    Value<int?>? tenderedAmount,
    Value<int?>? changeAmount,
    Value<int?>? verifiedAmount,
    Value<String>? status,
    Value<String?>? providerReference,
    Value<String?>? idempotencyKey,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? confirmedAt,
  }) {
    return SalePaymentsCompanion(
      id: id ?? this.id,
      saleUuid: saleUuid ?? this.saleUuid,
      paymentUuid: paymentUuid ?? this.paymentUuid,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      tenderedAmount: tenderedAmount ?? this.tenderedAmount,
      changeAmount: changeAmount ?? this.changeAmount,
      verifiedAmount: verifiedAmount ?? this.verifiedAmount,
      status: status ?? this.status,
      providerReference: providerReference ?? this.providerReference,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleUuid.present) {
      map['sale_uuid'] = Variable<String>(saleUuid.value);
    }
    if (paymentUuid.present) {
      map['payment_uuid'] = Variable<String>(paymentUuid.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (tenderedAmount.present) {
      map['tendered_amount'] = Variable<int>(tenderedAmount.value);
    }
    if (changeAmount.present) {
      map['change_amount'] = Variable<int>(changeAmount.value);
    }
    if (verifiedAmount.present) {
      map['verified_amount'] = Variable<int>(verifiedAmount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (providerReference.present) {
      map['provider_reference'] = Variable<String>(providerReference.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (confirmedAt.present) {
      map['confirmed_at'] = Variable<DateTime>(confirmedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalePaymentsCompanion(')
          ..write('id: $id, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('paymentUuid: $paymentUuid, ')
          ..write('method: $method, ')
          ..write('amount: $amount, ')
          ..write('tenderedAmount: $tenderedAmount, ')
          ..write('changeAmount: $changeAmount, ')
          ..write('verifiedAmount: $verifiedAmount, ')
          ..write('status: $status, ')
          ..write('providerReference: $providerReference, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('confirmedAt: $confirmedAt')
          ..write(')'))
        .toString();
  }
}

class $OutboxEventsTable extends OutboxEvents
    with TableInfo<$OutboxEventsTable, OutboxEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggregateTypeMeta = const VerificationMeta(
    'aggregateType',
  );
  @override
  late final GeneratedColumn<String> aggregateType = GeneratedColumn<String>(
    'aggregate_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _aggregateIdMeta = const VerificationMeta(
    'aggregateId',
  );
  @override
  late final GeneratedColumn<String> aggregateId = GeneratedColumn<String>(
    'aggregate_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryableMeta = const VerificationMeta(
    'retryable',
  );
  @override
  late final GeneratedColumn<bool> retryable = GeneratedColumn<bool>(
    'retryable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("retryable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventId,
    eventType,
    aggregateType,
    aggregateId,
    sequence,
    schemaVersion,
    payloadJson,
    status,
    attempts,
    retryable,
    lastError,
    lastAttemptAt,
    occurredAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('aggregate_type')) {
      context.handle(
        _aggregateTypeMeta,
        aggregateType.isAcceptableOrUnknown(
          data['aggregate_type']!,
          _aggregateTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateTypeMeta);
    }
    if (data.containsKey('aggregate_id')) {
      context.handle(
        _aggregateIdMeta,
        aggregateId.isAcceptableOrUnknown(
          data['aggregate_id']!,
          _aggregateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_aggregateIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('retryable')) {
      context.handle(
        _retryableMeta,
        retryable.isAcceptableOrUnknown(data['retryable']!, _retryableMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      aggregateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggregate_type'],
      )!,
      aggregateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}aggregate_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      retryable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}retryable'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $OutboxEventsTable createAlias(String alias) {
    return $OutboxEventsTable(attachedDatabase, alias);
  }
}

class OutboxEvent extends DataClass implements Insertable<OutboxEvent> {
  final int id;
  final String eventId;
  final String eventType;
  final String aggregateType;
  final String aggregateId;
  final int sequence;
  final int schemaVersion;
  final String payloadJson;
  final String status;
  final int attempts;
  final bool retryable;
  final String? lastError;
  final DateTime? lastAttemptAt;
  final DateTime occurredAt;
  final DateTime createdAt;
  const OutboxEvent({
    required this.id,
    required this.eventId,
    required this.eventType,
    required this.aggregateType,
    required this.aggregateId,
    required this.sequence,
    required this.schemaVersion,
    required this.payloadJson,
    required this.status,
    required this.attempts,
    required this.retryable,
    this.lastError,
    this.lastAttemptAt,
    required this.occurredAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_id'] = Variable<String>(eventId);
    map['event_type'] = Variable<String>(eventType);
    map['aggregate_type'] = Variable<String>(aggregateType);
    map['aggregate_id'] = Variable<String>(aggregateId);
    map['sequence'] = Variable<int>(sequence);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['payload_json'] = Variable<String>(payloadJson);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['retryable'] = Variable<bool>(retryable);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  OutboxEventsCompanion toCompanion(bool nullToAbsent) {
    return OutboxEventsCompanion(
      id: Value(id),
      eventId: Value(eventId),
      eventType: Value(eventType),
      aggregateType: Value(aggregateType),
      aggregateId: Value(aggregateId),
      sequence: Value(sequence),
      schemaVersion: Value(schemaVersion),
      payloadJson: Value(payloadJson),
      status: Value(status),
      attempts: Value(attempts),
      retryable: Value(retryable),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      occurredAt: Value(occurredAt),
      createdAt: Value(createdAt),
    );
  }

  factory OutboxEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEvent(
      id: serializer.fromJson<int>(json['id']),
      eventId: serializer.fromJson<String>(json['eventId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      aggregateType: serializer.fromJson<String>(json['aggregateType']),
      aggregateId: serializer.fromJson<String>(json['aggregateId']),
      sequence: serializer.fromJson<int>(json['sequence']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      retryable: serializer.fromJson<bool>(json['retryable']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventId': serializer.toJson<String>(eventId),
      'eventType': serializer.toJson<String>(eventType),
      'aggregateType': serializer.toJson<String>(aggregateType),
      'aggregateId': serializer.toJson<String>(aggregateId),
      'sequence': serializer.toJson<int>(sequence),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'retryable': serializer.toJson<bool>(retryable),
      'lastError': serializer.toJson<String?>(lastError),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  OutboxEvent copyWith({
    int? id,
    String? eventId,
    String? eventType,
    String? aggregateType,
    String? aggregateId,
    int? sequence,
    int? schemaVersion,
    String? payloadJson,
    String? status,
    int? attempts,
    bool? retryable,
    Value<String?> lastError = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    DateTime? occurredAt,
    DateTime? createdAt,
  }) => OutboxEvent(
    id: id ?? this.id,
    eventId: eventId ?? this.eventId,
    eventType: eventType ?? this.eventType,
    aggregateType: aggregateType ?? this.aggregateType,
    aggregateId: aggregateId ?? this.aggregateId,
    sequence: sequence ?? this.sequence,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    payloadJson: payloadJson ?? this.payloadJson,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    retryable: retryable ?? this.retryable,
    lastError: lastError.present ? lastError.value : this.lastError,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    occurredAt: occurredAt ?? this.occurredAt,
    createdAt: createdAt ?? this.createdAt,
  );
  OutboxEvent copyWithCompanion(OutboxEventsCompanion data) {
    return OutboxEvent(
      id: data.id.present ? data.id.value : this.id,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      aggregateType: data.aggregateType.present
          ? data.aggregateType.value
          : this.aggregateType,
      aggregateId: data.aggregateId.present
          ? data.aggregateId.value
          : this.aggregateId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      retryable: data.retryable.present ? data.retryable.value : this.retryable,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEvent(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('sequence: $sequence, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('retryable: $retryable, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    eventId,
    eventType,
    aggregateType,
    aggregateId,
    sequence,
    schemaVersion,
    payloadJson,
    status,
    attempts,
    retryable,
    lastError,
    lastAttemptAt,
    occurredAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEvent &&
          other.id == this.id &&
          other.eventId == this.eventId &&
          other.eventType == this.eventType &&
          other.aggregateType == this.aggregateType &&
          other.aggregateId == this.aggregateId &&
          other.sequence == this.sequence &&
          other.schemaVersion == this.schemaVersion &&
          other.payloadJson == this.payloadJson &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.retryable == this.retryable &&
          other.lastError == this.lastError &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.occurredAt == this.occurredAt &&
          other.createdAt == this.createdAt);
}

class OutboxEventsCompanion extends UpdateCompanion<OutboxEvent> {
  final Value<int> id;
  final Value<String> eventId;
  final Value<String> eventType;
  final Value<String> aggregateType;
  final Value<String> aggregateId;
  final Value<int> sequence;
  final Value<int> schemaVersion;
  final Value<String> payloadJson;
  final Value<String> status;
  final Value<int> attempts;
  final Value<bool> retryable;
  final Value<String?> lastError;
  final Value<DateTime?> lastAttemptAt;
  final Value<DateTime> occurredAt;
  final Value<DateTime> createdAt;
  const OutboxEventsCompanion({
    this.id = const Value.absent(),
    this.eventId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.aggregateType = const Value.absent(),
    this.aggregateId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.retryable = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  OutboxEventsCompanion.insert({
    this.id = const Value.absent(),
    required String eventId,
    required String eventType,
    required String aggregateType,
    required String aggregateId,
    required int sequence,
    this.schemaVersion = const Value.absent(),
    required String payloadJson,
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.retryable = const Value.absent(),
    this.lastError = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    required DateTime occurredAt,
    required DateTime createdAt,
  }) : eventId = Value(eventId),
       eventType = Value(eventType),
       aggregateType = Value(aggregateType),
       aggregateId = Value(aggregateId),
       sequence = Value(sequence),
       payloadJson = Value(payloadJson),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt);
  static Insertable<OutboxEvent> custom({
    Expression<int>? id,
    Expression<String>? eventId,
    Expression<String>? eventType,
    Expression<String>? aggregateType,
    Expression<String>? aggregateId,
    Expression<int>? sequence,
    Expression<int>? schemaVersion,
    Expression<String>? payloadJson,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<bool>? retryable,
    Expression<String>? lastError,
    Expression<DateTime>? lastAttemptAt,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventId != null) 'event_id': eventId,
      if (eventType != null) 'event_type': eventType,
      if (aggregateType != null) 'aggregate_type': aggregateType,
      if (aggregateId != null) 'aggregate_id': aggregateId,
      if (sequence != null) 'sequence': sequence,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (retryable != null) 'retryable': retryable,
      if (lastError != null) 'last_error': lastError,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  OutboxEventsCompanion copyWith({
    Value<int>? id,
    Value<String>? eventId,
    Value<String>? eventType,
    Value<String>? aggregateType,
    Value<String>? aggregateId,
    Value<int>? sequence,
    Value<int>? schemaVersion,
    Value<String>? payloadJson,
    Value<String>? status,
    Value<int>? attempts,
    Value<bool>? retryable,
    Value<String?>? lastError,
    Value<DateTime?>? lastAttemptAt,
    Value<DateTime>? occurredAt,
    Value<DateTime>? createdAt,
  }) {
    return OutboxEventsCompanion(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      aggregateType: aggregateType ?? this.aggregateType,
      aggregateId: aggregateId ?? this.aggregateId,
      sequence: sequence ?? this.sequence,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      retryable: retryable ?? this.retryable,
      lastError: lastError ?? this.lastError,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (aggregateType.present) {
      map['aggregate_type'] = Variable<String>(aggregateType.value);
    }
    if (aggregateId.present) {
      map['aggregate_id'] = Variable<String>(aggregateId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (retryable.present) {
      map['retryable'] = Variable<bool>(retryable.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEventsCompanion(')
          ..write('id: $id, ')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('aggregateType: $aggregateType, ')
          ..write('aggregateId: $aggregateId, ')
          ..write('sequence: $sequence, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('retryable: $retryable, ')
          ..write('lastError: $lastError, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LocalShiftsTable extends LocalShifts
    with TableInfo<$LocalShiftsTable, LocalShift> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalShiftsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _openingCashMeta = const VerificationMeta(
    'openingCash',
  );
  @override
  late final GeneratedColumn<int> openingCash = GeneratedColumn<int>(
    'opening_cash',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _openingNotesMeta = const VerificationMeta(
    'openingNotes',
  );
  @override
  late final GeneratedColumn<String> openingNotes = GeneratedColumn<String>(
    'opening_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtMeta = const VerificationMeta(
    'openedAt',
  );
  @override
  late final GeneratedColumn<DateTime> openedAt = GeneratedColumn<DateTime>(
    'opened_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expectedCashMeta = const VerificationMeta(
    'expectedCash',
  );
  @override
  late final GeneratedColumn<int> expectedCash = GeneratedColumn<int>(
    'expected_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _actualCashMeta = const VerificationMeta(
    'actualCash',
  );
  @override
  late final GeneratedColumn<int> actualCash = GeneratedColumn<int>(
    'actual_cash',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _differenceMeta = const VerificationMeta(
    'difference',
  );
  @override
  late final GeneratedColumn<int> difference = GeneratedColumn<int>(
    'difference',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closingNotesMeta = const VerificationMeta(
    'closingNotes',
  );
  @override
  late final GeneratedColumn<String> closingNotes = GeneratedColumn<String>(
    'closing_notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    status,
    openingCash,
    openingNotes,
    openedAt,
    closedAt,
    expectedCash,
    actualCash,
    difference,
    closingNotes,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_shifts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalShift> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('opening_cash')) {
      context.handle(
        _openingCashMeta,
        openingCash.isAcceptableOrUnknown(
          data['opening_cash']!,
          _openingCashMeta,
        ),
      );
    }
    if (data.containsKey('opening_notes')) {
      context.handle(
        _openingNotesMeta,
        openingNotes.isAcceptableOrUnknown(
          data['opening_notes']!,
          _openingNotesMeta,
        ),
      );
    }
    if (data.containsKey('opened_at')) {
      context.handle(
        _openedAtMeta,
        openedAt.isAcceptableOrUnknown(data['opened_at']!, _openedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_openedAtMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    if (data.containsKey('expected_cash')) {
      context.handle(
        _expectedCashMeta,
        expectedCash.isAcceptableOrUnknown(
          data['expected_cash']!,
          _expectedCashMeta,
        ),
      );
    }
    if (data.containsKey('actual_cash')) {
      context.handle(
        _actualCashMeta,
        actualCash.isAcceptableOrUnknown(data['actual_cash']!, _actualCashMeta),
      );
    }
    if (data.containsKey('difference')) {
      context.handle(
        _differenceMeta,
        difference.isAcceptableOrUnknown(data['difference']!, _differenceMeta),
      );
    }
    if (data.containsKey('closing_notes')) {
      context.handle(
        _closingNotesMeta,
        closingNotes.isAcceptableOrUnknown(
          data['closing_notes']!,
          _closingNotesMeta,
        ),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  LocalShift map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalShift(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openingCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_cash'],
      )!,
      openingNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}opening_notes'],
      ),
      openedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}opened_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
      expectedCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_cash'],
      ),
      actualCash: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_cash'],
      ),
      difference: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difference'],
      ),
      closingNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closing_notes'],
      ),
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $LocalShiftsTable createAlias(String alias) {
    return $LocalShiftsTable(attachedDatabase, alias);
  }
}

class LocalShift extends DataClass implements Insertable<LocalShift> {
  final String uuid;
  final String status;
  final int openingCash;
  final String? openingNotes;
  final DateTime openedAt;
  final DateTime? closedAt;
  final int? expectedCash;
  final int? actualCash;
  final int? difference;
  final String? closingNotes;
  final bool synced;
  const LocalShift({
    required this.uuid,
    required this.status,
    required this.openingCash,
    this.openingNotes,
    required this.openedAt,
    this.closedAt,
    this.expectedCash,
    this.actualCash,
    this.difference,
    this.closingNotes,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['status'] = Variable<String>(status);
    map['opening_cash'] = Variable<int>(openingCash);
    if (!nullToAbsent || openingNotes != null) {
      map['opening_notes'] = Variable<String>(openingNotes);
    }
    map['opened_at'] = Variable<DateTime>(openedAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    if (!nullToAbsent || expectedCash != null) {
      map['expected_cash'] = Variable<int>(expectedCash);
    }
    if (!nullToAbsent || actualCash != null) {
      map['actual_cash'] = Variable<int>(actualCash);
    }
    if (!nullToAbsent || difference != null) {
      map['difference'] = Variable<int>(difference);
    }
    if (!nullToAbsent || closingNotes != null) {
      map['closing_notes'] = Variable<String>(closingNotes);
    }
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  LocalShiftsCompanion toCompanion(bool nullToAbsent) {
    return LocalShiftsCompanion(
      uuid: Value(uuid),
      status: Value(status),
      openingCash: Value(openingCash),
      openingNotes: openingNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(openingNotes),
      openedAt: Value(openedAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
      expectedCash: expectedCash == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedCash),
      actualCash: actualCash == null && nullToAbsent
          ? const Value.absent()
          : Value(actualCash),
      difference: difference == null && nullToAbsent
          ? const Value.absent()
          : Value(difference),
      closingNotes: closingNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(closingNotes),
      synced: Value(synced),
    );
  }

  factory LocalShift.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalShift(
      uuid: serializer.fromJson<String>(json['uuid']),
      status: serializer.fromJson<String>(json['status']),
      openingCash: serializer.fromJson<int>(json['openingCash']),
      openingNotes: serializer.fromJson<String?>(json['openingNotes']),
      openedAt: serializer.fromJson<DateTime>(json['openedAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
      expectedCash: serializer.fromJson<int?>(json['expectedCash']),
      actualCash: serializer.fromJson<int?>(json['actualCash']),
      difference: serializer.fromJson<int?>(json['difference']),
      closingNotes: serializer.fromJson<String?>(json['closingNotes']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'status': serializer.toJson<String>(status),
      'openingCash': serializer.toJson<int>(openingCash),
      'openingNotes': serializer.toJson<String?>(openingNotes),
      'openedAt': serializer.toJson<DateTime>(openedAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
      'expectedCash': serializer.toJson<int?>(expectedCash),
      'actualCash': serializer.toJson<int?>(actualCash),
      'difference': serializer.toJson<int?>(difference),
      'closingNotes': serializer.toJson<String?>(closingNotes),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  LocalShift copyWith({
    String? uuid,
    String? status,
    int? openingCash,
    Value<String?> openingNotes = const Value.absent(),
    DateTime? openedAt,
    Value<DateTime?> closedAt = const Value.absent(),
    Value<int?> expectedCash = const Value.absent(),
    Value<int?> actualCash = const Value.absent(),
    Value<int?> difference = const Value.absent(),
    Value<String?> closingNotes = const Value.absent(),
    bool? synced,
  }) => LocalShift(
    uuid: uuid ?? this.uuid,
    status: status ?? this.status,
    openingCash: openingCash ?? this.openingCash,
    openingNotes: openingNotes.present ? openingNotes.value : this.openingNotes,
    openedAt: openedAt ?? this.openedAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
    expectedCash: expectedCash.present ? expectedCash.value : this.expectedCash,
    actualCash: actualCash.present ? actualCash.value : this.actualCash,
    difference: difference.present ? difference.value : this.difference,
    closingNotes: closingNotes.present ? closingNotes.value : this.closingNotes,
    synced: synced ?? this.synced,
  );
  LocalShift copyWithCompanion(LocalShiftsCompanion data) {
    return LocalShift(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      status: data.status.present ? data.status.value : this.status,
      openingCash: data.openingCash.present
          ? data.openingCash.value
          : this.openingCash,
      openingNotes: data.openingNotes.present
          ? data.openingNotes.value
          : this.openingNotes,
      openedAt: data.openedAt.present ? data.openedAt.value : this.openedAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
      expectedCash: data.expectedCash.present
          ? data.expectedCash.value
          : this.expectedCash,
      actualCash: data.actualCash.present
          ? data.actualCash.value
          : this.actualCash,
      difference: data.difference.present
          ? data.difference.value
          : this.difference,
      closingNotes: data.closingNotes.present
          ? data.closingNotes.value
          : this.closingNotes,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalShift(')
          ..write('uuid: $uuid, ')
          ..write('status: $status, ')
          ..write('openingCash: $openingCash, ')
          ..write('openingNotes: $openingNotes, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('actualCash: $actualCash, ')
          ..write('difference: $difference, ')
          ..write('closingNotes: $closingNotes, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    status,
    openingCash,
    openingNotes,
    openedAt,
    closedAt,
    expectedCash,
    actualCash,
    difference,
    closingNotes,
    synced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalShift &&
          other.uuid == this.uuid &&
          other.status == this.status &&
          other.openingCash == this.openingCash &&
          other.openingNotes == this.openingNotes &&
          other.openedAt == this.openedAt &&
          other.closedAt == this.closedAt &&
          other.expectedCash == this.expectedCash &&
          other.actualCash == this.actualCash &&
          other.difference == this.difference &&
          other.closingNotes == this.closingNotes &&
          other.synced == this.synced);
}

class LocalShiftsCompanion extends UpdateCompanion<LocalShift> {
  final Value<String> uuid;
  final Value<String> status;
  final Value<int> openingCash;
  final Value<String?> openingNotes;
  final Value<DateTime> openedAt;
  final Value<DateTime?> closedAt;
  final Value<int?> expectedCash;
  final Value<int?> actualCash;
  final Value<int?> difference;
  final Value<String?> closingNotes;
  final Value<bool> synced;
  final Value<int> rowid;
  const LocalShiftsCompanion({
    this.uuid = const Value.absent(),
    this.status = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.openingNotes = const Value.absent(),
    this.openedAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.actualCash = const Value.absent(),
    this.difference = const Value.absent(),
    this.closingNotes = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalShiftsCompanion.insert({
    required String uuid,
    this.status = const Value.absent(),
    this.openingCash = const Value.absent(),
    this.openingNotes = const Value.absent(),
    required DateTime openedAt,
    this.closedAt = const Value.absent(),
    this.expectedCash = const Value.absent(),
    this.actualCash = const Value.absent(),
    this.difference = const Value.absent(),
    this.closingNotes = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       openedAt = Value(openedAt);
  static Insertable<LocalShift> custom({
    Expression<String>? uuid,
    Expression<String>? status,
    Expression<int>? openingCash,
    Expression<String>? openingNotes,
    Expression<DateTime>? openedAt,
    Expression<DateTime>? closedAt,
    Expression<int>? expectedCash,
    Expression<int>? actualCash,
    Expression<int>? difference,
    Expression<String>? closingNotes,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (status != null) 'status': status,
      if (openingCash != null) 'opening_cash': openingCash,
      if (openingNotes != null) 'opening_notes': openingNotes,
      if (openedAt != null) 'opened_at': openedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (expectedCash != null) 'expected_cash': expectedCash,
      if (actualCash != null) 'actual_cash': actualCash,
      if (difference != null) 'difference': difference,
      if (closingNotes != null) 'closing_notes': closingNotes,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalShiftsCompanion copyWith({
    Value<String>? uuid,
    Value<String>? status,
    Value<int>? openingCash,
    Value<String?>? openingNotes,
    Value<DateTime>? openedAt,
    Value<DateTime?>? closedAt,
    Value<int?>? expectedCash,
    Value<int?>? actualCash,
    Value<int?>? difference,
    Value<String?>? closingNotes,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return LocalShiftsCompanion(
      uuid: uuid ?? this.uuid,
      status: status ?? this.status,
      openingCash: openingCash ?? this.openingCash,
      openingNotes: openingNotes ?? this.openingNotes,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      expectedCash: expectedCash ?? this.expectedCash,
      actualCash: actualCash ?? this.actualCash,
      difference: difference ?? this.difference,
      closingNotes: closingNotes ?? this.closingNotes,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openingCash.present) {
      map['opening_cash'] = Variable<int>(openingCash.value);
    }
    if (openingNotes.present) {
      map['opening_notes'] = Variable<String>(openingNotes.value);
    }
    if (openedAt.present) {
      map['opened_at'] = Variable<DateTime>(openedAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (expectedCash.present) {
      map['expected_cash'] = Variable<int>(expectedCash.value);
    }
    if (actualCash.present) {
      map['actual_cash'] = Variable<int>(actualCash.value);
    }
    if (difference.present) {
      map['difference'] = Variable<int>(difference.value);
    }
    if (closingNotes.present) {
      map['closing_notes'] = Variable<String>(closingNotes.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalShiftsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('status: $status, ')
          ..write('openingCash: $openingCash, ')
          ..write('openingNotes: $openingNotes, ')
          ..write('openedAt: $openedAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('expectedCash: $expectedCash, ')
          ..write('actualCash: $actualCash, ')
          ..write('difference: $difference, ')
          ..write('closingNotes: $closingNotes, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CashMovementsTable extends CashMovements
    with TableInfo<$CashMovementsTable, CashMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CashMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shiftUuidMeta = const VerificationMeta(
    'shiftUuid',
  );
  @override
  late final GeneratedColumn<String> shiftUuid = GeneratedColumn<String>(
    'shift_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES local_shifts (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    shiftUuid,
    type,
    amount,
    reason,
    createdAt,
    synced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cash_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CashMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('shift_uuid')) {
      context.handle(
        _shiftUuidMeta,
        shiftUuid.isAcceptableOrUnknown(data['shift_uuid']!, _shiftUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_shiftUuidMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  CashMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CashMovement(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      shiftUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shift_uuid'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
    );
  }

  @override
  $CashMovementsTable createAlias(String alias) {
    return $CashMovementsTable(attachedDatabase, alias);
  }
}

class CashMovement extends DataClass implements Insertable<CashMovement> {
  final String uuid;
  final String shiftUuid;
  final String type;
  final int amount;
  final String reason;
  final DateTime createdAt;
  final bool synced;
  const CashMovement({
    required this.uuid,
    required this.shiftUuid,
    required this.type,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.synced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['shift_uuid'] = Variable<String>(shiftUuid);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    map['reason'] = Variable<String>(reason);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['synced'] = Variable<bool>(synced);
    return map;
  }

  CashMovementsCompanion toCompanion(bool nullToAbsent) {
    return CashMovementsCompanion(
      uuid: Value(uuid),
      shiftUuid: Value(shiftUuid),
      type: Value(type),
      amount: Value(amount),
      reason: Value(reason),
      createdAt: Value(createdAt),
      synced: Value(synced),
    );
  }

  factory CashMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CashMovement(
      uuid: serializer.fromJson<String>(json['uuid']),
      shiftUuid: serializer.fromJson<String>(json['shiftUuid']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      reason: serializer.fromJson<String>(json['reason']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      synced: serializer.fromJson<bool>(json['synced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'shiftUuid': serializer.toJson<String>(shiftUuid),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'reason': serializer.toJson<String>(reason),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'synced': serializer.toJson<bool>(synced),
    };
  }

  CashMovement copyWith({
    String? uuid,
    String? shiftUuid,
    String? type,
    int? amount,
    String? reason,
    DateTime? createdAt,
    bool? synced,
  }) => CashMovement(
    uuid: uuid ?? this.uuid,
    shiftUuid: shiftUuid ?? this.shiftUuid,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    reason: reason ?? this.reason,
    createdAt: createdAt ?? this.createdAt,
    synced: synced ?? this.synced,
  );
  CashMovement copyWithCompanion(CashMovementsCompanion data) {
    return CashMovement(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      shiftUuid: data.shiftUuid.present ? data.shiftUuid.value : this.shiftUuid,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      reason: data.reason.present ? data.reason.value : this.reason,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      synced: data.synced.present ? data.synced.value : this.synced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CashMovement(')
          ..write('uuid: $uuid, ')
          ..write('shiftUuid: $shiftUuid, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuid, shiftUuid, type, amount, reason, createdAt, synced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CashMovement &&
          other.uuid == this.uuid &&
          other.shiftUuid == this.shiftUuid &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.reason == this.reason &&
          other.createdAt == this.createdAt &&
          other.synced == this.synced);
}

class CashMovementsCompanion extends UpdateCompanion<CashMovement> {
  final Value<String> uuid;
  final Value<String> shiftUuid;
  final Value<String> type;
  final Value<int> amount;
  final Value<String> reason;
  final Value<DateTime> createdAt;
  final Value<bool> synced;
  final Value<int> rowid;
  const CashMovementsCompanion({
    this.uuid = const Value.absent(),
    this.shiftUuid = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.reason = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CashMovementsCompanion.insert({
    required String uuid,
    required String shiftUuid,
    required String type,
    required int amount,
    required String reason,
    required DateTime createdAt,
    this.synced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       shiftUuid = Value(shiftUuid),
       type = Value(type),
       amount = Value(amount),
       reason = Value(reason),
       createdAt = Value(createdAt);
  static Insertable<CashMovement> custom({
    Expression<String>? uuid,
    Expression<String>? shiftUuid,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? reason,
    Expression<DateTime>? createdAt,
    Expression<bool>? synced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (shiftUuid != null) 'shift_uuid': shiftUuid,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (reason != null) 'reason': reason,
      if (createdAt != null) 'created_at': createdAt,
      if (synced != null) 'synced': synced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CashMovementsCompanion copyWith({
    Value<String>? uuid,
    Value<String>? shiftUuid,
    Value<String>? type,
    Value<int>? amount,
    Value<String>? reason,
    Value<DateTime>? createdAt,
    Value<bool>? synced,
    Value<int>? rowid,
  }) {
    return CashMovementsCompanion(
      uuid: uuid ?? this.uuid,
      shiftUuid: shiftUuid ?? this.shiftUuid,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (shiftUuid.present) {
      map['shift_uuid'] = Variable<String>(shiftUuid.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CashMovementsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('shiftUuid: $shiftUuid, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('reason: $reason, ')
          ..write('createdAt: $createdAt, ')
          ..write('synced: $synced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrintJobsTable extends PrintJobs
    with TableInfo<$PrintJobsTable, PrintJob> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrintJobsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _saleUuidMeta = const VerificationMeta(
    'saleUuid',
  );
  @override
  late final GeneratedColumn<String> saleUuid = GeneratedColumn<String>(
    'sale_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('receipt'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _printedAtMeta = const VerificationMeta(
    'printedAt',
  );
  @override
  late final GeneratedColumn<DateTime> printedAt = GeneratedColumn<DateTime>(
    'printed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    saleUuid,
    kind,
    status,
    attempts,
    lastError,
    createdAt,
    printedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'print_jobs';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrintJob> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sale_uuid')) {
      context.handle(
        _saleUuidMeta,
        saleUuid.isAcceptableOrUnknown(data['sale_uuid']!, _saleUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_saleUuidMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('printed_at')) {
      context.handle(
        _printedAtMeta,
        printedAt.isAcceptableOrUnknown(data['printed_at']!, _printedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrintJob map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrintJob(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      saleUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_uuid'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      printedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}printed_at'],
      ),
    );
  }

  @override
  $PrintJobsTable createAlias(String alias) {
    return $PrintJobsTable(attachedDatabase, alias);
  }
}

class PrintJob extends DataClass implements Insertable<PrintJob> {
  final int id;
  final String saleUuid;
  final String kind;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? printedAt;
  const PrintJob({
    required this.id,
    required this.saleUuid,
    required this.kind,
    required this.status,
    required this.attempts,
    this.lastError,
    required this.createdAt,
    this.printedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sale_uuid'] = Variable<String>(saleUuid);
    map['kind'] = Variable<String>(kind);
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || printedAt != null) {
      map['printed_at'] = Variable<DateTime>(printedAt);
    }
    return map;
  }

  PrintJobsCompanion toCompanion(bool nullToAbsent) {
    return PrintJobsCompanion(
      id: Value(id),
      saleUuid: Value(saleUuid),
      kind: Value(kind),
      status: Value(status),
      attempts: Value(attempts),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      printedAt: printedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(printedAt),
    );
  }

  factory PrintJob.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrintJob(
      id: serializer.fromJson<int>(json['id']),
      saleUuid: serializer.fromJson<String>(json['saleUuid']),
      kind: serializer.fromJson<String>(json['kind']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      printedAt: serializer.fromJson<DateTime?>(json['printedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'saleUuid': serializer.toJson<String>(saleUuid),
      'kind': serializer.toJson<String>(kind),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'printedAt': serializer.toJson<DateTime?>(printedAt),
    };
  }

  PrintJob copyWith({
    int? id,
    String? saleUuid,
    String? kind,
    String? status,
    int? attempts,
    Value<String?> lastError = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> printedAt = const Value.absent(),
  }) => PrintJob(
    id: id ?? this.id,
    saleUuid: saleUuid ?? this.saleUuid,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    printedAt: printedAt.present ? printedAt.value : this.printedAt,
  );
  PrintJob copyWithCompanion(PrintJobsCompanion data) {
    return PrintJob(
      id: data.id.present ? data.id.value : this.id,
      saleUuid: data.saleUuid.present ? data.saleUuid.value : this.saleUuid,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      printedAt: data.printedAt.present ? data.printedAt.value : this.printedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrintJob(')
          ..write('id: $id, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('printedAt: $printedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    saleUuid,
    kind,
    status,
    attempts,
    lastError,
    createdAt,
    printedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrintJob &&
          other.id == this.id &&
          other.saleUuid == this.saleUuid &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.printedAt == this.printedAt);
}

class PrintJobsCompanion extends UpdateCompanion<PrintJob> {
  final Value<int> id;
  final Value<String> saleUuid;
  final Value<String> kind;
  final Value<String> status;
  final Value<int> attempts;
  final Value<String?> lastError;
  final Value<DateTime> createdAt;
  final Value<DateTime?> printedAt;
  const PrintJobsCompanion({
    this.id = const Value.absent(),
    this.saleUuid = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.printedAt = const Value.absent(),
  });
  PrintJobsCompanion.insert({
    this.id = const Value.absent(),
    required String saleUuid,
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastError = const Value.absent(),
    required DateTime createdAt,
    this.printedAt = const Value.absent(),
  }) : saleUuid = Value(saleUuid),
       createdAt = Value(createdAt);
  static Insertable<PrintJob> custom({
    Expression<int>? id,
    Expression<String>? saleUuid,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<String>? lastError,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? printedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (saleUuid != null) 'sale_uuid': saleUuid,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (printedAt != null) 'printed_at': printedAt,
    });
  }

  PrintJobsCompanion copyWith({
    Value<int>? id,
    Value<String>? saleUuid,
    Value<String>? kind,
    Value<String>? status,
    Value<int>? attempts,
    Value<String?>? lastError,
    Value<DateTime>? createdAt,
    Value<DateTime?>? printedAt,
  }) {
    return PrintJobsCompanion(
      id: id ?? this.id,
      saleUuid: saleUuid ?? this.saleUuid,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      printedAt: printedAt ?? this.printedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (saleUuid.present) {
      map['sale_uuid'] = Variable<String>(saleUuid.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (printedAt.present) {
      map['printed_at'] = Variable<DateTime>(printedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrintJobsCompanion(')
          ..write('id: $id, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('printedAt: $printedAt')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPulledAtMeta = const VerificationMeta(
    'lastPulledAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPulledAt = GeneratedColumn<DateTime>(
    'last_pulled_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPushedAtMeta = const VerificationMeta(
    'lastPushedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPushedAt = GeneratedColumn<DateTime>(
    'last_pushed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _catalogSyncedAtMeta = const VerificationMeta(
    'catalogSyncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> catalogSyncedAt =
      GeneratedColumn<DateTime>(
        'catalog_synced_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _catalogVersionMeta = const VerificationMeta(
    'catalogVersion',
  );
  @override
  late final GeneratedColumn<String> catalogVersion = GeneratedColumn<String>(
    'catalog_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastServerTimeMeta = const VerificationMeta(
    'lastServerTime',
  );
  @override
  late final GeneratedColumn<String> lastServerTime = GeneratedColumn<String>(
    'last_server_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cursor,
    lastPulledAt,
    lastPushedAt,
    catalogSyncedAt,
    catalogVersion,
    lastServerTime,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('last_pulled_at')) {
      context.handle(
        _lastPulledAtMeta,
        lastPulledAt.isAcceptableOrUnknown(
          data['last_pulled_at']!,
          _lastPulledAtMeta,
        ),
      );
    }
    if (data.containsKey('last_pushed_at')) {
      context.handle(
        _lastPushedAtMeta,
        lastPushedAt.isAcceptableOrUnknown(
          data['last_pushed_at']!,
          _lastPushedAtMeta,
        ),
      );
    }
    if (data.containsKey('catalog_synced_at')) {
      context.handle(
        _catalogSyncedAtMeta,
        catalogSyncedAt.isAcceptableOrUnknown(
          data['catalog_synced_at']!,
          _catalogSyncedAtMeta,
        ),
      );
    }
    if (data.containsKey('catalog_version')) {
      context.handle(
        _catalogVersionMeta,
        catalogVersion.isAcceptableOrUnknown(
          data['catalog_version']!,
          _catalogVersionMeta,
        ),
      );
    }
    if (data.containsKey('last_server_time')) {
      context.handle(
        _lastServerTimeMeta,
        lastServerTime.isAcceptableOrUnknown(
          data['last_server_time']!,
          _lastServerTimeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      lastPulledAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pulled_at'],
      ),
      lastPushedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pushed_at'],
      ),
      catalogSyncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}catalog_synced_at'],
      ),
      catalogVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_version'],
      ),
      lastServerTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_server_time'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final int id;
  final String? cursor;
  final DateTime? lastPulledAt;
  final DateTime? lastPushedAt;
  final DateTime? catalogSyncedAt;
  final String? catalogVersion;
  final String? lastServerTime;
  const SyncStateData({
    required this.id,
    this.cursor,
    this.lastPulledAt,
    this.lastPushedAt,
    this.catalogSyncedAt,
    this.catalogVersion,
    this.lastServerTime,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || lastPulledAt != null) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt);
    }
    if (!nullToAbsent || lastPushedAt != null) {
      map['last_pushed_at'] = Variable<DateTime>(lastPushedAt);
    }
    if (!nullToAbsent || catalogSyncedAt != null) {
      map['catalog_synced_at'] = Variable<DateTime>(catalogSyncedAt);
    }
    if (!nullToAbsent || catalogVersion != null) {
      map['catalog_version'] = Variable<String>(catalogVersion);
    }
    if (!nullToAbsent || lastServerTime != null) {
      map['last_server_time'] = Variable<String>(lastServerTime);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      id: Value(id),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      lastPulledAt: lastPulledAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPulledAt),
      lastPushedAt: lastPushedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushedAt),
      catalogSyncedAt: catalogSyncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogSyncedAt),
      catalogVersion: catalogVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogVersion),
      lastServerTime: lastServerTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastServerTime),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      id: serializer.fromJson<int>(json['id']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      lastPulledAt: serializer.fromJson<DateTime?>(json['lastPulledAt']),
      lastPushedAt: serializer.fromJson<DateTime?>(json['lastPushedAt']),
      catalogSyncedAt: serializer.fromJson<DateTime?>(json['catalogSyncedAt']),
      catalogVersion: serializer.fromJson<String?>(json['catalogVersion']),
      lastServerTime: serializer.fromJson<String?>(json['lastServerTime']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cursor': serializer.toJson<String?>(cursor),
      'lastPulledAt': serializer.toJson<DateTime?>(lastPulledAt),
      'lastPushedAt': serializer.toJson<DateTime?>(lastPushedAt),
      'catalogSyncedAt': serializer.toJson<DateTime?>(catalogSyncedAt),
      'catalogVersion': serializer.toJson<String?>(catalogVersion),
      'lastServerTime': serializer.toJson<String?>(lastServerTime),
    };
  }

  SyncStateData copyWith({
    int? id,
    Value<String?> cursor = const Value.absent(),
    Value<DateTime?> lastPulledAt = const Value.absent(),
    Value<DateTime?> lastPushedAt = const Value.absent(),
    Value<DateTime?> catalogSyncedAt = const Value.absent(),
    Value<String?> catalogVersion = const Value.absent(),
    Value<String?> lastServerTime = const Value.absent(),
  }) => SyncStateData(
    id: id ?? this.id,
    cursor: cursor.present ? cursor.value : this.cursor,
    lastPulledAt: lastPulledAt.present ? lastPulledAt.value : this.lastPulledAt,
    lastPushedAt: lastPushedAt.present ? lastPushedAt.value : this.lastPushedAt,
    catalogSyncedAt: catalogSyncedAt.present
        ? catalogSyncedAt.value
        : this.catalogSyncedAt,
    catalogVersion: catalogVersion.present
        ? catalogVersion.value
        : this.catalogVersion,
    lastServerTime: lastServerTime.present
        ? lastServerTime.value
        : this.lastServerTime,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      id: data.id.present ? data.id.value : this.id,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastPulledAt: data.lastPulledAt.present
          ? data.lastPulledAt.value
          : this.lastPulledAt,
      lastPushedAt: data.lastPushedAt.present
          ? data.lastPushedAt.value
          : this.lastPushedAt,
      catalogSyncedAt: data.catalogSyncedAt.present
          ? data.catalogSyncedAt.value
          : this.catalogSyncedAt,
      catalogVersion: data.catalogVersion.present
          ? data.catalogVersion.value
          : this.catalogVersion,
      lastServerTime: data.lastServerTime.present
          ? data.lastServerTime.value
          : this.lastServerTime,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('id: $id, ')
          ..write('cursor: $cursor, ')
          ..write('lastPulledAt: $lastPulledAt, ')
          ..write('lastPushedAt: $lastPushedAt, ')
          ..write('catalogSyncedAt: $catalogSyncedAt, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('lastServerTime: $lastServerTime')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cursor,
    lastPulledAt,
    lastPushedAt,
    catalogSyncedAt,
    catalogVersion,
    lastServerTime,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.id == this.id &&
          other.cursor == this.cursor &&
          other.lastPulledAt == this.lastPulledAt &&
          other.lastPushedAt == this.lastPushedAt &&
          other.catalogSyncedAt == this.catalogSyncedAt &&
          other.catalogVersion == this.catalogVersion &&
          other.lastServerTime == this.lastServerTime);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<int> id;
  final Value<String?> cursor;
  final Value<DateTime?> lastPulledAt;
  final Value<DateTime?> lastPushedAt;
  final Value<DateTime?> catalogSyncedAt;
  final Value<String?> catalogVersion;
  final Value<String?> lastServerTime;
  const SyncStateCompanion({
    this.id = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastPulledAt = const Value.absent(),
    this.lastPushedAt = const Value.absent(),
    this.catalogSyncedAt = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.lastServerTime = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.id = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastPulledAt = const Value.absent(),
    this.lastPushedAt = const Value.absent(),
    this.catalogSyncedAt = const Value.absent(),
    this.catalogVersion = const Value.absent(),
    this.lastServerTime = const Value.absent(),
  });
  static Insertable<SyncStateData> custom({
    Expression<int>? id,
    Expression<String>? cursor,
    Expression<DateTime>? lastPulledAt,
    Expression<DateTime>? lastPushedAt,
    Expression<DateTime>? catalogSyncedAt,
    Expression<String>? catalogVersion,
    Expression<String>? lastServerTime,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cursor != null) 'cursor': cursor,
      if (lastPulledAt != null) 'last_pulled_at': lastPulledAt,
      if (lastPushedAt != null) 'last_pushed_at': lastPushedAt,
      if (catalogSyncedAt != null) 'catalog_synced_at': catalogSyncedAt,
      if (catalogVersion != null) 'catalog_version': catalogVersion,
      if (lastServerTime != null) 'last_server_time': lastServerTime,
    });
  }

  SyncStateCompanion copyWith({
    Value<int>? id,
    Value<String?>? cursor,
    Value<DateTime?>? lastPulledAt,
    Value<DateTime?>? lastPushedAt,
    Value<DateTime?>? catalogSyncedAt,
    Value<String?>? catalogVersion,
    Value<String?>? lastServerTime,
  }) {
    return SyncStateCompanion(
      id: id ?? this.id,
      cursor: cursor ?? this.cursor,
      lastPulledAt: lastPulledAt ?? this.lastPulledAt,
      lastPushedAt: lastPushedAt ?? this.lastPushedAt,
      catalogSyncedAt: catalogSyncedAt ?? this.catalogSyncedAt,
      catalogVersion: catalogVersion ?? this.catalogVersion,
      lastServerTime: lastServerTime ?? this.lastServerTime,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (lastPulledAt.present) {
      map['last_pulled_at'] = Variable<DateTime>(lastPulledAt.value);
    }
    if (lastPushedAt.present) {
      map['last_pushed_at'] = Variable<DateTime>(lastPushedAt.value);
    }
    if (catalogSyncedAt.present) {
      map['catalog_synced_at'] = Variable<DateTime>(catalogSyncedAt.value);
    }
    if (catalogVersion.present) {
      map['catalog_version'] = Variable<String>(catalogVersion.value);
    }
    if (lastServerTime.present) {
      map['last_server_time'] = Variable<String>(lastServerTime.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('id: $id, ')
          ..write('cursor: $cursor, ')
          ..write('lastPulledAt: $lastPulledAt, ')
          ..write('lastPushedAt: $lastPushedAt, ')
          ..write('catalogSyncedAt: $catalogSyncedAt, ')
          ..write('catalogVersion: $catalogVersion, ')
          ..write('lastServerTime: $lastServerTime')
          ..write(')'))
        .toString();
  }
}

class $ReceiptCountersTable extends ReceiptCounters
    with TableInfo<$ReceiptCountersTable, ReceiptCounter> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptCountersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _terminalCodeMeta = const VerificationMeta(
    'terminalCode',
  );
  @override
  late final GeneratedColumn<String> terminalCode = GeneratedColumn<String>(
    'terminal_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSequenceMeta = const VerificationMeta(
    'lastSequence',
  );
  @override
  late final GeneratedColumn<int> lastSequence = GeneratedColumn<int>(
    'last_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [terminalCode, lastSequence, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_counters';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptCounter> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('terminal_code')) {
      context.handle(
        _terminalCodeMeta,
        terminalCode.isAcceptableOrUnknown(
          data['terminal_code']!,
          _terminalCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_terminalCodeMeta);
    }
    if (data.containsKey('last_sequence')) {
      context.handle(
        _lastSequenceMeta,
        lastSequence.isAcceptableOrUnknown(
          data['last_sequence']!,
          _lastSequenceMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {terminalCode};
  @override
  ReceiptCounter map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptCounter(
      terminalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}terminal_code'],
      )!,
      lastSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sequence'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ReceiptCountersTable createAlias(String alias) {
    return $ReceiptCountersTable(attachedDatabase, alias);
  }
}

class ReceiptCounter extends DataClass implements Insertable<ReceiptCounter> {
  final String terminalCode;
  final int lastSequence;
  final DateTime updatedAt;
  const ReceiptCounter({
    required this.terminalCode,
    required this.lastSequence,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['terminal_code'] = Variable<String>(terminalCode);
    map['last_sequence'] = Variable<int>(lastSequence);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ReceiptCountersCompanion toCompanion(bool nullToAbsent) {
    return ReceiptCountersCompanion(
      terminalCode: Value(terminalCode),
      lastSequence: Value(lastSequence),
      updatedAt: Value(updatedAt),
    );
  }

  factory ReceiptCounter.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptCounter(
      terminalCode: serializer.fromJson<String>(json['terminalCode']),
      lastSequence: serializer.fromJson<int>(json['lastSequence']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'terminalCode': serializer.toJson<String>(terminalCode),
      'lastSequence': serializer.toJson<int>(lastSequence),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ReceiptCounter copyWith({
    String? terminalCode,
    int? lastSequence,
    DateTime? updatedAt,
  }) => ReceiptCounter(
    terminalCode: terminalCode ?? this.terminalCode,
    lastSequence: lastSequence ?? this.lastSequence,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ReceiptCounter copyWithCompanion(ReceiptCountersCompanion data) {
    return ReceiptCounter(
      terminalCode: data.terminalCode.present
          ? data.terminalCode.value
          : this.terminalCode,
      lastSequence: data.lastSequence.present
          ? data.lastSequence.value
          : this.lastSequence,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptCounter(')
          ..write('terminalCode: $terminalCode, ')
          ..write('lastSequence: $lastSequence, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(terminalCode, lastSequence, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptCounter &&
          other.terminalCode == this.terminalCode &&
          other.lastSequence == this.lastSequence &&
          other.updatedAt == this.updatedAt);
}

class ReceiptCountersCompanion extends UpdateCompanion<ReceiptCounter> {
  final Value<String> terminalCode;
  final Value<int> lastSequence;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ReceiptCountersCompanion({
    this.terminalCode = const Value.absent(),
    this.lastSequence = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptCountersCompanion.insert({
    required String terminalCode,
    this.lastSequence = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : terminalCode = Value(terminalCode),
       updatedAt = Value(updatedAt);
  static Insertable<ReceiptCounter> custom({
    Expression<String>? terminalCode,
    Expression<int>? lastSequence,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (terminalCode != null) 'terminal_code': terminalCode,
      if (lastSequence != null) 'last_sequence': lastSequence,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptCountersCompanion copyWith({
    Value<String>? terminalCode,
    Value<int>? lastSequence,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ReceiptCountersCompanion(
      terminalCode: terminalCode ?? this.terminalCode,
      lastSequence: lastSequence ?? this.lastSequence,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (terminalCode.present) {
      map['terminal_code'] = Variable<String>(terminalCode.value);
    }
    if (lastSequence.present) {
      map['last_sequence'] = Variable<int>(lastSequence.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptCountersCompanion(')
          ..write('terminalCode: $terminalCode, ')
          ..write('lastSequence: $lastSequence, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CatalogCategoriesTable catalogCategories =
      $CatalogCategoriesTable(this);
  late final $CatalogProductsTable catalogProducts = $CatalogProductsTable(
    this,
  );
  late final $CatalogVariantsTable catalogVariants = $CatalogVariantsTable(
    this,
  );
  late final $CatalogAddonsTable catalogAddons = $CatalogAddonsTable(this);
  late final $LocalOrdersTable localOrders = $LocalOrdersTable(this);
  late final $OrderItemsTable orderItems = $OrderItemsTable(this);
  late final $LocalSalesTable localSales = $LocalSalesTable(this);
  late final $SaleItemsTable saleItems = $SaleItemsTable(this);
  late final $SalePaymentsTable salePayments = $SalePaymentsTable(this);
  late final $OutboxEventsTable outboxEvents = $OutboxEventsTable(this);
  late final $LocalShiftsTable localShifts = $LocalShiftsTable(this);
  late final $CashMovementsTable cashMovements = $CashMovementsTable(this);
  late final $PrintJobsTable printJobs = $PrintJobsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $ReceiptCountersTable receiptCounters = $ReceiptCountersTable(
    this,
  );
  late final Index catalogProductsCategory = Index(
    'catalog_products_category',
    'CREATE INDEX catalog_products_category ON catalog_products (category_uuid)',
  );
  late final Index catalogVariantsProduct = Index(
    'catalog_variants_product',
    'CREATE INDEX catalog_variants_product ON catalog_variants (product_uuid)',
  );
  late final Index catalogAddonsProduct = Index(
    'catalog_addons_product',
    'CREATE INDEX catalog_addons_product ON catalog_addons (product_uuid)',
  );
  late final Index localOrdersStatus = Index(
    'local_orders_status',
    'CREATE INDEX local_orders_status ON local_orders (status)',
  );
  late final Index orderItemsOrder = Index(
    'order_items_order',
    'CREATE INDEX order_items_order ON order_items (order_uuid)',
  );
  late final Index localSalesTransacted = Index(
    'local_sales_transacted',
    'CREATE INDEX local_sales_transacted ON local_sales (transacted_at)',
  );
  late final Index saleItemsSale = Index(
    'sale_items_sale',
    'CREATE INDEX sale_items_sale ON sale_items (sale_uuid)',
  );
  late final Index salePaymentsSale = Index(
    'sale_payments_sale',
    'CREATE INDEX sale_payments_sale ON sale_payments (sale_uuid)',
  );
  late final Index salePaymentsUuid = Index(
    'sale_payments_uuid',
    'CREATE INDEX sale_payments_uuid ON sale_payments (payment_uuid)',
  );
  late final Index outboxStatusSequence = Index(
    'outbox_status_sequence',
    'CREATE INDEX outbox_status_sequence ON outbox_events (status, sequence)',
  );
  late final Index localShiftsStatus = Index(
    'local_shifts_status',
    'CREATE INDEX local_shifts_status ON local_shifts (status)',
  );
  late final Index cashMovementsShift = Index(
    'cash_movements_shift',
    'CREATE INDEX cash_movements_shift ON cash_movements (shift_uuid)',
  );
  late final Index printJobsStatus = Index(
    'print_jobs_status',
    'CREATE INDEX print_jobs_status ON print_jobs (status)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catalogCategories,
    catalogProducts,
    catalogVariants,
    catalogAddons,
    localOrders,
    orderItems,
    localSales,
    saleItems,
    salePayments,
    outboxEvents,
    localShifts,
    cashMovements,
    printJobs,
    settings,
    syncState,
    receiptCounters,
    catalogProductsCategory,
    catalogVariantsProduct,
    catalogAddonsProduct,
    localOrdersStatus,
    orderItemsOrder,
    localSalesTransacted,
    saleItemsSale,
    salePaymentsSale,
    salePaymentsUuid,
    outboxStatusSequence,
    localShiftsStatus,
    cashMovementsShift,
    printJobsStatus,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'catalog_categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('catalog_products', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'catalog_products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('catalog_variants', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'catalog_products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('catalog_addons', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_orders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('order_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sale_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_sales',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sale_payments', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'local_shifts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cash_movements', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CatalogCategoriesTableCreateCompanionBuilder =
    CatalogCategoriesCompanion Function({
      required String uuid,
      required String name,
      Value<int> sortOrder,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$CatalogCategoriesTableUpdateCompanionBuilder =
    CatalogCategoriesCompanion Function({
      Value<String> uuid,
      Value<String> name,
      Value<int> sortOrder,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$CatalogCategoriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CatalogCategoriesTable,
          CatalogCategory
        > {
  $$CatalogCategoriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$CatalogProductsTable, List<CatalogProduct>>
  _catalogProductsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.catalogProducts,
    aliasName: 'catalog_categories__uuid__catalog_products__category_uuid',
  );

  $$CatalogProductsTableProcessedTableManager get catalogProductsRefs {
    final manager =
        $$CatalogProductsTableTableManager($_db, $_db.catalogProducts).filter(
          (f) => f.categoryUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _catalogProductsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CatalogCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogCategoriesTable> {
  $$CatalogCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> catalogProductsRefs(
    Expression<bool> Function($$CatalogProductsTableFilterComposer f) f,
  ) {
    final $$CatalogProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.categoryUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableFilterComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatalogCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogCategoriesTable> {
  $$CatalogCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogCategoriesTable> {
  $$CatalogCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> catalogProductsRefs<T extends Object>(
    Expression<T> Function($$CatalogProductsTableAnnotationComposer a) f,
  ) {
    final $$CatalogProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.categoryUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatalogCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogCategoriesTable,
          CatalogCategory,
          $$CatalogCategoriesTableFilterComposer,
          $$CatalogCategoriesTableOrderingComposer,
          $$CatalogCategoriesTableAnnotationComposer,
          $$CatalogCategoriesTableCreateCompanionBuilder,
          $$CatalogCategoriesTableUpdateCompanionBuilder,
          (CatalogCategory, $$CatalogCategoriesTableReferences),
          CatalogCategory,
          PrefetchHooks Function({bool catalogProductsRefs})
        > {
  $$CatalogCategoriesTableTableManager(
    _$AppDatabase db,
    $CatalogCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogCategoriesCompanion(
                uuid: uuid,
                name: name,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogCategoriesCompanion.insert(
                uuid: uuid,
                name: name,
                sortOrder: sortOrder,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogCategoriesTable, CatalogCategory>(table),
                  $$CatalogCategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({catalogProductsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (catalogProductsRefs) db.catalogProducts,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (catalogProductsRefs)
                    await $_getPrefetchedDataByColumns<
                      CatalogCategory,
                      $CatalogCategoriesTable,
                      CatalogProduct,
                      $CatalogProductsTable
                    >(
                      currentTable: table,
                      referencedTable: $$CatalogCategoriesTableReferences
                          ._catalogProductsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CatalogCategoriesTableReferences(
                            db,
                            table,
                            p0,
                          ).catalogProductsRefs,
                      currentColumn: 'uuid',
                      referencedColumn: 'category_uuid',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CatalogCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogCategoriesTable,
      CatalogCategory,
      $$CatalogCategoriesTableFilterComposer,
      $$CatalogCategoriesTableOrderingComposer,
      $$CatalogCategoriesTableAnnotationComposer,
      $$CatalogCategoriesTableCreateCompanionBuilder,
      $$CatalogCategoriesTableUpdateCompanionBuilder,
      (CatalogCategory, $$CatalogCategoriesTableReferences),
      CatalogCategory,
      PrefetchHooks Function({bool catalogProductsRefs})
    >;
typedef $$CatalogProductsTableCreateCompanionBuilder =
    CatalogProductsCompanion Function({
      required String uuid,
      Value<String> sku,
      Value<String?> barcode,
      required String name,
      Value<String?> description,
      Value<String> unit,
      Value<int> price,
      Value<int> taxRateBasisPoints,
      Value<bool> isActive,
      Value<bool> isAvailable,
      Value<String?> imageUrl,
      Value<String?> categoryUuid,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });
typedef $$CatalogProductsTableUpdateCompanionBuilder =
    CatalogProductsCompanion Function({
      Value<String> uuid,
      Value<String> sku,
      Value<String?> barcode,
      Value<String> name,
      Value<String?> description,
      Value<String> unit,
      Value<int> price,
      Value<int> taxRateBasisPoints,
      Value<bool> isActive,
      Value<bool> isAvailable,
      Value<String?> imageUrl,
      Value<String?> categoryUuid,
      Value<DateTime?> updatedAt,
      Value<int> rowid,
    });

final class $$CatalogProductsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CatalogProductsTable, CatalogProduct> {
  $$CatalogProductsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogCategoriesTable _categoryUuidTable(_$AppDatabase db) => db
      .catalogCategories
      .createAlias('catalog_products__category_uuid__catalog_categories__uuid');

  $$CatalogCategoriesTableProcessedTableManager? get categoryUuid {
    final $_column = $_itemColumn<String>('category_uuid');
    if ($_column == null) return null;
    final manager = $$CatalogCategoriesTableTableManager(
      $_db,
      $_db.catalogCategories,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CatalogVariantsTable, List<CatalogVariant>>
  _catalogVariantsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.catalogVariants,
    aliasName: 'catalog_products__uuid__catalog_variants__product_uuid',
  );

  $$CatalogVariantsTableProcessedTableManager get catalogVariantsRefs {
    final manager =
        $$CatalogVariantsTableTableManager($_db, $_db.catalogVariants).filter(
          (f) => f.productUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _catalogVariantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CatalogAddonsTable, List<CatalogAddon>>
  _catalogAddonsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.catalogAddons,
    aliasName: 'catalog_products__uuid__catalog_addons__product_uuid',
  );

  $$CatalogAddonsTableProcessedTableManager get catalogAddonsRefs {
    final manager = $$CatalogAddonsTableTableManager($_db, $_db.catalogAddons)
        .filter(
          (f) => f.productUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_catalogAddonsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CatalogProductsTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogProductsTable> {
  $$CatalogProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogCategoriesTableFilterComposer get categoryUuid {
    final $$CatalogCategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryUuid,
      referencedTable: $db.catalogCategories,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogCategoriesTableFilterComposer(
            $db: $db,
            $table: $db.catalogCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> catalogVariantsRefs(
    Expression<bool> Function($$CatalogVariantsTableFilterComposer f) f,
  ) {
    final $$CatalogVariantsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.catalogVariants,
      getReferencedColumn: (t) => t.productUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogVariantsTableFilterComposer(
            $db: $db,
            $table: $db.catalogVariants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> catalogAddonsRefs(
    Expression<bool> Function($$CatalogAddonsTableFilterComposer f) f,
  ) {
    final $$CatalogAddonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.catalogAddons,
      getReferencedColumn: (t) => t.productUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogAddonsTableFilterComposer(
            $db: $db,
            $table: $db.catalogAddons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatalogProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogProductsTable> {
  $$CatalogProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogCategoriesTableOrderingComposer get categoryUuid {
    final $$CatalogCategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryUuid,
      referencedTable: $db.catalogCategories,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogCategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.catalogCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogProductsTable> {
  $$CatalogProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CatalogCategoriesTableAnnotationComposer get categoryUuid {
    final $$CatalogCategoriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.categoryUuid,
          referencedTable: $db.catalogCategories,
          getReferencedColumn: (t) => t.uuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CatalogCategoriesTableAnnotationComposer(
                $db: $db,
                $table: $db.catalogCategories,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  Expression<T> catalogVariantsRefs<T extends Object>(
    Expression<T> Function($$CatalogVariantsTableAnnotationComposer a) f,
  ) {
    final $$CatalogVariantsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.catalogVariants,
      getReferencedColumn: (t) => t.productUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogVariantsTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogVariants,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> catalogAddonsRefs<T extends Object>(
    Expression<T> Function($$CatalogAddonsTableAnnotationComposer a) f,
  ) {
    final $$CatalogAddonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.catalogAddons,
      getReferencedColumn: (t) => t.productUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogAddonsTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogAddons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CatalogProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogProductsTable,
          CatalogProduct,
          $$CatalogProductsTableFilterComposer,
          $$CatalogProductsTableOrderingComposer,
          $$CatalogProductsTableAnnotationComposer,
          $$CatalogProductsTableCreateCompanionBuilder,
          $$CatalogProductsTableUpdateCompanionBuilder,
          (CatalogProduct, $$CatalogProductsTableReferences),
          CatalogProduct,
          PrefetchHooks Function({
            bool categoryUuid,
            bool catalogVariantsRefs,
            bool catalogAddonsRefs,
          })
        > {
  $$CatalogProductsTableTableManager(
    _$AppDatabase db,
    $CatalogProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> categoryUuid = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogProductsCompanion(
                uuid: uuid,
                sku: sku,
                barcode: barcode,
                name: name,
                description: description,
                unit: unit,
                price: price,
                taxRateBasisPoints: taxRateBasisPoints,
                isActive: isActive,
                isAvailable: isAvailable,
                imageUrl: imageUrl,
                categoryUuid: categoryUuid,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                Value<String> sku = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<String?> categoryUuid = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogProductsCompanion.insert(
                uuid: uuid,
                sku: sku,
                barcode: barcode,
                name: name,
                description: description,
                unit: unit,
                price: price,
                taxRateBasisPoints: taxRateBasisPoints,
                isActive: isActive,
                isAvailable: isAvailable,
                imageUrl: imageUrl,
                categoryUuid: categoryUuid,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogProductsTable, CatalogProduct>(table),
                  $$CatalogProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryUuid = false,
                catalogVariantsRefs = false,
                catalogAddonsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (catalogVariantsRefs) db.catalogVariants,
                    if (catalogAddonsRefs) db.catalogAddons,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryUuid,
                                    referencedTable:
                                        $$CatalogProductsTableReferences
                                            ._categoryUuidTable(db),
                                    referencedColumn:
                                        $$CatalogProductsTableReferences
                                            ._categoryUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (catalogVariantsRefs)
                        await $_getPrefetchedDataByColumns<
                          CatalogProduct,
                          $CatalogProductsTable,
                          CatalogVariant,
                          $CatalogVariantsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProductsTableReferences
                              ._catalogVariantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).catalogVariantsRefs,
                          currentColumn: 'uuid',
                          referencedColumn: 'product_uuid',
                          typedResults: items,
                        ),
                      if (catalogAddonsRefs)
                        await $_getPrefetchedDataByColumns<
                          CatalogProduct,
                          $CatalogProductsTable,
                          CatalogAddon,
                          $CatalogAddonsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CatalogProductsTableReferences
                              ._catalogAddonsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CatalogProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).catalogAddonsRefs,
                          currentColumn: 'uuid',
                          referencedColumn: 'product_uuid',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CatalogProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogProductsTable,
      CatalogProduct,
      $$CatalogProductsTableFilterComposer,
      $$CatalogProductsTableOrderingComposer,
      $$CatalogProductsTableAnnotationComposer,
      $$CatalogProductsTableCreateCompanionBuilder,
      $$CatalogProductsTableUpdateCompanionBuilder,
      (CatalogProduct, $$CatalogProductsTableReferences),
      CatalogProduct,
      PrefetchHooks Function({
        bool categoryUuid,
        bool catalogVariantsRefs,
        bool catalogAddonsRefs,
      })
    >;
typedef $$CatalogVariantsTableCreateCompanionBuilder =
    CatalogVariantsCompanion Function({
      required String uuid,
      required String productUuid,
      required String name,
      Value<String?> sku,
      Value<int> priceDelta,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$CatalogVariantsTableUpdateCompanionBuilder =
    CatalogVariantsCompanion Function({
      Value<String> uuid,
      Value<String> productUuid,
      Value<String> name,
      Value<String?> sku,
      Value<int> priceDelta,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$CatalogVariantsTableReferences
    extends
        BaseReferences<_$AppDatabase, $CatalogVariantsTable, CatalogVariant> {
  $$CatalogVariantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProductsTable _productUuidTable(_$AppDatabase db) => db
      .catalogProducts
      .createAlias('catalog_variants__product_uuid__catalog_products__uuid');

  $$CatalogProductsTableProcessedTableManager get productUuid {
    final $_column = $_itemColumn<String>('product_uuid')!;

    final manager = $$CatalogProductsTableTableManager(
      $_db,
      $_db.catalogProducts,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CatalogVariantsTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogVariantsTable> {
  $$CatalogVariantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceDelta => $composableBuilder(
    column: $table.priceDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProductsTableFilterComposer get productUuid {
    final $$CatalogProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productUuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableFilterComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogVariantsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogVariantsTable> {
  $$CatalogVariantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceDelta => $composableBuilder(
    column: $table.priceDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProductsTableOrderingComposer get productUuid {
    final $$CatalogProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productUuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogVariantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogVariantsTable> {
  $$CatalogVariantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<int> get priceDelta => $composableBuilder(
    column: $table.priceDelta,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$CatalogProductsTableAnnotationComposer get productUuid {
    final $$CatalogProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productUuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogVariantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogVariantsTable,
          CatalogVariant,
          $$CatalogVariantsTableFilterComposer,
          $$CatalogVariantsTableOrderingComposer,
          $$CatalogVariantsTableAnnotationComposer,
          $$CatalogVariantsTableCreateCompanionBuilder,
          $$CatalogVariantsTableUpdateCompanionBuilder,
          (CatalogVariant, $$CatalogVariantsTableReferences),
          CatalogVariant,
          PrefetchHooks Function({bool productUuid})
        > {
  $$CatalogVariantsTableTableManager(
    _$AppDatabase db,
    $CatalogVariantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogVariantsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogVariantsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogVariantsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> productUuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<int> priceDelta = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogVariantsCompanion(
                uuid: uuid,
                productUuid: productUuid,
                name: name,
                sku: sku,
                priceDelta: priceDelta,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String productUuid,
                required String name,
                Value<String?> sku = const Value.absent(),
                Value<int> priceDelta = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogVariantsCompanion.insert(
                uuid: uuid,
                productUuid: productUuid,
                name: name,
                sku: sku,
                priceDelta: priceDelta,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogVariantsTable, CatalogVariant>(table),
                  $$CatalogVariantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productUuid,
                                referencedTable:
                                    $$CatalogVariantsTableReferences
                                        ._productUuidTable(db),
                                referencedColumn:
                                    $$CatalogVariantsTableReferences
                                        ._productUuidTable(db)
                                        .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CatalogVariantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogVariantsTable,
      CatalogVariant,
      $$CatalogVariantsTableFilterComposer,
      $$CatalogVariantsTableOrderingComposer,
      $$CatalogVariantsTableAnnotationComposer,
      $$CatalogVariantsTableCreateCompanionBuilder,
      $$CatalogVariantsTableUpdateCompanionBuilder,
      (CatalogVariant, $$CatalogVariantsTableReferences),
      CatalogVariant,
      PrefetchHooks Function({bool productUuid})
    >;
typedef $$CatalogAddonsTableCreateCompanionBuilder =
    CatalogAddonsCompanion Function({
      required String uuid,
      required String productUuid,
      required String name,
      Value<int> price,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$CatalogAddonsTableUpdateCompanionBuilder =
    CatalogAddonsCompanion Function({
      Value<String> uuid,
      Value<String> productUuid,
      Value<String> name,
      Value<int> price,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$CatalogAddonsTableReferences
    extends BaseReferences<_$AppDatabase, $CatalogAddonsTable, CatalogAddon> {
  $$CatalogAddonsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CatalogProductsTable _productUuidTable(_$AppDatabase db) => db
      .catalogProducts
      .createAlias('catalog_addons__product_uuid__catalog_products__uuid');

  $$CatalogProductsTableProcessedTableManager get productUuid {
    final $_column = $_itemColumn<String>('product_uuid')!;

    final manager = $$CatalogProductsTableTableManager(
      $_db,
      $_db.catalogProducts,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CatalogAddonsTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogAddonsTable> {
  $$CatalogAddonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$CatalogProductsTableFilterComposer get productUuid {
    final $$CatalogProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productUuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableFilterComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogAddonsTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogAddonsTable> {
  $$CatalogAddonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$CatalogProductsTableOrderingComposer get productUuid {
    final $$CatalogProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productUuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableOrderingComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogAddonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogAddonsTable> {
  $$CatalogAddonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$CatalogProductsTableAnnotationComposer get productUuid {
    final $$CatalogProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productUuid,
      referencedTable: $db.catalogProducts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CatalogProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.catalogProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CatalogAddonsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogAddonsTable,
          CatalogAddon,
          $$CatalogAddonsTableFilterComposer,
          $$CatalogAddonsTableOrderingComposer,
          $$CatalogAddonsTableAnnotationComposer,
          $$CatalogAddonsTableCreateCompanionBuilder,
          $$CatalogAddonsTableUpdateCompanionBuilder,
          (CatalogAddon, $$CatalogAddonsTableReferences),
          CatalogAddon,
          PrefetchHooks Function({bool productUuid})
        > {
  $$CatalogAddonsTableTableManager(_$AppDatabase db, $CatalogAddonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CatalogAddonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CatalogAddonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CatalogAddonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> productUuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> price = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogAddonsCompanion(
                uuid: uuid,
                productUuid: productUuid,
                name: name,
                price: price,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String productUuid,
                required String name,
                Value<int> price = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogAddonsCompanion.insert(
                uuid: uuid,
                productUuid: productUuid,
                name: name,
                price: price,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CatalogAddonsTable, CatalogAddon>(table),
                  $$CatalogAddonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.productUuid,
                                referencedTable: $$CatalogAddonsTableReferences
                                    ._productUuidTable(db),
                                referencedColumn: $$CatalogAddonsTableReferences
                                    ._productUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CatalogAddonsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogAddonsTable,
      CatalogAddon,
      $$CatalogAddonsTableFilterComposer,
      $$CatalogAddonsTableOrderingComposer,
      $$CatalogAddonsTableAnnotationComposer,
      $$CatalogAddonsTableCreateCompanionBuilder,
      $$CatalogAddonsTableUpdateCompanionBuilder,
      (CatalogAddon, $$CatalogAddonsTableReferences),
      CatalogAddon,
      PrefetchHooks Function({bool productUuid})
    >;
typedef $$LocalOrdersTableCreateCompanionBuilder =
    LocalOrdersCompanion Function({
      required String uuid,
      Value<String?> orderNumber,
      Value<String> orderType,
      Value<String?> tableNumber,
      Value<String?> notes,
      Value<String> status,
      Value<int> transactionDiscount,
      Value<int> baseVersion,
      Value<String?> serverUuid,
      Value<bool> synced,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalOrdersTableUpdateCompanionBuilder =
    LocalOrdersCompanion Function({
      Value<String> uuid,
      Value<String?> orderNumber,
      Value<String> orderType,
      Value<String?> tableNumber,
      Value<String?> notes,
      Value<String> status,
      Value<int> transactionDiscount,
      Value<int> baseVersion,
      Value<String?> serverUuid,
      Value<bool> synced,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LocalOrdersTableReferences
    extends BaseReferences<_$AppDatabase, $LocalOrdersTable, LocalOrder> {
  $$LocalOrdersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OrderItemsTable, List<OrderItem>>
  _orderItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.orderItems,
    aliasName: 'local_orders__uuid__order_items__order_uuid',
  );

  $$OrderItemsTableProcessedTableManager get orderItemsRefs {
    final manager = $$OrderItemsTableTableManager(
      $_db,
      $_db.orderItems,
    ).filter((f) => f.orderUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_orderItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionDiscount => $composableBuilder(
    column: $table.transactionDiscount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverUuid => $composableBuilder(
    column: $table.serverUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> orderItemsRefs(
    Expression<bool> Function($$OrderItemsTableFilterComposer f) f,
  ) {
    final $$OrderItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableFilterComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionDiscount => $composableBuilder(
    column: $table.transactionDiscount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverUuid => $composableBuilder(
    column: $table.serverUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOrdersTable> {
  $$LocalOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get transactionDiscount => $composableBuilder(
    column: $table.transactionDiscount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverUuid => $composableBuilder(
    column: $table.serverUuid,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> orderItemsRefs<T extends Object>(
    Expression<T> Function($$OrderItemsTableAnnotationComposer a) f,
  ) {
    final $$OrderItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.orderItems,
      getReferencedColumn: (t) => t.orderUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OrderItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.orderItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOrdersTable,
          LocalOrder,
          $$LocalOrdersTableFilterComposer,
          $$LocalOrdersTableOrderingComposer,
          $$LocalOrdersTableAnnotationComposer,
          $$LocalOrdersTableCreateCompanionBuilder,
          $$LocalOrdersTableUpdateCompanionBuilder,
          (LocalOrder, $$LocalOrdersTableReferences),
          LocalOrder,
          PrefetchHooks Function({bool orderItemsRefs})
        > {
  $$LocalOrdersTableTableManager(_$AppDatabase db, $LocalOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String?> orderNumber = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> transactionDiscount = const Value.absent(),
                Value<int> baseVersion = const Value.absent(),
                Value<String?> serverUuid = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion(
                uuid: uuid,
                orderNumber: orderNumber,
                orderType: orderType,
                tableNumber: tableNumber,
                notes: notes,
                status: status,
                transactionDiscount: transactionDiscount,
                baseVersion: baseVersion,
                serverUuid: serverUuid,
                synced: synced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                Value<String?> orderNumber = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> transactionDiscount = const Value.absent(),
                Value<int> baseVersion = const Value.absent(),
                Value<String?> serverUuid = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalOrdersCompanion.insert(
                uuid: uuid,
                orderNumber: orderNumber,
                orderType: orderType,
                tableNumber: tableNumber,
                notes: notes,
                status: status,
                transactionDiscount: transactionDiscount,
                baseVersion: baseVersion,
                serverUuid: serverUuid,
                synced: synced,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalOrdersTable, LocalOrder>(table),
                  $$LocalOrdersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (orderItemsRefs) db.orderItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderItemsRefs)
                    await $_getPrefetchedDataByColumns<
                      LocalOrder,
                      $LocalOrdersTable,
                      OrderItem,
                      $OrderItemsTable
                    >(
                      currentTable: table,
                      referencedTable: $$LocalOrdersTableReferences
                          ._orderItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalOrdersTableReferences(
                            db,
                            table,
                            p0,
                          ).orderItemsRefs,
                      currentColumn: 'uuid',
                      referencedColumn: 'order_uuid',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOrdersTable,
      LocalOrder,
      $$LocalOrdersTableFilterComposer,
      $$LocalOrdersTableOrderingComposer,
      $$LocalOrdersTableAnnotationComposer,
      $$LocalOrdersTableCreateCompanionBuilder,
      $$LocalOrdersTableUpdateCompanionBuilder,
      (LocalOrder, $$LocalOrdersTableReferences),
      LocalOrder,
      PrefetchHooks Function({bool orderItemsRefs})
    >;
typedef $$OrderItemsTableCreateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> id,
      required String orderUuid,
      required String productUuid,
      required String productName,
      Value<String?> variantUuid,
      Value<String?> variantName,
      Value<String> addonsJson,
      required int unitPrice,
      required int quantity,
      Value<int> itemDiscount,
      Value<int> taxRateBasisPoints,
      Value<int> lineSubtotal,
      Value<int> lineTotal,
      Value<String?> notes,
    });
typedef $$OrderItemsTableUpdateCompanionBuilder =
    OrderItemsCompanion Function({
      Value<int> id,
      Value<String> orderUuid,
      Value<String> productUuid,
      Value<String> productName,
      Value<String?> variantUuid,
      Value<String?> variantName,
      Value<String> addonsJson,
      Value<int> unitPrice,
      Value<int> quantity,
      Value<int> itemDiscount,
      Value<int> taxRateBasisPoints,
      Value<int> lineSubtotal,
      Value<int> lineTotal,
      Value<String?> notes,
    });

final class $$OrderItemsTableReferences
    extends BaseReferences<_$AppDatabase, $OrderItemsTable, OrderItem> {
  $$OrderItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalOrdersTable _orderUuidTable(_$AppDatabase db) =>
      db.localOrders.createAlias('order_items__order_uuid__local_orders__uuid');

  $$LocalOrdersTableProcessedTableManager get orderUuid {
    final $_column = $_itemColumn<String>('order_uuid')!;

    final manager = $$LocalOrdersTableTableManager(
      $_db,
      $_db.localOrders,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OrderItemsTableFilterComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productUuid => $composableBuilder(
    column: $table.productUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantUuid => $composableBuilder(
    column: $table.variantUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addonsJson => $composableBuilder(
    column: $table.addonsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemDiscount => $composableBuilder(
    column: $table.itemDiscount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineSubtotal => $composableBuilder(
    column: $table.lineSubtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalOrdersTableFilterComposer get orderUuid {
    final $$LocalOrdersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderUuid,
      referencedTable: $db.localOrders,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalOrdersTableFilterComposer(
            $db: $db,
            $table: $db.localOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productUuid => $composableBuilder(
    column: $table.productUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantUuid => $composableBuilder(
    column: $table.variantUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addonsJson => $composableBuilder(
    column: $table.addonsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemDiscount => $composableBuilder(
    column: $table.itemDiscount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineSubtotal => $composableBuilder(
    column: $table.lineSubtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalOrdersTableOrderingComposer get orderUuid {
    final $$LocalOrdersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderUuid,
      referencedTable: $db.localOrders,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalOrdersTableOrderingComposer(
            $db: $db,
            $table: $db.localOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderItemsTable> {
  $$OrderItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productUuid => $composableBuilder(
    column: $table.productUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantUuid => $composableBuilder(
    column: $table.variantUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addonsJson => $composableBuilder(
    column: $table.addonsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get itemDiscount => $composableBuilder(
    column: $table.itemDiscount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxRateBasisPoints => $composableBuilder(
    column: $table.taxRateBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineSubtotal => $composableBuilder(
    column: $table.lineSubtotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$LocalOrdersTableAnnotationComposer get orderUuid {
    final $$LocalOrdersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderUuid,
      referencedTable: $db.localOrders,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalOrdersTableAnnotationComposer(
            $db: $db,
            $table: $db.localOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OrderItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderItemsTable,
          OrderItem,
          $$OrderItemsTableFilterComposer,
          $$OrderItemsTableOrderingComposer,
          $$OrderItemsTableAnnotationComposer,
          $$OrderItemsTableCreateCompanionBuilder,
          $$OrderItemsTableUpdateCompanionBuilder,
          (OrderItem, $$OrderItemsTableReferences),
          OrderItem,
          PrefetchHooks Function({bool orderUuid})
        > {
  $$OrderItemsTableTableManager(_$AppDatabase db, $OrderItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> orderUuid = const Value.absent(),
                Value<String> productUuid = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> variantUuid = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<String> addonsJson = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> itemDiscount = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<int> lineSubtotal = const Value.absent(),
                Value<int> lineTotal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => OrderItemsCompanion(
                id: id,
                orderUuid: orderUuid,
                productUuid: productUuid,
                productName: productName,
                variantUuid: variantUuid,
                variantName: variantName,
                addonsJson: addonsJson,
                unitPrice: unitPrice,
                quantity: quantity,
                itemDiscount: itemDiscount,
                taxRateBasisPoints: taxRateBasisPoints,
                lineSubtotal: lineSubtotal,
                lineTotal: lineTotal,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String orderUuid,
                required String productUuid,
                required String productName,
                Value<String?> variantUuid = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<String> addonsJson = const Value.absent(),
                required int unitPrice,
                required int quantity,
                Value<int> itemDiscount = const Value.absent(),
                Value<int> taxRateBasisPoints = const Value.absent(),
                Value<int> lineSubtotal = const Value.absent(),
                Value<int> lineTotal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => OrderItemsCompanion.insert(
                id: id,
                orderUuid: orderUuid,
                productUuid: productUuid,
                productName: productName,
                variantUuid: variantUuid,
                variantName: variantName,
                addonsJson: addonsJson,
                unitPrice: unitPrice,
                quantity: quantity,
                itemDiscount: itemDiscount,
                taxRateBasisPoints: taxRateBasisPoints,
                lineSubtotal: lineSubtotal,
                lineTotal: lineTotal,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OrderItemsTable, OrderItem>(table),
                  $$OrderItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.orderUuid,
                                referencedTable: $$OrderItemsTableReferences
                                    ._orderUuidTable(db),
                                referencedColumn: $$OrderItemsTableReferences
                                    ._orderUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OrderItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderItemsTable,
      OrderItem,
      $$OrderItemsTableFilterComposer,
      $$OrderItemsTableOrderingComposer,
      $$OrderItemsTableAnnotationComposer,
      $$OrderItemsTableCreateCompanionBuilder,
      $$OrderItemsTableUpdateCompanionBuilder,
      (OrderItem, $$OrderItemsTableReferences),
      OrderItem,
      PrefetchHooks Function({bool orderUuid})
    >;
typedef $$LocalSalesTableCreateCompanionBuilder =
    LocalSalesCompanion Function({
      required String uuid,
      required String receiptNumber,
      Value<String?> orderUuid,
      Value<String?> serverOrderUuid,
      Value<int> sourceOrderVersion,
      Value<String> origin,
      required String orderType,
      Value<String?> tableNumber,
      Value<String> lifecycleStatus,
      Value<String> paymentStatus,
      required int subtotal,
      Value<int> itemDiscountTotal,
      Value<int> transactionDiscountTotal,
      Value<int> discountTotal,
      Value<int> netSubtotal,
      Value<int> serviceCharge,
      Value<int> taxTotal,
      required int total,
      Value<int> confirmedAmount,
      Value<int> awaitingAmount,
      Value<int> refundedAmount,
      Value<String?> shiftUuid,
      Value<String?> cashierName,
      Value<String?> notes,
      Value<bool> synced,
      required DateTime transactedAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalSalesTableUpdateCompanionBuilder =
    LocalSalesCompanion Function({
      Value<String> uuid,
      Value<String> receiptNumber,
      Value<String?> orderUuid,
      Value<String?> serverOrderUuid,
      Value<int> sourceOrderVersion,
      Value<String> origin,
      Value<String> orderType,
      Value<String?> tableNumber,
      Value<String> lifecycleStatus,
      Value<String> paymentStatus,
      Value<int> subtotal,
      Value<int> itemDiscountTotal,
      Value<int> transactionDiscountTotal,
      Value<int> discountTotal,
      Value<int> netSubtotal,
      Value<int> serviceCharge,
      Value<int> taxTotal,
      Value<int> total,
      Value<int> confirmedAmount,
      Value<int> awaitingAmount,
      Value<int> refundedAmount,
      Value<String?> shiftUuid,
      Value<String?> cashierName,
      Value<String?> notes,
      Value<bool> synced,
      Value<DateTime> transactedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LocalSalesTableReferences
    extends BaseReferences<_$AppDatabase, $LocalSalesTable, LocalSale> {
  $$LocalSalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SaleItemsTable, List<SaleItem>>
  _saleItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.saleItems,
    aliasName: 'local_sales__uuid__sale_items__sale_uuid',
  );

  $$SaleItemsTableProcessedTableManager get saleItemsRefs {
    final manager = $$SaleItemsTableTableManager(
      $_db,
      $_db.saleItems,
    ).filter((f) => f.saleUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_saleItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SalePaymentsTable, List<SalePayment>>
  _salePaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.salePayments,
    aliasName: 'local_sales__uuid__sale_payments__sale_uuid',
  );

  $$SalePaymentsTableProcessedTableManager get salePaymentsRefs {
    final manager = $$SalePaymentsTableTableManager(
      $_db,
      $_db.salePayments,
    ).filter((f) => f.saleUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_salePaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalSalesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderUuid => $composableBuilder(
    column: $table.orderUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverOrderUuid => $composableBuilder(
    column: $table.serverOrderUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceOrderVersion => $composableBuilder(
    column: $table.sourceOrderVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycleStatus => $composableBuilder(
    column: $table.lifecycleStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemDiscountTotal => $composableBuilder(
    column: $table.itemDiscountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get transactionDiscountTotal => $composableBuilder(
    column: $table.transactionDiscountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get netSubtotal => $composableBuilder(
    column: $table.netSubtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxTotal => $composableBuilder(
    column: $table.taxTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get confirmedAmount => $composableBuilder(
    column: $table.confirmedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awaitingAmount => $composableBuilder(
    column: $table.awaitingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get refundedAmount => $composableBuilder(
    column: $table.refundedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shiftUuid => $composableBuilder(
    column: $table.shiftUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transactedAt => $composableBuilder(
    column: $table.transactedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> saleItemsRefs(
    Expression<bool> Function($$SaleItemsTableFilterComposer f) f,
  ) {
    final $$SaleItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.saleUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableFilterComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> salePaymentsRefs(
    Expression<bool> Function($$SalePaymentsTableFilterComposer f) f,
  ) {
    final $$SalePaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.salePayments,
      getReferencedColumn: (t) => t.saleUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalePaymentsTableFilterComposer(
            $db: $db,
            $table: $db.salePayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderUuid => $composableBuilder(
    column: $table.orderUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverOrderUuid => $composableBuilder(
    column: $table.serverOrderUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceOrderVersion => $composableBuilder(
    column: $table.sourceOrderVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderType => $composableBuilder(
    column: $table.orderType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycleStatus => $composableBuilder(
    column: $table.lifecycleStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemDiscountTotal => $composableBuilder(
    column: $table.itemDiscountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get transactionDiscountTotal => $composableBuilder(
    column: $table.transactionDiscountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get netSubtotal => $composableBuilder(
    column: $table.netSubtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxTotal => $composableBuilder(
    column: $table.taxTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get confirmedAmount => $composableBuilder(
    column: $table.confirmedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awaitingAmount => $composableBuilder(
    column: $table.awaitingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get refundedAmount => $composableBuilder(
    column: $table.refundedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shiftUuid => $composableBuilder(
    column: $table.shiftUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transactedAt => $composableBuilder(
    column: $table.transactedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSalesTable> {
  $$LocalSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get orderUuid =>
      $composableBuilder(column: $table.orderUuid, builder: (column) => column);

  GeneratedColumn<String> get serverOrderUuid => $composableBuilder(
    column: $table.serverOrderUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceOrderVersion => $composableBuilder(
    column: $table.sourceOrderVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get orderType =>
      $composableBuilder(column: $table.orderType, builder: (column) => column);

  GeneratedColumn<String> get tableNumber => $composableBuilder(
    column: $table.tableNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lifecycleStatus => $composableBuilder(
    column: $table.lifecycleStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get itemDiscountTotal => $composableBuilder(
    column: $table.itemDiscountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get transactionDiscountTotal => $composableBuilder(
    column: $table.transactionDiscountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get netSubtotal => $composableBuilder(
    column: $table.netSubtotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get serviceCharge => $composableBuilder(
    column: $table.serviceCharge,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxTotal =>
      $composableBuilder(column: $table.taxTotal, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get confirmedAmount => $composableBuilder(
    column: $table.confirmedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awaitingAmount => $composableBuilder(
    column: $table.awaitingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get refundedAmount => $composableBuilder(
    column: $table.refundedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get shiftUuid =>
      $composableBuilder(column: $table.shiftUuid, builder: (column) => column);

  GeneratedColumn<String> get cashierName => $composableBuilder(
    column: $table.cashierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<DateTime> get transactedAt => $composableBuilder(
    column: $table.transactedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> saleItemsRefs<T extends Object>(
    Expression<T> Function($$SaleItemsTableAnnotationComposer a) f,
  ) {
    final $$SaleItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.saleItems,
      getReferencedColumn: (t) => t.saleUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SaleItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.saleItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> salePaymentsRefs<T extends Object>(
    Expression<T> Function($$SalePaymentsTableAnnotationComposer a) f,
  ) {
    final $$SalePaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.salePayments,
      getReferencedColumn: (t) => t.saleUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalePaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.salePayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSalesTable,
          LocalSale,
          $$LocalSalesTableFilterComposer,
          $$LocalSalesTableOrderingComposer,
          $$LocalSalesTableAnnotationComposer,
          $$LocalSalesTableCreateCompanionBuilder,
          $$LocalSalesTableUpdateCompanionBuilder,
          (LocalSale, $$LocalSalesTableReferences),
          LocalSale,
          PrefetchHooks Function({bool saleItemsRefs, bool salePaymentsRefs})
        > {
  $$LocalSalesTableTableManager(_$AppDatabase db, $LocalSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> receiptNumber = const Value.absent(),
                Value<String?> orderUuid = const Value.absent(),
                Value<String?> serverOrderUuid = const Value.absent(),
                Value<int> sourceOrderVersion = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String> orderType = const Value.absent(),
                Value<String?> tableNumber = const Value.absent(),
                Value<String> lifecycleStatus = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> itemDiscountTotal = const Value.absent(),
                Value<int> transactionDiscountTotal = const Value.absent(),
                Value<int> discountTotal = const Value.absent(),
                Value<int> netSubtotal = const Value.absent(),
                Value<int> serviceCharge = const Value.absent(),
                Value<int> taxTotal = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> confirmedAmount = const Value.absent(),
                Value<int> awaitingAmount = const Value.absent(),
                Value<int> refundedAmount = const Value.absent(),
                Value<String?> shiftUuid = const Value.absent(),
                Value<String?> cashierName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<DateTime> transactedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion(
                uuid: uuid,
                receiptNumber: receiptNumber,
                orderUuid: orderUuid,
                serverOrderUuid: serverOrderUuid,
                sourceOrderVersion: sourceOrderVersion,
                origin: origin,
                orderType: orderType,
                tableNumber: tableNumber,
                lifecycleStatus: lifecycleStatus,
                paymentStatus: paymentStatus,
                subtotal: subtotal,
                itemDiscountTotal: itemDiscountTotal,
                transactionDiscountTotal: transactionDiscountTotal,
                discountTotal: discountTotal,
                netSubtotal: netSubtotal,
                serviceCharge: serviceCharge,
                taxTotal: taxTotal,
                total: total,
                confirmedAmount: confirmedAmount,
                awaitingAmount: awaitingAmount,
                refundedAmount: refundedAmount,
                shiftUuid: shiftUuid,
                cashierName: cashierName,
                notes: notes,
                synced: synced,
                transactedAt: transactedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String receiptNumber,
                Value<String?> orderUuid = const Value.absent(),
                Value<String?> serverOrderUuid = const Value.absent(),
                Value<int> sourceOrderVersion = const Value.absent(),
                Value<String> origin = const Value.absent(),
                required String orderType,
                Value<String?> tableNumber = const Value.absent(),
                Value<String> lifecycleStatus = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                required int subtotal,
                Value<int> itemDiscountTotal = const Value.absent(),
                Value<int> transactionDiscountTotal = const Value.absent(),
                Value<int> discountTotal = const Value.absent(),
                Value<int> netSubtotal = const Value.absent(),
                Value<int> serviceCharge = const Value.absent(),
                Value<int> taxTotal = const Value.absent(),
                required int total,
                Value<int> confirmedAmount = const Value.absent(),
                Value<int> awaitingAmount = const Value.absent(),
                Value<int> refundedAmount = const Value.absent(),
                Value<String?> shiftUuid = const Value.absent(),
                Value<String?> cashierName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                required DateTime transactedAt,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalSalesCompanion.insert(
                uuid: uuid,
                receiptNumber: receiptNumber,
                orderUuid: orderUuid,
                serverOrderUuid: serverOrderUuid,
                sourceOrderVersion: sourceOrderVersion,
                origin: origin,
                orderType: orderType,
                tableNumber: tableNumber,
                lifecycleStatus: lifecycleStatus,
                paymentStatus: paymentStatus,
                subtotal: subtotal,
                itemDiscountTotal: itemDiscountTotal,
                transactionDiscountTotal: transactionDiscountTotal,
                discountTotal: discountTotal,
                netSubtotal: netSubtotal,
                serviceCharge: serviceCharge,
                taxTotal: taxTotal,
                total: total,
                confirmedAmount: confirmedAmount,
                awaitingAmount: awaitingAmount,
                refundedAmount: refundedAmount,
                shiftUuid: shiftUuid,
                cashierName: cashierName,
                notes: notes,
                synced: synced,
                transactedAt: transactedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSalesTable, LocalSale>(table),
                  $$LocalSalesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({saleItemsRefs = false, salePaymentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (saleItemsRefs) db.saleItems,
                    if (salePaymentsRefs) db.salePayments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (saleItemsRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalSale,
                          $LocalSalesTable,
                          SaleItem,
                          $SaleItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$LocalSalesTableReferences
                              ._saleItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalSalesTableReferences(
                                db,
                                table,
                                p0,
                              ).saleItemsRefs,
                          currentColumn: 'uuid',
                          referencedColumn: 'sale_uuid',
                          typedResults: items,
                        ),
                      if (salePaymentsRefs)
                        await $_getPrefetchedDataByColumns<
                          LocalSale,
                          $LocalSalesTable,
                          SalePayment,
                          $SalePaymentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$LocalSalesTableReferences
                              ._salePaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LocalSalesTableReferences(
                                db,
                                table,
                                p0,
                              ).salePaymentsRefs,
                          currentColumn: 'uuid',
                          referencedColumn: 'sale_uuid',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LocalSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSalesTable,
      LocalSale,
      $$LocalSalesTableFilterComposer,
      $$LocalSalesTableOrderingComposer,
      $$LocalSalesTableAnnotationComposer,
      $$LocalSalesTableCreateCompanionBuilder,
      $$LocalSalesTableUpdateCompanionBuilder,
      (LocalSale, $$LocalSalesTableReferences),
      LocalSale,
      PrefetchHooks Function({bool saleItemsRefs, bool salePaymentsRefs})
    >;
typedef $$SaleItemsTableCreateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<int> id,
      required String saleUuid,
      required String productUuid,
      required String productName,
      Value<String?> variantUuid,
      Value<String?> variantName,
      Value<String> addonsJson,
      required int unitPrice,
      required int quantity,
      Value<int> itemDiscount,
      Value<int> lineSubtotal,
      Value<int> lineTotal,
      Value<String?> notes,
    });
typedef $$SaleItemsTableUpdateCompanionBuilder =
    SaleItemsCompanion Function({
      Value<int> id,
      Value<String> saleUuid,
      Value<String> productUuid,
      Value<String> productName,
      Value<String?> variantUuid,
      Value<String?> variantName,
      Value<String> addonsJson,
      Value<int> unitPrice,
      Value<int> quantity,
      Value<int> itemDiscount,
      Value<int> lineSubtotal,
      Value<int> lineTotal,
      Value<String?> notes,
    });

final class $$SaleItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SaleItemsTable, SaleItem> {
  $$SaleItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalSalesTable _saleUuidTable(_$AppDatabase db) =>
      db.localSales.createAlias('sale_items__sale_uuid__local_sales__uuid');

  $$LocalSalesTableProcessedTableManager get saleUuid {
    final $_column = $_itemColumn<String>('sale_uuid')!;

    final manager = $$LocalSalesTableTableManager(
      $_db,
      $_db.localSales,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SaleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productUuid => $composableBuilder(
    column: $table.productUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantUuid => $composableBuilder(
    column: $table.variantUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get addonsJson => $composableBuilder(
    column: $table.addonsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemDiscount => $composableBuilder(
    column: $table.itemDiscount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineSubtotal => $composableBuilder(
    column: $table.lineSubtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalSalesTableFilterComposer get saleUuid {
    final $$LocalSalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleUuid,
      referencedTable: $db.localSales,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSalesTableFilterComposer(
            $db: $db,
            $table: $db.localSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productUuid => $composableBuilder(
    column: $table.productUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantUuid => $composableBuilder(
    column: $table.variantUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get addonsJson => $composableBuilder(
    column: $table.addonsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemDiscount => $composableBuilder(
    column: $table.itemDiscount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineSubtotal => $composableBuilder(
    column: $table.lineSubtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineTotal => $composableBuilder(
    column: $table.lineTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalSalesTableOrderingComposer get saleUuid {
    final $$LocalSalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleUuid,
      referencedTable: $db.localSales,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSalesTableOrderingComposer(
            $db: $db,
            $table: $db.localSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SaleItemsTable> {
  $$SaleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productUuid => $composableBuilder(
    column: $table.productUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantUuid => $composableBuilder(
    column: $table.variantUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get addonsJson => $composableBuilder(
    column: $table.addonsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get itemDiscount => $composableBuilder(
    column: $table.itemDiscount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineSubtotal => $composableBuilder(
    column: $table.lineSubtotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lineTotal =>
      $composableBuilder(column: $table.lineTotal, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  $$LocalSalesTableAnnotationComposer get saleUuid {
    final $$LocalSalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleUuid,
      referencedTable: $db.localSales,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSalesTableAnnotationComposer(
            $db: $db,
            $table: $db.localSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SaleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SaleItemsTable,
          SaleItem,
          $$SaleItemsTableFilterComposer,
          $$SaleItemsTableOrderingComposer,
          $$SaleItemsTableAnnotationComposer,
          $$SaleItemsTableCreateCompanionBuilder,
          $$SaleItemsTableUpdateCompanionBuilder,
          (SaleItem, $$SaleItemsTableReferences),
          SaleItem,
          PrefetchHooks Function({bool saleUuid})
        > {
  $$SaleItemsTableTableManager(_$AppDatabase db, $SaleItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SaleItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SaleItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SaleItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> saleUuid = const Value.absent(),
                Value<String> productUuid = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String?> variantUuid = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<String> addonsJson = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> itemDiscount = const Value.absent(),
                Value<int> lineSubtotal = const Value.absent(),
                Value<int> lineTotal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SaleItemsCompanion(
                id: id,
                saleUuid: saleUuid,
                productUuid: productUuid,
                productName: productName,
                variantUuid: variantUuid,
                variantName: variantName,
                addonsJson: addonsJson,
                unitPrice: unitPrice,
                quantity: quantity,
                itemDiscount: itemDiscount,
                lineSubtotal: lineSubtotal,
                lineTotal: lineTotal,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String saleUuid,
                required String productUuid,
                required String productName,
                Value<String?> variantUuid = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<String> addonsJson = const Value.absent(),
                required int unitPrice,
                required int quantity,
                Value<int> itemDiscount = const Value.absent(),
                Value<int> lineSubtotal = const Value.absent(),
                Value<int> lineTotal = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => SaleItemsCompanion.insert(
                id: id,
                saleUuid: saleUuid,
                productUuid: productUuid,
                productName: productName,
                variantUuid: variantUuid,
                variantName: variantName,
                addonsJson: addonsJson,
                unitPrice: unitPrice,
                quantity: quantity,
                itemDiscount: itemDiscount,
                lineSubtotal: lineSubtotal,
                lineTotal: lineTotal,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SaleItemsTable, SaleItem>(table),
                  $$SaleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleUuid,
                                referencedTable: $$SaleItemsTableReferences
                                    ._saleUuidTable(db),
                                referencedColumn: $$SaleItemsTableReferences
                                    ._saleUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SaleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SaleItemsTable,
      SaleItem,
      $$SaleItemsTableFilterComposer,
      $$SaleItemsTableOrderingComposer,
      $$SaleItemsTableAnnotationComposer,
      $$SaleItemsTableCreateCompanionBuilder,
      $$SaleItemsTableUpdateCompanionBuilder,
      (SaleItem, $$SaleItemsTableReferences),
      SaleItem,
      PrefetchHooks Function({bool saleUuid})
    >;
typedef $$SalePaymentsTableCreateCompanionBuilder =
    SalePaymentsCompanion Function({
      Value<int> id,
      required String saleUuid,
      Value<String?> paymentUuid,
      required String method,
      required int amount,
      Value<int?> tenderedAmount,
      Value<int?> changeAmount,
      Value<int?> verifiedAmount,
      required String status,
      Value<String?> providerReference,
      Value<String?> idempotencyKey,
      Value<String?> notes,
      required DateTime createdAt,
      Value<DateTime?> confirmedAt,
    });
typedef $$SalePaymentsTableUpdateCompanionBuilder =
    SalePaymentsCompanion Function({
      Value<int> id,
      Value<String> saleUuid,
      Value<String?> paymentUuid,
      Value<String> method,
      Value<int> amount,
      Value<int?> tenderedAmount,
      Value<int?> changeAmount,
      Value<int?> verifiedAmount,
      Value<String> status,
      Value<String?> providerReference,
      Value<String?> idempotencyKey,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime?> confirmedAt,
    });

final class $$SalePaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $SalePaymentsTable, SalePayment> {
  $$SalePaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LocalSalesTable _saleUuidTable(_$AppDatabase db) =>
      db.localSales.createAlias('sale_payments__sale_uuid__local_sales__uuid');

  $$LocalSalesTableProcessedTableManager get saleUuid {
    final $_column = $_itemColumn<String>('sale_uuid')!;

    final manager = $$LocalSalesTableTableManager(
      $_db,
      $_db.localSales,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_saleUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SalePaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentUuid => $composableBuilder(
    column: $table.paymentUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tenderedAmount => $composableBuilder(
    column: $table.tenderedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get verifiedAmount => $composableBuilder(
    column: $table.verifiedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerReference => $composableBuilder(
    column: $table.providerReference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalSalesTableFilterComposer get saleUuid {
    final $$LocalSalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleUuid,
      referencedTable: $db.localSales,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSalesTableFilterComposer(
            $db: $db,
            $table: $db.localSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalePaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentUuid => $composableBuilder(
    column: $table.paymentUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tenderedAmount => $composableBuilder(
    column: $table.tenderedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get verifiedAmount => $composableBuilder(
    column: $table.verifiedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerReference => $composableBuilder(
    column: $table.providerReference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalSalesTableOrderingComposer get saleUuid {
    final $$LocalSalesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleUuid,
      referencedTable: $db.localSales,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSalesTableOrderingComposer(
            $db: $db,
            $table: $db.localSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalePaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalePaymentsTable> {
  $$SalePaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get paymentUuid => $composableBuilder(
    column: $table.paymentUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get tenderedAmount => $composableBuilder(
    column: $table.tenderedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changeAmount => $composableBuilder(
    column: $table.changeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get verifiedAmount => $composableBuilder(
    column: $table.verifiedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get providerReference => $composableBuilder(
    column: $table.providerReference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get confirmedAt => $composableBuilder(
    column: $table.confirmedAt,
    builder: (column) => column,
  );

  $$LocalSalesTableAnnotationComposer get saleUuid {
    final $$LocalSalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.saleUuid,
      referencedTable: $db.localSales,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSalesTableAnnotationComposer(
            $db: $db,
            $table: $db.localSales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalePaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalePaymentsTable,
          SalePayment,
          $$SalePaymentsTableFilterComposer,
          $$SalePaymentsTableOrderingComposer,
          $$SalePaymentsTableAnnotationComposer,
          $$SalePaymentsTableCreateCompanionBuilder,
          $$SalePaymentsTableUpdateCompanionBuilder,
          (SalePayment, $$SalePaymentsTableReferences),
          SalePayment,
          PrefetchHooks Function({bool saleUuid})
        > {
  $$SalePaymentsTableTableManager(_$AppDatabase db, $SalePaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalePaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalePaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalePaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> saleUuid = const Value.absent(),
                Value<String?> paymentUuid = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<int?> tenderedAmount = const Value.absent(),
                Value<int?> changeAmount = const Value.absent(),
                Value<int?> verifiedAmount = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> providerReference = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => SalePaymentsCompanion(
                id: id,
                saleUuid: saleUuid,
                paymentUuid: paymentUuid,
                method: method,
                amount: amount,
                tenderedAmount: tenderedAmount,
                changeAmount: changeAmount,
                verifiedAmount: verifiedAmount,
                status: status,
                providerReference: providerReference,
                idempotencyKey: idempotencyKey,
                notes: notes,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String saleUuid,
                Value<String?> paymentUuid = const Value.absent(),
                required String method,
                required int amount,
                Value<int?> tenderedAmount = const Value.absent(),
                Value<int?> changeAmount = const Value.absent(),
                Value<int?> verifiedAmount = const Value.absent(),
                required String status,
                Value<String?> providerReference = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> confirmedAt = const Value.absent(),
              }) => SalePaymentsCompanion.insert(
                id: id,
                saleUuid: saleUuid,
                paymentUuid: paymentUuid,
                method: method,
                amount: amount,
                tenderedAmount: tenderedAmount,
                changeAmount: changeAmount,
                verifiedAmount: verifiedAmount,
                status: status,
                providerReference: providerReference,
                idempotencyKey: idempotencyKey,
                notes: notes,
                createdAt: createdAt,
                confirmedAt: confirmedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SalePaymentsTable, SalePayment>(table),
                  $$SalePaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({saleUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (saleUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.saleUuid,
                                referencedTable: $$SalePaymentsTableReferences
                                    ._saleUuidTable(db),
                                referencedColumn: $$SalePaymentsTableReferences
                                    ._saleUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SalePaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalePaymentsTable,
      SalePayment,
      $$SalePaymentsTableFilterComposer,
      $$SalePaymentsTableOrderingComposer,
      $$SalePaymentsTableAnnotationComposer,
      $$SalePaymentsTableCreateCompanionBuilder,
      $$SalePaymentsTableUpdateCompanionBuilder,
      (SalePayment, $$SalePaymentsTableReferences),
      SalePayment,
      PrefetchHooks Function({bool saleUuid})
    >;
typedef $$OutboxEventsTableCreateCompanionBuilder =
    OutboxEventsCompanion Function({
      Value<int> id,
      required String eventId,
      required String eventType,
      required String aggregateType,
      required String aggregateId,
      required int sequence,
      Value<int> schemaVersion,
      required String payloadJson,
      Value<String> status,
      Value<int> attempts,
      Value<bool> retryable,
      Value<String?> lastError,
      Value<DateTime?> lastAttemptAt,
      required DateTime occurredAt,
      required DateTime createdAt,
    });
typedef $$OutboxEventsTableUpdateCompanionBuilder =
    OutboxEventsCompanion Function({
      Value<int> id,
      Value<String> eventId,
      Value<String> eventType,
      Value<String> aggregateType,
      Value<String> aggregateId,
      Value<int> sequence,
      Value<int> schemaVersion,
      Value<String> payloadJson,
      Value<String> status,
      Value<int> attempts,
      Value<bool> retryable,
      Value<String?> lastError,
      Value<DateTime?> lastAttemptAt,
      Value<DateTime> occurredAt,
      Value<DateTime> createdAt,
    });

class $$OutboxEventsTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get retryable => $composableBuilder(
    column: $table.retryable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get retryable => $composableBuilder(
    column: $table.retryable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxEventsTable> {
  $$OutboxEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get aggregateType => $composableBuilder(
    column: $table.aggregateType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get aggregateId => $composableBuilder(
    column: $table.aggregateId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<bool> get retryable =>
      $composableBuilder(column: $table.retryable, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$OutboxEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxEventsTable,
          OutboxEvent,
          $$OutboxEventsTableFilterComposer,
          $$OutboxEventsTableOrderingComposer,
          $$OutboxEventsTableAnnotationComposer,
          $$OutboxEventsTableCreateCompanionBuilder,
          $$OutboxEventsTableUpdateCompanionBuilder,
          (
            OutboxEvent,
            BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxEvent>,
          ),
          OutboxEvent,
          PrefetchHooks Function()
        > {
  $$OutboxEventsTableTableManager(_$AppDatabase db, $OutboxEventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> aggregateType = const Value.absent(),
                Value<String> aggregateId = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> retryable = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => OutboxEventsCompanion(
                id: id,
                eventId: eventId,
                eventType: eventType,
                aggregateType: aggregateType,
                aggregateId: aggregateId,
                sequence: sequence,
                schemaVersion: schemaVersion,
                payloadJson: payloadJson,
                status: status,
                attempts: attempts,
                retryable: retryable,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
                occurredAt: occurredAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventId,
                required String eventType,
                required String aggregateType,
                required String aggregateId,
                required int sequence,
                Value<int> schemaVersion = const Value.absent(),
                required String payloadJson,
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<bool> retryable = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                required DateTime occurredAt,
                required DateTime createdAt,
              }) => OutboxEventsCompanion.insert(
                id: id,
                eventId: eventId,
                eventType: eventType,
                aggregateType: aggregateType,
                aggregateId: aggregateId,
                sequence: sequence,
                schemaVersion: schemaVersion,
                payloadJson: payloadJson,
                status: status,
                attempts: attempts,
                retryable: retryable,
                lastError: lastError,
                lastAttemptAt: lastAttemptAt,
                occurredAt: occurredAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEventsTable, OutboxEvent>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $OutboxEventsTable,
                    OutboxEvent
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxEventsTable,
      OutboxEvent,
      $$OutboxEventsTableFilterComposer,
      $$OutboxEventsTableOrderingComposer,
      $$OutboxEventsTableAnnotationComposer,
      $$OutboxEventsTableCreateCompanionBuilder,
      $$OutboxEventsTableUpdateCompanionBuilder,
      (
        OutboxEvent,
        BaseReferences<_$AppDatabase, $OutboxEventsTable, OutboxEvent>,
      ),
      OutboxEvent,
      PrefetchHooks Function()
    >;
typedef $$LocalShiftsTableCreateCompanionBuilder =
    LocalShiftsCompanion Function({
      required String uuid,
      Value<String> status,
      Value<int> openingCash,
      Value<String?> openingNotes,
      required DateTime openedAt,
      Value<DateTime?> closedAt,
      Value<int?> expectedCash,
      Value<int?> actualCash,
      Value<int?> difference,
      Value<String?> closingNotes,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$LocalShiftsTableUpdateCompanionBuilder =
    LocalShiftsCompanion Function({
      Value<String> uuid,
      Value<String> status,
      Value<int> openingCash,
      Value<String?> openingNotes,
      Value<DateTime> openedAt,
      Value<DateTime?> closedAt,
      Value<int?> expectedCash,
      Value<int?> actualCash,
      Value<int?> difference,
      Value<String?> closingNotes,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$LocalShiftsTableReferences
    extends BaseReferences<_$AppDatabase, $LocalShiftsTable, LocalShift> {
  $$LocalShiftsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CashMovementsTable, List<CashMovement>>
  _cashMovementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cashMovements,
    aliasName: 'local_shifts__uuid__cash_movements__shift_uuid',
  );

  $$CashMovementsTableProcessedTableManager get cashMovementsRefs {
    final manager = $$CashMovementsTableTableManager(
      $_db,
      $_db.cashMovements,
    ).filter((f) => f.shiftUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!));

    final cache = $_typedResult.readTableOrNull(_cashMovementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LocalShiftsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalShiftsTable> {
  $$LocalShiftsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openingNotes => $composableBuilder(
    column: $table.openingNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualCash => $composableBuilder(
    column: $table.actualCash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difference => $composableBuilder(
    column: $table.difference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closingNotes => $composableBuilder(
    column: $table.closingNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> cashMovementsRefs(
    Expression<bool> Function($$CashMovementsTableFilterComposer f) f,
  ) {
    final $$CashMovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.cashMovements,
      getReferencedColumn: (t) => t.shiftUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashMovementsTableFilterComposer(
            $db: $db,
            $table: $db.cashMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalShiftsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalShiftsTable> {
  $$LocalShiftsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openingNotes => $composableBuilder(
    column: $table.openingNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get openedAt => $composableBuilder(
    column: $table.openedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualCash => $composableBuilder(
    column: $table.actualCash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difference => $composableBuilder(
    column: $table.difference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closingNotes => $composableBuilder(
    column: $table.closingNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalShiftsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalShiftsTable> {
  $$LocalShiftsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get openingCash => $composableBuilder(
    column: $table.openingCash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openingNotes => $composableBuilder(
    column: $table.openingNotes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get openedAt =>
      $composableBuilder(column: $table.openedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  GeneratedColumn<int> get expectedCash => $composableBuilder(
    column: $table.expectedCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualCash => $composableBuilder(
    column: $table.actualCash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get difference => $composableBuilder(
    column: $table.difference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get closingNotes => $composableBuilder(
    column: $table.closingNotes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  Expression<T> cashMovementsRefs<T extends Object>(
    Expression<T> Function($$CashMovementsTableAnnotationComposer a) f,
  ) {
    final $$CashMovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.cashMovements,
      getReferencedColumn: (t) => t.shiftUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CashMovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.cashMovements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LocalShiftsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalShiftsTable,
          LocalShift,
          $$LocalShiftsTableFilterComposer,
          $$LocalShiftsTableOrderingComposer,
          $$LocalShiftsTableAnnotationComposer,
          $$LocalShiftsTableCreateCompanionBuilder,
          $$LocalShiftsTableUpdateCompanionBuilder,
          (LocalShift, $$LocalShiftsTableReferences),
          LocalShift,
          PrefetchHooks Function({bool cashMovementsRefs})
        > {
  $$LocalShiftsTableTableManager(_$AppDatabase db, $LocalShiftsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalShiftsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalShiftsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalShiftsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> openingCash = const Value.absent(),
                Value<String?> openingNotes = const Value.absent(),
                Value<DateTime> openedAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int?> expectedCash = const Value.absent(),
                Value<int?> actualCash = const Value.absent(),
                Value<int?> difference = const Value.absent(),
                Value<String?> closingNotes = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShiftsCompanion(
                uuid: uuid,
                status: status,
                openingCash: openingCash,
                openingNotes: openingNotes,
                openedAt: openedAt,
                closedAt: closedAt,
                expectedCash: expectedCash,
                actualCash: actualCash,
                difference: difference,
                closingNotes: closingNotes,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                Value<String> status = const Value.absent(),
                Value<int> openingCash = const Value.absent(),
                Value<String?> openingNotes = const Value.absent(),
                required DateTime openedAt,
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int?> expectedCash = const Value.absent(),
                Value<int?> actualCash = const Value.absent(),
                Value<int?> difference = const Value.absent(),
                Value<String?> closingNotes = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalShiftsCompanion.insert(
                uuid: uuid,
                status: status,
                openingCash: openingCash,
                openingNotes: openingNotes,
                openedAt: openedAt,
                closedAt: closedAt,
                expectedCash: expectedCash,
                actualCash: actualCash,
                difference: difference,
                closingNotes: closingNotes,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalShiftsTable, LocalShift>(table),
                  $$LocalShiftsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cashMovementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (cashMovementsRefs) db.cashMovements,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cashMovementsRefs)
                    await $_getPrefetchedDataByColumns<
                      LocalShift,
                      $LocalShiftsTable,
                      CashMovement,
                      $CashMovementsTable
                    >(
                      currentTable: table,
                      referencedTable: $$LocalShiftsTableReferences
                          ._cashMovementsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$LocalShiftsTableReferences(
                            db,
                            table,
                            p0,
                          ).cashMovementsRefs,
                      currentColumn: 'uuid',
                      referencedColumn: 'shift_uuid',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$LocalShiftsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalShiftsTable,
      LocalShift,
      $$LocalShiftsTableFilterComposer,
      $$LocalShiftsTableOrderingComposer,
      $$LocalShiftsTableAnnotationComposer,
      $$LocalShiftsTableCreateCompanionBuilder,
      $$LocalShiftsTableUpdateCompanionBuilder,
      (LocalShift, $$LocalShiftsTableReferences),
      LocalShift,
      PrefetchHooks Function({bool cashMovementsRefs})
    >;
typedef $$CashMovementsTableCreateCompanionBuilder =
    CashMovementsCompanion Function({
      required String uuid,
      required String shiftUuid,
      required String type,
      required int amount,
      required String reason,
      required DateTime createdAt,
      Value<bool> synced,
      Value<int> rowid,
    });
typedef $$CashMovementsTableUpdateCompanionBuilder =
    CashMovementsCompanion Function({
      Value<String> uuid,
      Value<String> shiftUuid,
      Value<String> type,
      Value<int> amount,
      Value<String> reason,
      Value<DateTime> createdAt,
      Value<bool> synced,
      Value<int> rowid,
    });

final class $$CashMovementsTableReferences
    extends BaseReferences<_$AppDatabase, $CashMovementsTable, CashMovement> {
  $$CashMovementsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LocalShiftsTable _shiftUuidTable(_$AppDatabase db) => db.localShifts
      .createAlias('cash_movements__shift_uuid__local_shifts__uuid');

  $$LocalShiftsTableProcessedTableManager get shiftUuid {
    final $_column = $_itemColumn<String>('shift_uuid')!;

    final manager = $$LocalShiftsTableTableManager(
      $_db,
      $_db.localShifts,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_shiftUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CashMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  $$LocalShiftsTableFilterComposer get shiftUuid {
    final $$LocalShiftsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftUuid,
      referencedTable: $db.localShifts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShiftsTableFilterComposer(
            $db: $db,
            $table: $db.localShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  $$LocalShiftsTableOrderingComposer get shiftUuid {
    final $$LocalShiftsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftUuid,
      referencedTable: $db.localShifts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShiftsTableOrderingComposer(
            $db: $db,
            $table: $db.localShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CashMovementsTable> {
  $$CashMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  $$LocalShiftsTableAnnotationComposer get shiftUuid {
    final $$LocalShiftsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.shiftUuid,
      referencedTable: $db.localShifts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalShiftsTableAnnotationComposer(
            $db: $db,
            $table: $db.localShifts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CashMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CashMovementsTable,
          CashMovement,
          $$CashMovementsTableFilterComposer,
          $$CashMovementsTableOrderingComposer,
          $$CashMovementsTableAnnotationComposer,
          $$CashMovementsTableCreateCompanionBuilder,
          $$CashMovementsTableUpdateCompanionBuilder,
          (CashMovement, $$CashMovementsTableReferences),
          CashMovement,
          PrefetchHooks Function({bool shiftUuid})
        > {
  $$CashMovementsTableTableManager(_$AppDatabase db, $CashMovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CashMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CashMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CashMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> shiftUuid = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> reason = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashMovementsCompanion(
                uuid: uuid,
                shiftUuid: shiftUuid,
                type: type,
                amount: amount,
                reason: reason,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String shiftUuid,
                required String type,
                required int amount,
                required String reason,
                required DateTime createdAt,
                Value<bool> synced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CashMovementsCompanion.insert(
                uuid: uuid,
                shiftUuid: shiftUuid,
                type: type,
                amount: amount,
                reason: reason,
                createdAt: createdAt,
                synced: synced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CashMovementsTable, CashMovement>(table),
                  $$CashMovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({shiftUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (shiftUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.shiftUuid,
                                referencedTable: $$CashMovementsTableReferences
                                    ._shiftUuidTable(db),
                                referencedColumn: $$CashMovementsTableReferences
                                    ._shiftUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CashMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CashMovementsTable,
      CashMovement,
      $$CashMovementsTableFilterComposer,
      $$CashMovementsTableOrderingComposer,
      $$CashMovementsTableAnnotationComposer,
      $$CashMovementsTableCreateCompanionBuilder,
      $$CashMovementsTableUpdateCompanionBuilder,
      (CashMovement, $$CashMovementsTableReferences),
      CashMovement,
      PrefetchHooks Function({bool shiftUuid})
    >;
typedef $$PrintJobsTableCreateCompanionBuilder =
    PrintJobsCompanion Function({
      Value<int> id,
      required String saleUuid,
      Value<String> kind,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      required DateTime createdAt,
      Value<DateTime?> printedAt,
    });
typedef $$PrintJobsTableUpdateCompanionBuilder =
    PrintJobsCompanion Function({
      Value<int> id,
      Value<String> saleUuid,
      Value<String> kind,
      Value<String> status,
      Value<int> attempts,
      Value<String?> lastError,
      Value<DateTime> createdAt,
      Value<DateTime?> printedAt,
    });

class $$PrintJobsTableFilterComposer
    extends Composer<_$AppDatabase, $PrintJobsTable> {
  $$PrintJobsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saleUuid => $composableBuilder(
    column: $table.saleUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrintJobsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrintJobsTable> {
  $$PrintJobsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saleUuid => $composableBuilder(
    column: $table.saleUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get printedAt => $composableBuilder(
    column: $table.printedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrintJobsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrintJobsTable> {
  $$PrintJobsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get saleUuid =>
      $composableBuilder(column: $table.saleUuid, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get printedAt =>
      $composableBuilder(column: $table.printedAt, builder: (column) => column);
}

class $$PrintJobsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrintJobsTable,
          PrintJob,
          $$PrintJobsTableFilterComposer,
          $$PrintJobsTableOrderingComposer,
          $$PrintJobsTableAnnotationComposer,
          $$PrintJobsTableCreateCompanionBuilder,
          $$PrintJobsTableUpdateCompanionBuilder,
          (PrintJob, BaseReferences<_$AppDatabase, $PrintJobsTable, PrintJob>),
          PrintJob,
          PrefetchHooks Function()
        > {
  $$PrintJobsTableTableManager(_$AppDatabase db, $PrintJobsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrintJobsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrintJobsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrintJobsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> saleUuid = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> printedAt = const Value.absent(),
              }) => PrintJobsCompanion(
                id: id,
                saleUuid: saleUuid,
                kind: kind,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                printedAt: printedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String saleUuid,
                Value<String> kind = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> printedAt = const Value.absent(),
              }) => PrintJobsCompanion.insert(
                id: id,
                saleUuid: saleUuid,
                kind: kind,
                status: status,
                attempts: attempts,
                lastError: lastError,
                createdAt: createdAt,
                printedAt: printedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrintJobsTable, PrintJob>(table),
                  BaseReferences<_$AppDatabase, $PrintJobsTable, PrintJob>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrintJobsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrintJobsTable,
      PrintJob,
      $$PrintJobsTableFilterComposer,
      $$PrintJobsTableOrderingComposer,
      $$PrintJobsTableAnnotationComposer,
      $$PrintJobsTableCreateCompanionBuilder,
      $$PrintJobsTableUpdateCompanionBuilder,
      (PrintJob, BaseReferences<_$AppDatabase, $PrintJobsTable, PrintJob>),
      PrintJob,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String?> cursor,
      Value<DateTime?> lastPulledAt,
      Value<DateTime?> lastPushedAt,
      Value<DateTime?> catalogSyncedAt,
      Value<String?> catalogVersion,
      Value<String?> lastServerTime,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<int> id,
      Value<String?> cursor,
      Value<DateTime?> lastPulledAt,
      Value<DateTime?> lastPushedAt,
      Value<DateTime?> catalogSyncedAt,
      Value<String?> catalogVersion,
      Value<String?> lastServerTime,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPulledAt => $composableBuilder(
    column: $table.lastPulledAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPushedAt => $composableBuilder(
    column: $table.lastPushedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get catalogSyncedAt => $composableBuilder(
    column: $table.catalogSyncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastServerTime => $composableBuilder(
    column: $table.lastServerTime,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPulledAt => $composableBuilder(
    column: $table.lastPulledAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPushedAt => $composableBuilder(
    column: $table.lastPushedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get catalogSyncedAt => $composableBuilder(
    column: $table.catalogSyncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastServerTime => $composableBuilder(
    column: $table.lastServerTime,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPulledAt => $composableBuilder(
    column: $table.lastPulledAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPushedAt => $composableBuilder(
    column: $table.lastPushedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get catalogSyncedAt => $composableBuilder(
    column: $table.catalogSyncedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogVersion => $composableBuilder(
    column: $table.catalogVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastServerTime => $composableBuilder(
    column: $table.lastServerTime,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateData,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastPulledAt = const Value.absent(),
                Value<DateTime?> lastPushedAt = const Value.absent(),
                Value<DateTime?> catalogSyncedAt = const Value.absent(),
                Value<String?> catalogVersion = const Value.absent(),
                Value<String?> lastServerTime = const Value.absent(),
              }) => SyncStateCompanion(
                id: id,
                cursor: cursor,
                lastPulledAt: lastPulledAt,
                lastPushedAt: lastPushedAt,
                catalogSyncedAt: catalogSyncedAt,
                catalogVersion: catalogVersion,
                lastServerTime: lastServerTime,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<DateTime?> lastPulledAt = const Value.absent(),
                Value<DateTime?> lastPushedAt = const Value.absent(),
                Value<DateTime?> catalogSyncedAt = const Value.absent(),
                Value<String?> catalogVersion = const Value.absent(),
                Value<String?> lastServerTime = const Value.absent(),
              }) => SyncStateCompanion.insert(
                id: id,
                cursor: cursor,
                lastPulledAt: lastPulledAt,
                lastPushedAt: lastPushedAt,
                catalogSyncedAt: catalogSyncedAt,
                catalogVersion: catalogVersion,
                lastServerTime: lastServerTime,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncStateTable, SyncStateData>(table),
                  BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateData,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateData,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateData>,
      ),
      SyncStateData,
      PrefetchHooks Function()
    >;
typedef $$ReceiptCountersTableCreateCompanionBuilder =
    ReceiptCountersCompanion Function({
      required String terminalCode,
      Value<int> lastSequence,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ReceiptCountersTableUpdateCompanionBuilder =
    ReceiptCountersCompanion Function({
      Value<String> terminalCode,
      Value<int> lastSequence,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ReceiptCountersTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptCountersTable> {
  $$ReceiptCountersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get terminalCode => $composableBuilder(
    column: $table.terminalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSequence => $composableBuilder(
    column: $table.lastSequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptCountersTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptCountersTable> {
  $$ReceiptCountersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get terminalCode => $composableBuilder(
    column: $table.terminalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSequence => $composableBuilder(
    column: $table.lastSequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptCountersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptCountersTable> {
  $$ReceiptCountersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get terminalCode => $composableBuilder(
    column: $table.terminalCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastSequence => $composableBuilder(
    column: $table.lastSequence,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ReceiptCountersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptCountersTable,
          ReceiptCounter,
          $$ReceiptCountersTableFilterComposer,
          $$ReceiptCountersTableOrderingComposer,
          $$ReceiptCountersTableAnnotationComposer,
          $$ReceiptCountersTableCreateCompanionBuilder,
          $$ReceiptCountersTableUpdateCompanionBuilder,
          (
            ReceiptCounter,
            BaseReferences<
              _$AppDatabase,
              $ReceiptCountersTable,
              ReceiptCounter
            >,
          ),
          ReceiptCounter,
          PrefetchHooks Function()
        > {
  $$ReceiptCountersTableTableManager(
    _$AppDatabase db,
    $ReceiptCountersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptCountersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptCountersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptCountersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> terminalCode = const Value.absent(),
                Value<int> lastSequence = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptCountersCompanion(
                terminalCode: terminalCode,
                lastSequence: lastSequence,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String terminalCode,
                Value<int> lastSequence = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptCountersCompanion.insert(
                terminalCode: terminalCode,
                lastSequence: lastSequence,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptCountersTable, ReceiptCounter>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ReceiptCountersTable,
                    ReceiptCounter
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptCountersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptCountersTable,
      ReceiptCounter,
      $$ReceiptCountersTableFilterComposer,
      $$ReceiptCountersTableOrderingComposer,
      $$ReceiptCountersTableAnnotationComposer,
      $$ReceiptCountersTableCreateCompanionBuilder,
      $$ReceiptCountersTableUpdateCompanionBuilder,
      (
        ReceiptCounter,
        BaseReferences<_$AppDatabase, $ReceiptCountersTable, ReceiptCounter>,
      ),
      ReceiptCounter,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CatalogCategoriesTableTableManager get catalogCategories =>
      $$CatalogCategoriesTableTableManager(_db, _db.catalogCategories);
  $$CatalogProductsTableTableManager get catalogProducts =>
      $$CatalogProductsTableTableManager(_db, _db.catalogProducts);
  $$CatalogVariantsTableTableManager get catalogVariants =>
      $$CatalogVariantsTableTableManager(_db, _db.catalogVariants);
  $$CatalogAddonsTableTableManager get catalogAddons =>
      $$CatalogAddonsTableTableManager(_db, _db.catalogAddons);
  $$LocalOrdersTableTableManager get localOrders =>
      $$LocalOrdersTableTableManager(_db, _db.localOrders);
  $$OrderItemsTableTableManager get orderItems =>
      $$OrderItemsTableTableManager(_db, _db.orderItems);
  $$LocalSalesTableTableManager get localSales =>
      $$LocalSalesTableTableManager(_db, _db.localSales);
  $$SaleItemsTableTableManager get saleItems =>
      $$SaleItemsTableTableManager(_db, _db.saleItems);
  $$SalePaymentsTableTableManager get salePayments =>
      $$SalePaymentsTableTableManager(_db, _db.salePayments);
  $$OutboxEventsTableTableManager get outboxEvents =>
      $$OutboxEventsTableTableManager(_db, _db.outboxEvents);
  $$LocalShiftsTableTableManager get localShifts =>
      $$LocalShiftsTableTableManager(_db, _db.localShifts);
  $$CashMovementsTableTableManager get cashMovements =>
      $$CashMovementsTableTableManager(_db, _db.cashMovements);
  $$PrintJobsTableTableManager get printJobs =>
      $$PrintJobsTableTableManager(_db, _db.printJobs);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$ReceiptCountersTableTableManager get receiptCounters =>
      $$ReceiptCountersTableTableManager(_db, _db.receiptCounters);
}
