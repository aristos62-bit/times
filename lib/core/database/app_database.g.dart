// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
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
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<int> parentId = GeneratedColumn<int>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CategoriesTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($CategoriesTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    description,
    icon,
    color,
    parentId,
    level,
    sortOrder,
    isActive,
    createdBy,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
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
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name, parentId},
  ];
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_id'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      ),
      createdAt: $CategoriesTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $CategoriesTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String uuid;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int? parentId;
  final int level;
  final int sortOrder;
  final bool isActive;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Category({
    required this.id,
    required this.uuid,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.parentId,
    required this.level,
    required this.sortOrder,
    required this.isActive,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<int>(parentId);
    }
    map['level'] = Variable<int>(level);
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_active'] = Variable<bool>(isActive);
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $CategoriesTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<DateTime>(
        $CategoriesTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      level: Value(level),
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      parentId: serializer.fromJson<int?>(json['parentId']),
      level: serializer.fromJson<int>(json['level']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'parentId': serializer.toJson<int?>(parentId),
      'level': serializer.toJson<int>(level),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isActive': serializer.toJson<bool>(isActive),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Category copyWith({
    int? id,
    String? uuid,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    Value<int?> parentId = const Value.absent(),
    int? level,
    int? sortOrder,
    bool? isActive,
    Value<String?> createdBy = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Category(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    parentId: parentId.present ? parentId.value : this.parentId,
    level: level ?? this.level,
    sortOrder: sortOrder ?? this.sortOrder,
    isActive: isActive ?? this.isActive,
    createdBy: createdBy.present ? createdBy.value : this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      level: data.level.present ? data.level.value : this.level,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    description,
    icon,
    color,
    parentId,
    level,
    sortOrder,
    isActive,
    createdBy,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.description == this.description &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.parentId == this.parentId &&
          other.level == this.level &&
          other.sortOrder == this.sortOrder &&
          other.isActive == this.isActive &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<int?> parentId;
  final Value<int> level;
  final Value<int> sortOrder;
  final Value<bool> isActive;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.parentId = const Value.absent(),
    this.level = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? parentId,
    Expression<int>? level,
    Expression<int>? sortOrder,
    Expression<bool>? isActive,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (parentId != null) 'parent_id': parentId,
      if (level != null) 'level': level,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isActive != null) 'is_active': isActive,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? icon,
    Value<String?>? color,
    Value<int?>? parentId,
    Value<int>? level,
    Value<int>? sortOrder,
    Value<bool>? isActive,
    Value<String?>? createdBy,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<int>(parentId.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $CategoriesTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $CategoriesTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('parentId: $parentId, ')
          ..write('level: $level, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isActive: $isActive, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SuppliersTable extends Suppliers
    with TableInfo<$SuppliersTable, Supplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuppliersTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatNumberMeta = const VerificationMeta(
    'vatNumber',
  );
  @override
  late final GeneratedColumn<String> vatNumber = GeneratedColumn<String>(
    'vat_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _taxOfficeMeta = const VerificationMeta(
    'taxOffice',
  );
  @override
  late final GeneratedColumn<String> taxOffice = GeneratedColumn<String>(
    'tax_office',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
    'mobile',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _websiteMeta = const VerificationMeta(
    'website',
  );
  @override
  late final GeneratedColumn<String> website = GeneratedColumn<String>(
    'website',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _postalCodeMeta = const VerificationMeta(
    'postalCode',
  );
  @override
  late final GeneratedColumn<String> postalCode = GeneratedColumn<String>(
    'postal_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Ελλάδα'),
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankAccountMeta = const VerificationMeta(
    'bankAccount',
  );
  @override
  late final GeneratedColumn<String> bankAccount = GeneratedColumn<String>(
    'bank_account',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
    'iban',
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
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SuppliersTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($SuppliersTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    vatNumber,
    taxOffice,
    phone,
    mobile,
    email,
    website,
    address,
    city,
    postalCode,
    country,
    bankName,
    bankAccount,
    iban,
    notes,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Supplier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
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
    if (data.containsKey('vat_number')) {
      context.handle(
        _vatNumberMeta,
        vatNumber.isAcceptableOrUnknown(data['vat_number']!, _vatNumberMeta),
      );
    }
    if (data.containsKey('tax_office')) {
      context.handle(
        _taxOfficeMeta,
        taxOffice.isAcceptableOrUnknown(data['tax_office']!, _taxOfficeMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('mobile')) {
      context.handle(
        _mobileMeta,
        mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    }
    if (data.containsKey('postal_code')) {
      context.handle(
        _postalCodeMeta,
        postalCode.isAcceptableOrUnknown(data['postal_code']!, _postalCodeMeta),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    }
    if (data.containsKey('bank_account')) {
      context.handle(
        _bankAccountMeta,
        bankAccount.isAcceptableOrUnknown(
          data['bank_account']!,
          _bankAccountMeta,
        ),
      );
    }
    if (data.containsKey('iban')) {
      context.handle(
        _ibanMeta,
        iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Supplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Supplier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      vatNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vat_number'],
      ),
      taxOffice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tax_office'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      mobile: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mobile'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      website: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}website'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      ),
      postalCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}postal_code'],
      ),
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      ),
      bankAccount: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_account'],
      ),
      iban: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iban'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: $SuppliersTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $SuppliersTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $SuppliersTable createAlias(String alias) {
    return $SuppliersTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Supplier extends DataClass implements Insertable<Supplier> {
  final int id;
  final String uuid;
  final String name;
  final String? vatNumber;
  final String? taxOffice;
  final String? phone;
  final String? mobile;
  final String? email;
  final String? website;
  final String? address;
  final String? city;
  final String? postalCode;
  final String country;
  final String? bankName;
  final String? bankAccount;
  final String? iban;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Supplier({
    required this.id,
    required this.uuid,
    required this.name,
    this.vatNumber,
    this.taxOffice,
    this.phone,
    this.mobile,
    this.email,
    this.website,
    this.address,
    this.city,
    this.postalCode,
    required this.country,
    this.bankName,
    this.bankAccount,
    this.iban,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || vatNumber != null) {
      map['vat_number'] = Variable<String>(vatNumber);
    }
    if (!nullToAbsent || taxOffice != null) {
      map['tax_office'] = Variable<String>(taxOffice);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || website != null) {
      map['website'] = Variable<String>(website);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || city != null) {
      map['city'] = Variable<String>(city);
    }
    if (!nullToAbsent || postalCode != null) {
      map['postal_code'] = Variable<String>(postalCode);
    }
    map['country'] = Variable<String>(country);
    if (!nullToAbsent || bankName != null) {
      map['bank_name'] = Variable<String>(bankName);
    }
    if (!nullToAbsent || bankAccount != null) {
      map['bank_account'] = Variable<String>(bankAccount);
    }
    if (!nullToAbsent || iban != null) {
      map['iban'] = Variable<String>(iban);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    {
      map['created_at'] = Variable<DateTime>(
        $SuppliersTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<DateTime>(
        $SuppliersTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  SuppliersCompanion toCompanion(bool nullToAbsent) {
    return SuppliersCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      vatNumber: vatNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(vatNumber),
      taxOffice: taxOffice == null && nullToAbsent
          ? const Value.absent()
          : Value(taxOffice),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      mobile: mobile == null && nullToAbsent
          ? const Value.absent()
          : Value(mobile),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      website: website == null && nullToAbsent
          ? const Value.absent()
          : Value(website),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      city: city == null && nullToAbsent ? const Value.absent() : Value(city),
      postalCode: postalCode == null && nullToAbsent
          ? const Value.absent()
          : Value(postalCode),
      country: Value(country),
      bankName: bankName == null && nullToAbsent
          ? const Value.absent()
          : Value(bankName),
      bankAccount: bankAccount == null && nullToAbsent
          ? const Value.absent()
          : Value(bankAccount),
      iban: iban == null && nullToAbsent ? const Value.absent() : Value(iban),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Supplier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Supplier(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      vatNumber: serializer.fromJson<String?>(json['vatNumber']),
      taxOffice: serializer.fromJson<String?>(json['taxOffice']),
      phone: serializer.fromJson<String?>(json['phone']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      email: serializer.fromJson<String?>(json['email']),
      website: serializer.fromJson<String?>(json['website']),
      address: serializer.fromJson<String?>(json['address']),
      city: serializer.fromJson<String?>(json['city']),
      postalCode: serializer.fromJson<String?>(json['postalCode']),
      country: serializer.fromJson<String>(json['country']),
      bankName: serializer.fromJson<String?>(json['bankName']),
      bankAccount: serializer.fromJson<String?>(json['bankAccount']),
      iban: serializer.fromJson<String?>(json['iban']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'vatNumber': serializer.toJson<String?>(vatNumber),
      'taxOffice': serializer.toJson<String?>(taxOffice),
      'phone': serializer.toJson<String?>(phone),
      'mobile': serializer.toJson<String?>(mobile),
      'email': serializer.toJson<String?>(email),
      'website': serializer.toJson<String?>(website),
      'address': serializer.toJson<String?>(address),
      'city': serializer.toJson<String?>(city),
      'postalCode': serializer.toJson<String?>(postalCode),
      'country': serializer.toJson<String>(country),
      'bankName': serializer.toJson<String?>(bankName),
      'bankAccount': serializer.toJson<String?>(bankAccount),
      'iban': serializer.toJson<String?>(iban),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Supplier copyWith({
    int? id,
    String? uuid,
    String? name,
    Value<String?> vatNumber = const Value.absent(),
    Value<String?> taxOffice = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> mobile = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> website = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<String?> city = const Value.absent(),
    Value<String?> postalCode = const Value.absent(),
    String? country,
    Value<String?> bankName = const Value.absent(),
    Value<String?> bankAccount = const Value.absent(),
    Value<String?> iban = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Supplier(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    vatNumber: vatNumber.present ? vatNumber.value : this.vatNumber,
    taxOffice: taxOffice.present ? taxOffice.value : this.taxOffice,
    phone: phone.present ? phone.value : this.phone,
    mobile: mobile.present ? mobile.value : this.mobile,
    email: email.present ? email.value : this.email,
    website: website.present ? website.value : this.website,
    address: address.present ? address.value : this.address,
    city: city.present ? city.value : this.city,
    postalCode: postalCode.present ? postalCode.value : this.postalCode,
    country: country ?? this.country,
    bankName: bankName.present ? bankName.value : this.bankName,
    bankAccount: bankAccount.present ? bankAccount.value : this.bankAccount,
    iban: iban.present ? iban.value : this.iban,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Supplier copyWithCompanion(SuppliersCompanion data) {
    return Supplier(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      vatNumber: data.vatNumber.present ? data.vatNumber.value : this.vatNumber,
      taxOffice: data.taxOffice.present ? data.taxOffice.value : this.taxOffice,
      phone: data.phone.present ? data.phone.value : this.phone,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      email: data.email.present ? data.email.value : this.email,
      website: data.website.present ? data.website.value : this.website,
      address: data.address.present ? data.address.value : this.address,
      city: data.city.present ? data.city.value : this.city,
      postalCode: data.postalCode.present
          ? data.postalCode.value
          : this.postalCode,
      country: data.country.present ? data.country.value : this.country,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      bankAccount: data.bankAccount.present
          ? data.bankAccount.value
          : this.bankAccount,
      iban: data.iban.present ? data.iban.value : this.iban,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Supplier(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('vatNumber: $vatNumber, ')
          ..write('taxOffice: $taxOffice, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('postalCode: $postalCode, ')
          ..write('country: $country, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccount: $bankAccount, ')
          ..write('iban: $iban, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    name,
    vatNumber,
    taxOffice,
    phone,
    mobile,
    email,
    website,
    address,
    city,
    postalCode,
    country,
    bankName,
    bankAccount,
    iban,
    notes,
    isActive,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Supplier &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.vatNumber == this.vatNumber &&
          other.taxOffice == this.taxOffice &&
          other.phone == this.phone &&
          other.mobile == this.mobile &&
          other.email == this.email &&
          other.website == this.website &&
          other.address == this.address &&
          other.city == this.city &&
          other.postalCode == this.postalCode &&
          other.country == this.country &&
          other.bankName == this.bankName &&
          other.bankAccount == this.bankAccount &&
          other.iban == this.iban &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SuppliersCompanion extends UpdateCompanion<Supplier> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String?> vatNumber;
  final Value<String?> taxOffice;
  final Value<String?> phone;
  final Value<String?> mobile;
  final Value<String?> email;
  final Value<String?> website;
  final Value<String?> address;
  final Value<String?> city;
  final Value<String?> postalCode;
  final Value<String> country;
  final Value<String?> bankName;
  final Value<String?> bankAccount;
  final Value<String?> iban;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SuppliersCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.vatNumber = const Value.absent(),
    this.taxOffice = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.postalCode = const Value.absent(),
    this.country = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccount = const Value.absent(),
    this.iban = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SuppliersCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    this.vatNumber = const Value.absent(),
    this.taxOffice = const Value.absent(),
    this.phone = const Value.absent(),
    this.mobile = const Value.absent(),
    this.email = const Value.absent(),
    this.website = const Value.absent(),
    this.address = const Value.absent(),
    this.city = const Value.absent(),
    this.postalCode = const Value.absent(),
    this.country = const Value.absent(),
    this.bankName = const Value.absent(),
    this.bankAccount = const Value.absent(),
    this.iban = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Supplier> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? vatNumber,
    Expression<String>? taxOffice,
    Expression<String>? phone,
    Expression<String>? mobile,
    Expression<String>? email,
    Expression<String>? website,
    Expression<String>? address,
    Expression<String>? city,
    Expression<String>? postalCode,
    Expression<String>? country,
    Expression<String>? bankName,
    Expression<String>? bankAccount,
    Expression<String>? iban,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (vatNumber != null) 'vat_number': vatNumber,
      if (taxOffice != null) 'tax_office': taxOffice,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      if (country != null) 'country': country,
      if (bankName != null) 'bank_name': bankName,
      if (bankAccount != null) 'bank_account': bankAccount,
      if (iban != null) 'iban': iban,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SuppliersCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<String?>? vatNumber,
    Value<String?>? taxOffice,
    Value<String?>? phone,
    Value<String?>? mobile,
    Value<String?>? email,
    Value<String?>? website,
    Value<String?>? address,
    Value<String?>? city,
    Value<String?>? postalCode,
    Value<String>? country,
    Value<String?>? bankName,
    Value<String?>? bankAccount,
    Value<String?>? iban,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return SuppliersCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      vatNumber: vatNumber ?? this.vatNumber,
      taxOffice: taxOffice ?? this.taxOffice,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      iban: iban ?? this.iban,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (vatNumber.present) {
      map['vat_number'] = Variable<String>(vatNumber.value);
    }
    if (taxOffice.present) {
      map['tax_office'] = Variable<String>(taxOffice.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (website.present) {
      map['website'] = Variable<String>(website.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (postalCode.present) {
      map['postal_code'] = Variable<String>(postalCode.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (bankAccount.present) {
      map['bank_account'] = Variable<String>(bankAccount.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $SuppliersTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $SuppliersTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('vatNumber: $vatNumber, ')
          ..write('taxOffice: $taxOffice, ')
          ..write('phone: $phone, ')
          ..write('mobile: $mobile, ')
          ..write('email: $email, ')
          ..write('website: $website, ')
          ..write('address: $address, ')
          ..write('city: $city, ')
          ..write('postalCode: $postalCode, ')
          ..write('country: $country, ')
          ..write('bankName: $bankName, ')
          ..write('bankAccount: $bankAccount, ')
          ..write('iban: $iban, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, Item> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('τεμ'),
  );
  static const VerificationMeta _unitWeightMeta = const VerificationMeta(
    'unitWeight',
  );
  @override
  late final GeneratedColumn<double> unitWeight = GeneratedColumn<double>(
    'unit_weight',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _minStockMeta = const VerificationMeta(
    'minStock',
  );
  @override
  late final GeneratedColumn<double> minStock = GeneratedColumn<double>(
    'min_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxStockMeta = const VerificationMeta(
    'maxStock',
  );
  @override
  late final GeneratedColumn<double> maxStock = GeneratedColumn<double>(
    'max_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentStockMeta = const VerificationMeta(
    'currentStock',
  );
  @override
  late final GeneratedColumn<double> currentStock = GeneratedColumn<double>(
    'current_stock',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reorderLevelMeta = const VerificationMeta(
    'reorderLevel',
  );
  @override
  late final GeneratedColumn<double> reorderLevel = GeneratedColumn<double>(
    'reorder_level',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastPriceMeta = const VerificationMeta(
    'lastPrice',
  );
  @override
  late final GeneratedColumn<double> lastPrice = GeneratedColumn<double>(
    'last_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSupplierIdMeta = const VerificationMeta(
    'lastSupplierId',
  );
  @override
  late final GeneratedColumn<int> lastSupplierId = GeneratedColumn<int>(
    'last_supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suppliers (id)',
    ),
  );
  static const VerificationMeta _preferredSupplierIdMeta =
      const VerificationMeta('preferredSupplierId');
  @override
  late final GeneratedColumn<int> preferredSupplierId = GeneratedColumn<int>(
    'preferred_supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suppliers (id)',
    ),
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
  static const VerificationMeta _isTaxableMeta = const VerificationMeta(
    'isTaxable',
  );
  @override
  late final GeneratedColumn<bool> isTaxable = GeneratedColumn<bool>(
    'is_taxable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_taxable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _defaultVatRateMeta = const VerificationMeta(
    'defaultVatRate',
  );
  @override
  late final GeneratedColumn<double> defaultVatRate = GeneratedColumn<double>(
    'default_vat_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(24.0),
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
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ItemsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ItemsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    name,
    categoryId,
    barcode,
    sku,
    unit,
    unitWeight,
    minStock,
    maxStock,
    currentStock,
    reorderLevel,
    lastPrice,
    lastSupplierId,
    preferredSupplierId,
    notes,
    isTaxable,
    defaultVatRate,
    isActive,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<Item> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('unit_weight')) {
      context.handle(
        _unitWeightMeta,
        unitWeight.isAcceptableOrUnknown(data['unit_weight']!, _unitWeightMeta),
      );
    }
    if (data.containsKey('min_stock')) {
      context.handle(
        _minStockMeta,
        minStock.isAcceptableOrUnknown(data['min_stock']!, _minStockMeta),
      );
    }
    if (data.containsKey('max_stock')) {
      context.handle(
        _maxStockMeta,
        maxStock.isAcceptableOrUnknown(data['max_stock']!, _maxStockMeta),
      );
    }
    if (data.containsKey('current_stock')) {
      context.handle(
        _currentStockMeta,
        currentStock.isAcceptableOrUnknown(
          data['current_stock']!,
          _currentStockMeta,
        ),
      );
    }
    if (data.containsKey('reorder_level')) {
      context.handle(
        _reorderLevelMeta,
        reorderLevel.isAcceptableOrUnknown(
          data['reorder_level']!,
          _reorderLevelMeta,
        ),
      );
    }
    if (data.containsKey('last_price')) {
      context.handle(
        _lastPriceMeta,
        lastPrice.isAcceptableOrUnknown(data['last_price']!, _lastPriceMeta),
      );
    }
    if (data.containsKey('last_supplier_id')) {
      context.handle(
        _lastSupplierIdMeta,
        lastSupplierId.isAcceptableOrUnknown(
          data['last_supplier_id']!,
          _lastSupplierIdMeta,
        ),
      );
    }
    if (data.containsKey('preferred_supplier_id')) {
      context.handle(
        _preferredSupplierIdMeta,
        preferredSupplierId.isAcceptableOrUnknown(
          data['preferred_supplier_id']!,
          _preferredSupplierIdMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_taxable')) {
      context.handle(
        _isTaxableMeta,
        isTaxable.isAcceptableOrUnknown(data['is_taxable']!, _isTaxableMeta),
      );
    }
    if (data.containsKey('default_vat_rate')) {
      context.handle(
        _defaultVatRateMeta,
        defaultVatRate.isAcceptableOrUnknown(
          data['default_vat_rate']!,
          _defaultVatRateMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {name, categoryId},
  ];
  @override
  Item map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Item(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_weight'],
      ),
      minStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_stock'],
      )!,
      maxStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}max_stock'],
      )!,
      currentStock: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_stock'],
      )!,
      reorderLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}reorder_level'],
      )!,
      lastPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}last_price'],
      ),
      lastSupplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_supplier_id'],
      ),
      preferredSupplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preferred_supplier_id'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isTaxable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_taxable'],
      )!,
      defaultVatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_vat_rate'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAt: $ItemsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ItemsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Item extends DataClass implements Insertable<Item> {
  final int id;
  final String uuid;
  final String name;
  final int categoryId;
  final String? barcode;
  final String? sku;
  final String unit;
  final double? unitWeight;
  final double minStock;
  final double maxStock;
  final double currentStock;
  final double reorderLevel;
  final double? lastPrice;
  final int? lastSupplierId;
  final int? preferredSupplierId;
  final String? notes;
  final bool isTaxable;
  final double defaultVatRate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Item({
    required this.id,
    required this.uuid,
    required this.name,
    required this.categoryId,
    this.barcode,
    this.sku,
    required this.unit,
    this.unitWeight,
    required this.minStock,
    required this.maxStock,
    required this.currentStock,
    required this.reorderLevel,
    this.lastPrice,
    this.lastSupplierId,
    this.preferredSupplierId,
    this.notes,
    required this.isTaxable,
    required this.defaultVatRate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    map['category_id'] = Variable<int>(categoryId);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || unitWeight != null) {
      map['unit_weight'] = Variable<double>(unitWeight);
    }
    map['min_stock'] = Variable<double>(minStock);
    map['max_stock'] = Variable<double>(maxStock);
    map['current_stock'] = Variable<double>(currentStock);
    map['reorder_level'] = Variable<double>(reorderLevel);
    if (!nullToAbsent || lastPrice != null) {
      map['last_price'] = Variable<double>(lastPrice);
    }
    if (!nullToAbsent || lastSupplierId != null) {
      map['last_supplier_id'] = Variable<int>(lastSupplierId);
    }
    if (!nullToAbsent || preferredSupplierId != null) {
      map['preferred_supplier_id'] = Variable<int>(preferredSupplierId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_taxable'] = Variable<bool>(isTaxable);
    map['default_vat_rate'] = Variable<double>(defaultVatRate);
    map['is_active'] = Variable<bool>(isActive);
    {
      map['created_at'] = Variable<DateTime>(
        $ItemsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<DateTime>(
        $ItemsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      categoryId: Value(categoryId),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      unit: Value(unit),
      unitWeight: unitWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(unitWeight),
      minStock: Value(minStock),
      maxStock: Value(maxStock),
      currentStock: Value(currentStock),
      reorderLevel: Value(reorderLevel),
      lastPrice: lastPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPrice),
      lastSupplierId: lastSupplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSupplierId),
      preferredSupplierId: preferredSupplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSupplierId),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isTaxable: Value(isTaxable),
      defaultVatRate: Value(defaultVatRate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Item.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Item(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      sku: serializer.fromJson<String?>(json['sku']),
      unit: serializer.fromJson<String>(json['unit']),
      unitWeight: serializer.fromJson<double?>(json['unitWeight']),
      minStock: serializer.fromJson<double>(json['minStock']),
      maxStock: serializer.fromJson<double>(json['maxStock']),
      currentStock: serializer.fromJson<double>(json['currentStock']),
      reorderLevel: serializer.fromJson<double>(json['reorderLevel']),
      lastPrice: serializer.fromJson<double?>(json['lastPrice']),
      lastSupplierId: serializer.fromJson<int?>(json['lastSupplierId']),
      preferredSupplierId: serializer.fromJson<int?>(
        json['preferredSupplierId'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
      isTaxable: serializer.fromJson<bool>(json['isTaxable']),
      defaultVatRate: serializer.fromJson<double>(json['defaultVatRate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'categoryId': serializer.toJson<int>(categoryId),
      'barcode': serializer.toJson<String?>(barcode),
      'sku': serializer.toJson<String?>(sku),
      'unit': serializer.toJson<String>(unit),
      'unitWeight': serializer.toJson<double?>(unitWeight),
      'minStock': serializer.toJson<double>(minStock),
      'maxStock': serializer.toJson<double>(maxStock),
      'currentStock': serializer.toJson<double>(currentStock),
      'reorderLevel': serializer.toJson<double>(reorderLevel),
      'lastPrice': serializer.toJson<double?>(lastPrice),
      'lastSupplierId': serializer.toJson<int?>(lastSupplierId),
      'preferredSupplierId': serializer.toJson<int?>(preferredSupplierId),
      'notes': serializer.toJson<String?>(notes),
      'isTaxable': serializer.toJson<bool>(isTaxable),
      'defaultVatRate': serializer.toJson<double>(defaultVatRate),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Item copyWith({
    int? id,
    String? uuid,
    String? name,
    int? categoryId,
    Value<String?> barcode = const Value.absent(),
    Value<String?> sku = const Value.absent(),
    String? unit,
    Value<double?> unitWeight = const Value.absent(),
    double? minStock,
    double? maxStock,
    double? currentStock,
    double? reorderLevel,
    Value<double?> lastPrice = const Value.absent(),
    Value<int?> lastSupplierId = const Value.absent(),
    Value<int?> preferredSupplierId = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isTaxable,
    double? defaultVatRate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Item(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    categoryId: categoryId ?? this.categoryId,
    barcode: barcode.present ? barcode.value : this.barcode,
    sku: sku.present ? sku.value : this.sku,
    unit: unit ?? this.unit,
    unitWeight: unitWeight.present ? unitWeight.value : this.unitWeight,
    minStock: minStock ?? this.minStock,
    maxStock: maxStock ?? this.maxStock,
    currentStock: currentStock ?? this.currentStock,
    reorderLevel: reorderLevel ?? this.reorderLevel,
    lastPrice: lastPrice.present ? lastPrice.value : this.lastPrice,
    lastSupplierId: lastSupplierId.present
        ? lastSupplierId.value
        : this.lastSupplierId,
    preferredSupplierId: preferredSupplierId.present
        ? preferredSupplierId.value
        : this.preferredSupplierId,
    notes: notes.present ? notes.value : this.notes,
    isTaxable: isTaxable ?? this.isTaxable,
    defaultVatRate: defaultVatRate ?? this.defaultVatRate,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Item copyWithCompanion(ItemsCompanion data) {
    return Item(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      sku: data.sku.present ? data.sku.value : this.sku,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitWeight: data.unitWeight.present
          ? data.unitWeight.value
          : this.unitWeight,
      minStock: data.minStock.present ? data.minStock.value : this.minStock,
      maxStock: data.maxStock.present ? data.maxStock.value : this.maxStock,
      currentStock: data.currentStock.present
          ? data.currentStock.value
          : this.currentStock,
      reorderLevel: data.reorderLevel.present
          ? data.reorderLevel.value
          : this.reorderLevel,
      lastPrice: data.lastPrice.present ? data.lastPrice.value : this.lastPrice,
      lastSupplierId: data.lastSupplierId.present
          ? data.lastSupplierId.value
          : this.lastSupplierId,
      preferredSupplierId: data.preferredSupplierId.present
          ? data.preferredSupplierId.value
          : this.preferredSupplierId,
      notes: data.notes.present ? data.notes.value : this.notes,
      isTaxable: data.isTaxable.present ? data.isTaxable.value : this.isTaxable,
      defaultVatRate: data.defaultVatRate.present
          ? data.defaultVatRate.value
          : this.defaultVatRate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Item(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('barcode: $barcode, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('unitWeight: $unitWeight, ')
          ..write('minStock: $minStock, ')
          ..write('maxStock: $maxStock, ')
          ..write('currentStock: $currentStock, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('lastPrice: $lastPrice, ')
          ..write('lastSupplierId: $lastSupplierId, ')
          ..write('preferredSupplierId: $preferredSupplierId, ')
          ..write('notes: $notes, ')
          ..write('isTaxable: $isTaxable, ')
          ..write('defaultVatRate: $defaultVatRate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    uuid,
    name,
    categoryId,
    barcode,
    sku,
    unit,
    unitWeight,
    minStock,
    maxStock,
    currentStock,
    reorderLevel,
    lastPrice,
    lastSupplierId,
    preferredSupplierId,
    notes,
    isTaxable,
    defaultVatRate,
    isActive,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Item &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.categoryId == this.categoryId &&
          other.barcode == this.barcode &&
          other.sku == this.sku &&
          other.unit == this.unit &&
          other.unitWeight == this.unitWeight &&
          other.minStock == this.minStock &&
          other.maxStock == this.maxStock &&
          other.currentStock == this.currentStock &&
          other.reorderLevel == this.reorderLevel &&
          other.lastPrice == this.lastPrice &&
          other.lastSupplierId == this.lastSupplierId &&
          other.preferredSupplierId == this.preferredSupplierId &&
          other.notes == this.notes &&
          other.isTaxable == this.isTaxable &&
          other.defaultVatRate == this.defaultVatRate &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ItemsCompanion extends UpdateCompanion<Item> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<int> categoryId;
  final Value<String?> barcode;
  final Value<String?> sku;
  final Value<String> unit;
  final Value<double?> unitWeight;
  final Value<double> minStock;
  final Value<double> maxStock;
  final Value<double> currentStock;
  final Value<double> reorderLevel;
  final Value<double?> lastPrice;
  final Value<int?> lastSupplierId;
  final Value<int?> preferredSupplierId;
  final Value<String?> notes;
  final Value<bool> isTaxable;
  final Value<double> defaultVatRate;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitWeight = const Value.absent(),
    this.minStock = const Value.absent(),
    this.maxStock = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.lastPrice = const Value.absent(),
    this.lastSupplierId = const Value.absent(),
    this.preferredSupplierId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isTaxable = const Value.absent(),
    this.defaultVatRate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    required int categoryId,
    this.barcode = const Value.absent(),
    this.sku = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitWeight = const Value.absent(),
    this.minStock = const Value.absent(),
    this.maxStock = const Value.absent(),
    this.currentStock = const Value.absent(),
    this.reorderLevel = const Value.absent(),
    this.lastPrice = const Value.absent(),
    this.lastSupplierId = const Value.absent(),
    this.preferredSupplierId = const Value.absent(),
    this.notes = const Value.absent(),
    this.isTaxable = const Value.absent(),
    this.defaultVatRate = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : name = Value(name),
       categoryId = Value(categoryId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Item> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<int>? categoryId,
    Expression<String>? barcode,
    Expression<String>? sku,
    Expression<String>? unit,
    Expression<double>? unitWeight,
    Expression<double>? minStock,
    Expression<double>? maxStock,
    Expression<double>? currentStock,
    Expression<double>? reorderLevel,
    Expression<double>? lastPrice,
    Expression<int>? lastSupplierId,
    Expression<int>? preferredSupplierId,
    Expression<String>? notes,
    Expression<bool>? isTaxable,
    Expression<double>? defaultVatRate,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (barcode != null) 'barcode': barcode,
      if (sku != null) 'sku': sku,
      if (unit != null) 'unit': unit,
      if (unitWeight != null) 'unit_weight': unitWeight,
      if (minStock != null) 'min_stock': minStock,
      if (maxStock != null) 'max_stock': maxStock,
      if (currentStock != null) 'current_stock': currentStock,
      if (reorderLevel != null) 'reorder_level': reorderLevel,
      if (lastPrice != null) 'last_price': lastPrice,
      if (lastSupplierId != null) 'last_supplier_id': lastSupplierId,
      if (preferredSupplierId != null)
        'preferred_supplier_id': preferredSupplierId,
      if (notes != null) 'notes': notes,
      if (isTaxable != null) 'is_taxable': isTaxable,
      if (defaultVatRate != null) 'default_vat_rate': defaultVatRate,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<int>? categoryId,
    Value<String?>? barcode,
    Value<String?>? sku,
    Value<String>? unit,
    Value<double?>? unitWeight,
    Value<double>? minStock,
    Value<double>? maxStock,
    Value<double>? currentStock,
    Value<double>? reorderLevel,
    Value<double?>? lastPrice,
    Value<int?>? lastSupplierId,
    Value<int?>? preferredSupplierId,
    Value<String?>? notes,
    Value<bool>? isTaxable,
    Value<double>? defaultVatRate,
    Value<bool>? isActive,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      unit: unit ?? this.unit,
      unitWeight: unitWeight ?? this.unitWeight,
      minStock: minStock ?? this.minStock,
      maxStock: maxStock ?? this.maxStock,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      lastPrice: lastPrice ?? this.lastPrice,
      lastSupplierId: lastSupplierId ?? this.lastSupplierId,
      preferredSupplierId: preferredSupplierId ?? this.preferredSupplierId,
      notes: notes ?? this.notes,
      isTaxable: isTaxable ?? this.isTaxable,
      defaultVatRate: defaultVatRate ?? this.defaultVatRate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitWeight.present) {
      map['unit_weight'] = Variable<double>(unitWeight.value);
    }
    if (minStock.present) {
      map['min_stock'] = Variable<double>(minStock.value);
    }
    if (maxStock.present) {
      map['max_stock'] = Variable<double>(maxStock.value);
    }
    if (currentStock.present) {
      map['current_stock'] = Variable<double>(currentStock.value);
    }
    if (reorderLevel.present) {
      map['reorder_level'] = Variable<double>(reorderLevel.value);
    }
    if (lastPrice.present) {
      map['last_price'] = Variable<double>(lastPrice.value);
    }
    if (lastSupplierId.present) {
      map['last_supplier_id'] = Variable<int>(lastSupplierId.value);
    }
    if (preferredSupplierId.present) {
      map['preferred_supplier_id'] = Variable<int>(preferredSupplierId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isTaxable.present) {
      map['is_taxable'] = Variable<bool>(isTaxable.value);
    }
    if (defaultVatRate.present) {
      map['default_vat_rate'] = Variable<double>(defaultVatRate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $ItemsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $ItemsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('categoryId: $categoryId, ')
          ..write('barcode: $barcode, ')
          ..write('sku: $sku, ')
          ..write('unit: $unit, ')
          ..write('unitWeight: $unitWeight, ')
          ..write('minStock: $minStock, ')
          ..write('maxStock: $maxStock, ')
          ..write('currentStock: $currentStock, ')
          ..write('reorderLevel: $reorderLevel, ')
          ..write('lastPrice: $lastPrice, ')
          ..write('lastSupplierId: $lastSupplierId, ')
          ..write('preferredSupplierId: $preferredSupplierId, ')
          ..write('notes: $notes, ')
          ..write('isTaxable: $isTaxable, ')
          ..write('defaultVatRate: $defaultVatRate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _receiptNumberMeta = const VerificationMeta(
    'receiptNumber',
  );
  @override
  late final GeneratedColumn<int> receiptNumber = GeneratedColumn<int>(
    'receipt_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> receiptDate =
      GeneratedColumn<DateTime>(
        'receipt_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReceiptsTable.$converterreceiptDate);
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<int> supplierId = GeneratedColumn<int>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suppliers (id)',
    ),
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceSeriesMeta = const VerificationMeta(
    'invoiceSeries',
  );
  @override
  late final GeneratedColumn<String> invoiceSeries = GeneratedColumn<String>(
    'invoice_series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vatTotalMeta = const VerificationMeta(
    'vatTotal',
  );
  @override
  late final GeneratedColumn<double> vatTotal = GeneratedColumn<double>(
    'vat_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountTotalMeta = const VerificationMeta(
    'discountTotal',
  );
  @override
  late final GeneratedColumn<double> discountTotal = GeneratedColumn<double>(
    'discount_total',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paidAmountMeta = const VerificationMeta(
    'paidAmount',
  );
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
    'paid_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _remainingAmountMeta = const VerificationMeta(
    'remainingAmount',
  );
  @override
  late final GeneratedColumn<double> remainingAmount = GeneratedColumn<double>(
    'remaining_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
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
    defaultValue: const Constant('pending'),
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
  static const VerificationMeta _attachmentPathMeta = const VerificationMeta(
    'attachmentPath',
  );
  @override
  late final GeneratedColumn<String> attachmentPath = GeneratedColumn<String>(
    'attachment_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSyncedMeta = const VerificationMeta(
    'isSynced',
  );
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
    'is_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReceiptsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReceiptsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    receiptNumber,
    receiptDate,
    supplierId,
    invoiceNumber,
    invoiceSeries,
    paymentMethod,
    totalAmount,
    vatTotal,
    discountTotal,
    paidAmount,
    remainingAmount,
    paymentStatus,
    notes,
    attachmentPath,
    isSynced,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
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
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierIdMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('invoice_series')) {
      context.handle(
        _invoiceSeriesMeta,
        invoiceSeries.isAcceptableOrUnknown(
          data['invoice_series']!,
          _invoiceSeriesMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    }
    if (data.containsKey('vat_total')) {
      context.handle(
        _vatTotalMeta,
        vatTotal.isAcceptableOrUnknown(data['vat_total']!, _vatTotalMeta),
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
    if (data.containsKey('paid_amount')) {
      context.handle(
        _paidAmountMeta,
        paidAmount.isAcceptableOrUnknown(data['paid_amount']!, _paidAmountMeta),
      );
    }
    if (data.containsKey('remaining_amount')) {
      context.handle(
        _remainingAmountMeta,
        remainingAmount.isAcceptableOrUnknown(
          data['remaining_amount']!,
          _remainingAmountMeta,
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
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('attachment_path')) {
      context.handle(
        _attachmentPathMeta,
        attachmentPath.isAcceptableOrUnknown(
          data['attachment_path']!,
          _attachmentPathMeta,
        ),
      );
    }
    if (data.containsKey('is_synced')) {
      context.handle(
        _isSyncedMeta,
        isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      receiptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_number'],
      )!,
      receiptDate: $ReceiptsTable.$converterreceiptDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}receipt_date'],
        )!,
      ),
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}supplier_id'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      ),
      invoiceSeries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_series'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      vatTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_total'],
      )!,
      discountTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount_total'],
      )!,
      paidAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}paid_amount'],
      )!,
      remainingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}remaining_amount'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      attachmentPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_path'],
      ),
      isSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_synced'],
      )!,
      createdAt: $ReceiptsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $ReceiptsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterreceiptDate =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final int id;
  final String uuid;
  final int receiptNumber;
  final DateTime receiptDate;
  final int supplierId;
  final String? invoiceNumber;
  final String? invoiceSeries;
  final String? paymentMethod;
  final double totalAmount;
  final double vatTotal;
  final double discountTotal;
  final double paidAmount;
  final double remainingAmount;
  final String paymentStatus;
  final String? notes;
  final String? attachmentPath;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Receipt({
    required this.id,
    required this.uuid,
    required this.receiptNumber,
    required this.receiptDate,
    required this.supplierId,
    this.invoiceNumber,
    this.invoiceSeries,
    this.paymentMethod,
    required this.totalAmount,
    required this.vatTotal,
    required this.discountTotal,
    required this.paidAmount,
    required this.remainingAmount,
    required this.paymentStatus,
    this.notes,
    this.attachmentPath,
    required this.isSynced,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['receipt_number'] = Variable<int>(receiptNumber);
    {
      map['receipt_date'] = Variable<DateTime>(
        $ReceiptsTable.$converterreceiptDate.toSql(receiptDate),
      );
    }
    map['supplier_id'] = Variable<int>(supplierId);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || invoiceSeries != null) {
      map['invoice_series'] = Variable<String>(invoiceSeries);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['total_amount'] = Variable<double>(totalAmount);
    map['vat_total'] = Variable<double>(vatTotal);
    map['discount_total'] = Variable<double>(discountTotal);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['remaining_amount'] = Variable<double>(remainingAmount);
    map['payment_status'] = Variable<String>(paymentStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || attachmentPath != null) {
      map['attachment_path'] = Variable<String>(attachmentPath);
    }
    map['is_synced'] = Variable<bool>(isSynced);
    {
      map['created_at'] = Variable<DateTime>(
        $ReceiptsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<DateTime>(
        $ReceiptsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      receiptNumber: Value(receiptNumber),
      receiptDate: Value(receiptDate),
      supplierId: Value(supplierId),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      invoiceSeries: invoiceSeries == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceSeries),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      totalAmount: Value(totalAmount),
      vatTotal: Value(vatTotal),
      discountTotal: Value(discountTotal),
      paidAmount: Value(paidAmount),
      remainingAmount: Value(remainingAmount),
      paymentStatus: Value(paymentStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      attachmentPath: attachmentPath == null && nullToAbsent
          ? const Value.absent()
          : Value(attachmentPath),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      receiptNumber: serializer.fromJson<int>(json['receiptNumber']),
      receiptDate: serializer.fromJson<DateTime>(json['receiptDate']),
      supplierId: serializer.fromJson<int>(json['supplierId']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      invoiceSeries: serializer.fromJson<String?>(json['invoiceSeries']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      vatTotal: serializer.fromJson<double>(json['vatTotal']),
      discountTotal: serializer.fromJson<double>(json['discountTotal']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      remainingAmount: serializer.fromJson<double>(json['remainingAmount']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      attachmentPath: serializer.fromJson<String?>(json['attachmentPath']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'receiptNumber': serializer.toJson<int>(receiptNumber),
      'receiptDate': serializer.toJson<DateTime>(receiptDate),
      'supplierId': serializer.toJson<int>(supplierId),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'invoiceSeries': serializer.toJson<String?>(invoiceSeries),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'vatTotal': serializer.toJson<double>(vatTotal),
      'discountTotal': serializer.toJson<double>(discountTotal),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'remainingAmount': serializer.toJson<double>(remainingAmount),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'notes': serializer.toJson<String?>(notes),
      'attachmentPath': serializer.toJson<String?>(attachmentPath),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Receipt copyWith({
    int? id,
    String? uuid,
    int? receiptNumber,
    DateTime? receiptDate,
    int? supplierId,
    Value<String?> invoiceNumber = const Value.absent(),
    Value<String?> invoiceSeries = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    double? totalAmount,
    double? vatTotal,
    double? discountTotal,
    double? paidAmount,
    double? remainingAmount,
    String? paymentStatus,
    Value<String?> notes = const Value.absent(),
    Value<String?> attachmentPath = const Value.absent(),
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Receipt(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    receiptNumber: receiptNumber ?? this.receiptNumber,
    receiptDate: receiptDate ?? this.receiptDate,
    supplierId: supplierId ?? this.supplierId,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    invoiceSeries: invoiceSeries.present
        ? invoiceSeries.value
        : this.invoiceSeries,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    totalAmount: totalAmount ?? this.totalAmount,
    vatTotal: vatTotal ?? this.vatTotal,
    discountTotal: discountTotal ?? this.discountTotal,
    paidAmount: paidAmount ?? this.paidAmount,
    remainingAmount: remainingAmount ?? this.remainingAmount,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    notes: notes.present ? notes.value : this.notes,
    attachmentPath: attachmentPath.present
        ? attachmentPath.value
        : this.attachmentPath,
    isSynced: isSynced ?? this.isSynced,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      receiptNumber: data.receiptNumber.present
          ? data.receiptNumber.value
          : this.receiptNumber,
      receiptDate: data.receiptDate.present
          ? data.receiptDate.value
          : this.receiptDate,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      invoiceSeries: data.invoiceSeries.present
          ? data.invoiceSeries.value
          : this.invoiceSeries,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      vatTotal: data.vatTotal.present ? data.vatTotal.value : this.vatTotal,
      discountTotal: data.discountTotal.present
          ? data.discountTotal.value
          : this.discountTotal,
      paidAmount: data.paidAmount.present
          ? data.paidAmount.value
          : this.paidAmount,
      remainingAmount: data.remainingAmount.present
          ? data.remainingAmount.value
          : this.remainingAmount,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      attachmentPath: data.attachmentPath.present
          ? data.attachmentPath.value
          : this.attachmentPath,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('supplierId: $supplierId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceSeries: $invoiceSeries, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('vatTotal: $vatTotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    receiptNumber,
    receiptDate,
    supplierId,
    invoiceNumber,
    invoiceSeries,
    paymentMethod,
    totalAmount,
    vatTotal,
    discountTotal,
    paidAmount,
    remainingAmount,
    paymentStatus,
    notes,
    attachmentPath,
    isSynced,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.receiptNumber == this.receiptNumber &&
          other.receiptDate == this.receiptDate &&
          other.supplierId == this.supplierId &&
          other.invoiceNumber == this.invoiceNumber &&
          other.invoiceSeries == this.invoiceSeries &&
          other.paymentMethod == this.paymentMethod &&
          other.totalAmount == this.totalAmount &&
          other.vatTotal == this.vatTotal &&
          other.discountTotal == this.discountTotal &&
          other.paidAmount == this.paidAmount &&
          other.remainingAmount == this.remainingAmount &&
          other.paymentStatus == this.paymentStatus &&
          other.notes == this.notes &&
          other.attachmentPath == this.attachmentPath &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> receiptNumber;
  final Value<DateTime> receiptDate;
  final Value<int> supplierId;
  final Value<String?> invoiceNumber;
  final Value<String?> invoiceSeries;
  final Value<String?> paymentMethod;
  final Value<double> totalAmount;
  final Value<double> vatTotal;
  final Value<double> discountTotal;
  final Value<double> paidAmount;
  final Value<double> remainingAmount;
  final Value<String> paymentStatus;
  final Value<String?> notes;
  final Value<String?> attachmentPath;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const ReceiptsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.receiptNumber = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.invoiceSeries = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.vatTotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int receiptNumber,
    required DateTime receiptDate,
    required int supplierId,
    this.invoiceNumber = const Value.absent(),
    this.invoiceSeries = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.vatTotal = const Value.absent(),
    this.discountTotal = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.remainingAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.attachmentPath = const Value.absent(),
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : receiptNumber = Value(receiptNumber),
       receiptDate = Value(receiptDate),
       supplierId = Value(supplierId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Receipt> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? receiptNumber,
    Expression<DateTime>? receiptDate,
    Expression<int>? supplierId,
    Expression<String>? invoiceNumber,
    Expression<String>? invoiceSeries,
    Expression<String>? paymentMethod,
    Expression<double>? totalAmount,
    Expression<double>? vatTotal,
    Expression<double>? discountTotal,
    Expression<double>? paidAmount,
    Expression<double>? remainingAmount,
    Expression<String>? paymentStatus,
    Expression<String>? notes,
    Expression<String>? attachmentPath,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (receiptNumber != null) 'receipt_number': receiptNumber,
      if (receiptDate != null) 'receipt_date': receiptDate,
      if (supplierId != null) 'supplier_id': supplierId,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (invoiceSeries != null) 'invoice_series': invoiceSeries,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (vatTotal != null) 'vat_total': vatTotal,
      if (discountTotal != null) 'discount_total': discountTotal,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (remainingAmount != null) 'remaining_amount': remainingAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (notes != null) 'notes': notes,
      if (attachmentPath != null) 'attachment_path': attachmentPath,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ReceiptsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? receiptNumber,
    Value<DateTime>? receiptDate,
    Value<int>? supplierId,
    Value<String?>? invoiceNumber,
    Value<String?>? invoiceSeries,
    Value<String?>? paymentMethod,
    Value<double>? totalAmount,
    Value<double>? vatTotal,
    Value<double>? discountTotal,
    Value<double>? paidAmount,
    Value<double>? remainingAmount,
    Value<String>? paymentStatus,
    Value<String?>? notes,
    Value<String?>? attachmentPath,
    Value<bool>? isSynced,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return ReceiptsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      receiptDate: receiptDate ?? this.receiptDate,
      supplierId: supplierId ?? this.supplierId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceSeries: invoiceSeries ?? this.invoiceSeries,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      totalAmount: totalAmount ?? this.totalAmount,
      vatTotal: vatTotal ?? this.vatTotal,
      discountTotal: discountTotal ?? this.discountTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (receiptNumber.present) {
      map['receipt_number'] = Variable<int>(receiptNumber.value);
    }
    if (receiptDate.present) {
      map['receipt_date'] = Variable<DateTime>(
        $ReceiptsTable.$converterreceiptDate.toSql(receiptDate.value),
      );
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<int>(supplierId.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (invoiceSeries.present) {
      map['invoice_series'] = Variable<String>(invoiceSeries.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (vatTotal.present) {
      map['vat_total'] = Variable<double>(vatTotal.value);
    }
    if (discountTotal.present) {
      map['discount_total'] = Variable<double>(discountTotal.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (remainingAmount.present) {
      map['remaining_amount'] = Variable<double>(remainingAmount.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (attachmentPath.present) {
      map['attachment_path'] = Variable<String>(attachmentPath.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $ReceiptsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $ReceiptsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptNumber: $receiptNumber, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('supplierId: $supplierId, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('invoiceSeries: $invoiceSeries, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('vatTotal: $vatTotal, ')
          ..write('discountTotal: $discountTotal, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('remainingAmount: $remainingAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('notes: $notes, ')
          ..write('attachmentPath: $attachmentPath, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $ReceiptItemsTable extends ReceiptItems
    with TableInfo<$ReceiptItemsTable, ReceiptItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptItemsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id)',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatRateMeta = const VerificationMeta(
    'vatRate',
  );
  @override
  late final GeneratedColumn<double> vatRate = GeneratedColumn<double>(
    'vat_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(24.0),
  );
  static const VerificationMeta _vatAmountMeta = const VerificationMeta(
    'vatAmount',
  );
  @override
  late final GeneratedColumn<double> vatAmount = GeneratedColumn<double>(
    'vat_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _discountMeta = const VerificationMeta(
    'discount',
  );
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
    'discount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalPriceMeta = const VerificationMeta(
    'totalPrice',
  );
  @override
  late final GeneratedColumn<double> totalPrice = GeneratedColumn<double>(
    'total_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalWithVatMeta = const VerificationMeta(
    'totalWithVat',
  );
  @override
  late final GeneratedColumn<double> totalWithVat = GeneratedColumn<double>(
    'total_with_vat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReceiptItemsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    receiptId,
    itemId,
    quantity,
    unitPrice,
    vatRate,
    vatAmount,
    discount,
    totalPrice,
    totalWithVat,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
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
    if (data.containsKey('vat_rate')) {
      context.handle(
        _vatRateMeta,
        vatRate.isAcceptableOrUnknown(data['vat_rate']!, _vatRateMeta),
      );
    }
    if (data.containsKey('vat_amount')) {
      context.handle(
        _vatAmountMeta,
        vatAmount.isAcceptableOrUnknown(data['vat_amount']!, _vatAmountMeta),
      );
    }
    if (data.containsKey('discount')) {
      context.handle(
        _discountMeta,
        discount.isAcceptableOrUnknown(data['discount']!, _discountMeta),
      );
    }
    if (data.containsKey('total_price')) {
      context.handle(
        _totalPriceMeta,
        totalPrice.isAcceptableOrUnknown(data['total_price']!, _totalPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_totalPriceMeta);
    }
    if (data.containsKey('total_with_vat')) {
      context.handle(
        _totalWithVatMeta,
        totalWithVat.isAcceptableOrUnknown(
          data['total_with_vat']!,
          _totalWithVatMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalWithVatMeta);
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
  ReceiptItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      vatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_rate'],
      )!,
      vatAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_amount'],
      )!,
      discount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}discount'],
      )!,
      totalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_price'],
      )!,
      totalWithVat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_with_vat'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: $ReceiptItemsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $ReceiptItemsTable createAlias(String alias) {
    return $ReceiptItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
}

class ReceiptItem extends DataClass implements Insertable<ReceiptItem> {
  final int id;
  final String uuid;
  final int receiptId;
  final int itemId;
  final double quantity;
  final double unitPrice;
  final double vatRate;
  final double vatAmount;
  final double discount;
  final double totalPrice;
  final double totalWithVat;
  final String? notes;
  final DateTime createdAt;
  const ReceiptItem({
    required this.id,
    required this.uuid,
    required this.receiptId,
    required this.itemId,
    required this.quantity,
    required this.unitPrice,
    required this.vatRate,
    required this.vatAmount,
    required this.discount,
    required this.totalPrice,
    required this.totalWithVat,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['receipt_id'] = Variable<int>(receiptId);
    map['item_id'] = Variable<int>(itemId);
    map['quantity'] = Variable<double>(quantity);
    map['unit_price'] = Variable<double>(unitPrice);
    map['vat_rate'] = Variable<double>(vatRate);
    map['vat_amount'] = Variable<double>(vatAmount);
    map['discount'] = Variable<double>(discount);
    map['total_price'] = Variable<double>(totalPrice);
    map['total_with_vat'] = Variable<double>(totalWithVat);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $ReceiptItemsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  ReceiptItemsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptItemsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      receiptId: Value(receiptId),
      itemId: Value(itemId),
      quantity: Value(quantity),
      unitPrice: Value(unitPrice),
      vatRate: Value(vatRate),
      vatAmount: Value(vatAmount),
      discount: Value(discount),
      totalPrice: Value(totalPrice),
      totalWithVat: Value(totalWithVat),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory ReceiptItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptItem(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      itemId: serializer.fromJson<int>(json['itemId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      vatRate: serializer.fromJson<double>(json['vatRate']),
      vatAmount: serializer.fromJson<double>(json['vatAmount']),
      discount: serializer.fromJson<double>(json['discount']),
      totalPrice: serializer.fromJson<double>(json['totalPrice']),
      totalWithVat: serializer.fromJson<double>(json['totalWithVat']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'receiptId': serializer.toJson<int>(receiptId),
      'itemId': serializer.toJson<int>(itemId),
      'quantity': serializer.toJson<double>(quantity),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'vatRate': serializer.toJson<double>(vatRate),
      'vatAmount': serializer.toJson<double>(vatAmount),
      'discount': serializer.toJson<double>(discount),
      'totalPrice': serializer.toJson<double>(totalPrice),
      'totalWithVat': serializer.toJson<double>(totalWithVat),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ReceiptItem copyWith({
    int? id,
    String? uuid,
    int? receiptId,
    int? itemId,
    double? quantity,
    double? unitPrice,
    double? vatRate,
    double? vatAmount,
    double? discount,
    double? totalPrice,
    double? totalWithVat,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => ReceiptItem(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    receiptId: receiptId ?? this.receiptId,
    itemId: itemId ?? this.itemId,
    quantity: quantity ?? this.quantity,
    unitPrice: unitPrice ?? this.unitPrice,
    vatRate: vatRate ?? this.vatRate,
    vatAmount: vatAmount ?? this.vatAmount,
    discount: discount ?? this.discount,
    totalPrice: totalPrice ?? this.totalPrice,
    totalWithVat: totalWithVat ?? this.totalWithVat,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  ReceiptItem copyWithCompanion(ReceiptItemsCompanion data) {
    return ReceiptItem(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      vatRate: data.vatRate.present ? data.vatRate.value : this.vatRate,
      vatAmount: data.vatAmount.present ? data.vatAmount.value : this.vatAmount,
      discount: data.discount.present ? data.discount.value : this.discount,
      totalPrice: data.totalPrice.present
          ? data.totalPrice.value
          : this.totalPrice,
      totalWithVat: data.totalWithVat.present
          ? data.totalWithVat.value
          : this.totalWithVat,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItem(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptId: $receiptId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('vatRate: $vatRate, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('discount: $discount, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('totalWithVat: $totalWithVat, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    receiptId,
    itemId,
    quantity,
    unitPrice,
    vatRate,
    vatAmount,
    discount,
    totalPrice,
    totalWithVat,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptItem &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.receiptId == this.receiptId &&
          other.itemId == this.itemId &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.vatRate == this.vatRate &&
          other.vatAmount == this.vatAmount &&
          other.discount == this.discount &&
          other.totalPrice == this.totalPrice &&
          other.totalWithVat == this.totalWithVat &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class ReceiptItemsCompanion extends UpdateCompanion<ReceiptItem> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> receiptId;
  final Value<int> itemId;
  final Value<double> quantity;
  final Value<double> unitPrice;
  final Value<double> vatRate;
  final Value<double> vatAmount;
  final Value<double> discount;
  final Value<double> totalPrice;
  final Value<double> totalWithVat;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const ReceiptItemsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.discount = const Value.absent(),
    this.totalPrice = const Value.absent(),
    this.totalWithVat = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReceiptItemsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int receiptId,
    required int itemId,
    this.quantity = const Value.absent(),
    required double unitPrice,
    this.vatRate = const Value.absent(),
    this.vatAmount = const Value.absent(),
    this.discount = const Value.absent(),
    required double totalPrice,
    required double totalWithVat,
    this.notes = const Value.absent(),
    required DateTime createdAt,
  }) : receiptId = Value(receiptId),
       itemId = Value(itemId),
       unitPrice = Value(unitPrice),
       totalPrice = Value(totalPrice),
       totalWithVat = Value(totalWithVat),
       createdAt = Value(createdAt);
  static Insertable<ReceiptItem> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? receiptId,
    Expression<int>? itemId,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? vatRate,
    Expression<double>? vatAmount,
    Expression<double>? discount,
    Expression<double>? totalPrice,
    Expression<double>? totalWithVat,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (receiptId != null) 'receipt_id': receiptId,
      if (itemId != null) 'item_id': itemId,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (vatRate != null) 'vat_rate': vatRate,
      if (vatAmount != null) 'vat_amount': vatAmount,
      if (discount != null) 'discount': discount,
      if (totalPrice != null) 'total_price': totalPrice,
      if (totalWithVat != null) 'total_with_vat': totalWithVat,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReceiptItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? receiptId,
    Value<int>? itemId,
    Value<double>? quantity,
    Value<double>? unitPrice,
    Value<double>? vatRate,
    Value<double>? vatAmount,
    Value<double>? discount,
    Value<double>? totalPrice,
    Value<double>? totalWithVat,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return ReceiptItemsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      receiptId: receiptId ?? this.receiptId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      vatRate: vatRate ?? this.vatRate,
      vatAmount: vatAmount ?? this.vatAmount,
      discount: discount ?? this.discount,
      totalPrice: totalPrice ?? this.totalPrice,
      totalWithVat: totalWithVat ?? this.totalWithVat,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (vatRate.present) {
      map['vat_rate'] = Variable<double>(vatRate.value);
    }
    if (vatAmount.present) {
      map['vat_amount'] = Variable<double>(vatAmount.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (totalPrice.present) {
      map['total_price'] = Variable<double>(totalPrice.value);
    }
    if (totalWithVat.present) {
      map['total_with_vat'] = Variable<double>(totalWithVat.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $ReceiptItemsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptItemsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptId: $receiptId, ')
          ..write('itemId: $itemId, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('vatRate: $vatRate, ')
          ..write('vatAmount: $vatAmount, ')
          ..write('discount: $discount, ')
          ..write('totalPrice: $totalPrice, ')
          ..write('totalWithVat: $totalWithVat, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> paymentDate =
      GeneratedColumn<DateTime>(
        'payment_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PaymentsTable.$converterpaymentDate);
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenceMeta = const VerificationMeta(
    'reference',
  );
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
    'reference',
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
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PaymentsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    receiptId,
    amount,
    paymentDate,
    paymentMethod,
    reference,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_paymentMethodMeta);
    }
    if (data.containsKey('reference')) {
      context.handle(
        _referenceMeta,
        reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta),
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
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentDate: $PaymentsTable.$converterpaymentDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}payment_date'],
        )!,
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      )!,
      reference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: $PaymentsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterpaymentDate =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
}

class Payment extends DataClass implements Insertable<Payment> {
  final int id;
  final String uuid;
  final int receiptId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  const Payment({
    required this.id,
    required this.uuid,
    required this.receiptId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.reference,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['receipt_id'] = Variable<int>(receiptId);
    map['amount'] = Variable<double>(amount);
    {
      map['payment_date'] = Variable<DateTime>(
        $PaymentsTable.$converterpaymentDate.toSql(paymentDate),
      );
    }
    map['payment_method'] = Variable<String>(paymentMethod);
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $PaymentsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      receiptId: Value(receiptId),
      amount: Value(amount),
      paymentDate: Value(paymentDate),
      paymentMethod: Value(paymentMethod),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      receiptId: serializer.fromJson<int>(json['receiptId']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      reference: serializer.fromJson<String?>(json['reference']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'receiptId': serializer.toJson<int>(receiptId),
      'amount': serializer.toJson<double>(amount),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'reference': serializer.toJson<String?>(reference),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Payment copyWith({
    int? id,
    String? uuid,
    int? receiptId,
    double? amount,
    DateTime? paymentDate,
    String? paymentMethod,
    Value<String?> reference = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => Payment(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    receiptId: receiptId ?? this.receiptId,
    amount: amount ?? this.amount,
    paymentDate: paymentDate ?? this.paymentDate,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    reference: reference.present ? reference.value : this.reference,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentDate: data.paymentDate.present
          ? data.paymentDate.value
          : this.paymentDate,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      reference: data.reference.present ? data.reference.value : this.reference,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptId: $receiptId, ')
          ..write('amount: $amount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    receiptId,
    amount,
    paymentDate,
    paymentMethod,
    reference,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.receiptId == this.receiptId &&
          other.amount == this.amount &&
          other.paymentDate == this.paymentDate &&
          other.paymentMethod == this.paymentMethod &&
          other.reference == this.reference &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> receiptId;
  final Value<double> amount;
  final Value<DateTime> paymentDate;
  final Value<String> paymentMethod;
  final Value<String?> reference;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.receiptId = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int receiptId,
    required double amount,
    required DateTime paymentDate,
    required String paymentMethod,
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  }) : receiptId = Value(receiptId),
       amount = Value(amount),
       paymentDate = Value(paymentDate),
       paymentMethod = Value(paymentMethod),
       createdAt = Value(createdAt);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? receiptId,
    Expression<double>? amount,
    Expression<DateTime>? paymentDate,
    Expression<String>? paymentMethod,
    Expression<String>? reference,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (receiptId != null) 'receipt_id': receiptId,
      if (amount != null) 'amount': amount,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaymentsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? receiptId,
    Value<double>? amount,
    Value<DateTime>? paymentDate,
    Value<String>? paymentMethod,
    Value<String?>? reference,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      receiptId: receiptId ?? this.receiptId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(
        $PaymentsTable.$converterpaymentDate.toSql(paymentDate.value),
      );
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $PaymentsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('receiptId: $receiptId, ')
          ..write('amount: $amount, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PriceHistoryTable extends PriceHistory
    with TableInfo<$PriceHistoryTable, PriceHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PriceHistoryTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<int> itemId = GeneratedColumn<int>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vatRateMeta = const VerificationMeta(
    'vatRate',
  );
  @override
  late final GeneratedColumn<double> vatRate = GeneratedColumn<double>(
    'vat_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(24.0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> receiptDate =
      GeneratedColumn<DateTime>(
        'receipt_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PriceHistoryTable.$converterreceiptDate);
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  @override
  late final GeneratedColumn<int> supplierId = GeneratedColumn<int>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES suppliers (id)',
    ),
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
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
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($PriceHistoryTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    itemId,
    price,
    vatRate,
    receiptDate,
    supplierId,
    quantity,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<PriceHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    } else if (isInserting) {
      context.missing(_priceMeta);
    }
    if (data.containsKey('vat_rate')) {
      context.handle(
        _vatRateMeta,
        vatRate.isAcceptableOrUnknown(data['vat_rate']!, _vatRateMeta),
      );
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
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
  PriceHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PriceHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_id'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      )!,
      vatRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vat_rate'],
      )!,
      receiptDate: $PriceHistoryTable.$converterreceiptDate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}receipt_date'],
        )!,
      ),
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}supplier_id'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: $PriceHistoryTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $PriceHistoryTable createAlias(String alias) {
    return $PriceHistoryTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterreceiptDate =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
}

class PriceHistoryData extends DataClass
    implements Insertable<PriceHistoryData> {
  final int id;
  final String uuid;
  final int itemId;
  final double price;
  final double vatRate;
  final DateTime receiptDate;
  final int supplierId;
  final double quantity;
  final String? notes;
  final DateTime createdAt;
  const PriceHistoryData({
    required this.id,
    required this.uuid,
    required this.itemId,
    required this.price,
    required this.vatRate,
    required this.receiptDate,
    required this.supplierId,
    required this.quantity,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['item_id'] = Variable<int>(itemId);
    map['price'] = Variable<double>(price);
    map['vat_rate'] = Variable<double>(vatRate);
    {
      map['receipt_date'] = Variable<DateTime>(
        $PriceHistoryTable.$converterreceiptDate.toSql(receiptDate),
      );
    }
    map['supplier_id'] = Variable<int>(supplierId);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $PriceHistoryTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  PriceHistoryCompanion toCompanion(bool nullToAbsent) {
    return PriceHistoryCompanion(
      id: Value(id),
      uuid: Value(uuid),
      itemId: Value(itemId),
      price: Value(price),
      vatRate: Value(vatRate),
      receiptDate: Value(receiptDate),
      supplierId: Value(supplierId),
      quantity: Value(quantity),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PriceHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PriceHistoryData(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      itemId: serializer.fromJson<int>(json['itemId']),
      price: serializer.fromJson<double>(json['price']),
      vatRate: serializer.fromJson<double>(json['vatRate']),
      receiptDate: serializer.fromJson<DateTime>(json['receiptDate']),
      supplierId: serializer.fromJson<int>(json['supplierId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'itemId': serializer.toJson<int>(itemId),
      'price': serializer.toJson<double>(price),
      'vatRate': serializer.toJson<double>(vatRate),
      'receiptDate': serializer.toJson<DateTime>(receiptDate),
      'supplierId': serializer.toJson<int>(supplierId),
      'quantity': serializer.toJson<double>(quantity),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PriceHistoryData copyWith({
    int? id,
    String? uuid,
    int? itemId,
    double? price,
    double? vatRate,
    DateTime? receiptDate,
    int? supplierId,
    double? quantity,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => PriceHistoryData(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    itemId: itemId ?? this.itemId,
    price: price ?? this.price,
    vatRate: vatRate ?? this.vatRate,
    receiptDate: receiptDate ?? this.receiptDate,
    supplierId: supplierId ?? this.supplierId,
    quantity: quantity ?? this.quantity,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  PriceHistoryData copyWithCompanion(PriceHistoryCompanion data) {
    return PriceHistoryData(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      price: data.price.present ? data.price.value : this.price,
      vatRate: data.vatRate.present ? data.vatRate.value : this.vatRate,
      receiptDate: data.receiptDate.present
          ? data.receiptDate.value
          : this.receiptDate,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryData(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('itemId: $itemId, ')
          ..write('price: $price, ')
          ..write('vatRate: $vatRate, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('supplierId: $supplierId, ')
          ..write('quantity: $quantity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    itemId,
    price,
    vatRate,
    receiptDate,
    supplierId,
    quantity,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PriceHistoryData &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.itemId == this.itemId &&
          other.price == this.price &&
          other.vatRate == this.vatRate &&
          other.receiptDate == this.receiptDate &&
          other.supplierId == this.supplierId &&
          other.quantity == this.quantity &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PriceHistoryCompanion extends UpdateCompanion<PriceHistoryData> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> itemId;
  final Value<double> price;
  final Value<double> vatRate;
  final Value<DateTime> receiptDate;
  final Value<int> supplierId;
  final Value<double> quantity;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const PriceHistoryCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.itemId = const Value.absent(),
    this.price = const Value.absent(),
    this.vatRate = const Value.absent(),
    this.receiptDate = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PriceHistoryCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int itemId,
    required double price,
    this.vatRate = const Value.absent(),
    required DateTime receiptDate,
    required int supplierId,
    this.quantity = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  }) : itemId = Value(itemId),
       price = Value(price),
       receiptDate = Value(receiptDate),
       supplierId = Value(supplierId),
       createdAt = Value(createdAt);
  static Insertable<PriceHistoryData> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? itemId,
    Expression<double>? price,
    Expression<double>? vatRate,
    Expression<DateTime>? receiptDate,
    Expression<int>? supplierId,
    Expression<double>? quantity,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (itemId != null) 'item_id': itemId,
      if (price != null) 'price': price,
      if (vatRate != null) 'vat_rate': vatRate,
      if (receiptDate != null) 'receipt_date': receiptDate,
      if (supplierId != null) 'supplier_id': supplierId,
      if (quantity != null) 'quantity': quantity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PriceHistoryCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? itemId,
    Value<double>? price,
    Value<double>? vatRate,
    Value<DateTime>? receiptDate,
    Value<int>? supplierId,
    Value<double>? quantity,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return PriceHistoryCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      itemId: itemId ?? this.itemId,
      price: price ?? this.price,
      vatRate: vatRate ?? this.vatRate,
      receiptDate: receiptDate ?? this.receiptDate,
      supplierId: supplierId ?? this.supplierId,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<int>(itemId.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (vatRate.present) {
      map['vat_rate'] = Variable<double>(vatRate.value);
    }
    if (receiptDate.present) {
      map['receipt_date'] = Variable<DateTime>(
        $PriceHistoryTable.$converterreceiptDate.toSql(receiptDate.value),
      );
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<int>(supplierId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $PriceHistoryTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PriceHistoryCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('itemId: $itemId, ')
          ..write('price: $price, ')
          ..write('vatRate: $vatRate, ')
          ..write('receiptDate: $receiptDate, ')
          ..write('supplierId: $supplierId, ')
          ..write('quantity: $quantity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BudgetsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($BudgetsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    uuid,
    categoryId,
    month,
    year,
    amount,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {categoryId, month, year},
  ];
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: $BudgetsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $BudgetsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final String uuid;
  final int categoryId;
  final int month;
  final int year;
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Budget({
    required this.id,
    required this.uuid,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['category_id'] = Variable<int>(categoryId);
    map['month'] = Variable<int>(month);
    map['year'] = Variable<int>(year);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $BudgetsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<DateTime>(
        $BudgetsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      categoryId: Value(categoryId),
      month: Value(month),
      year: Value(year),
      amount: Value(amount),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int>(json['year']),
      amount: serializer.fromJson<double>(json['amount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'categoryId': serializer.toJson<int>(categoryId),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int>(year),
      'amount': serializer.toJson<double>(amount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Budget copyWith({
    int? id,
    String? uuid,
    int? categoryId,
    int? month,
    int? year,
    double? amount,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Budget(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    categoryId: categoryId ?? this.categoryId,
    month: month ?? this.month,
    year: year ?? this.year,
    amount: amount ?? this.amount,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      month: data.month.present ? data.month.value : this.month,
      year: data.year.present ? data.year.value : this.year,
      amount: data.amount.present ? data.amount.value : this.amount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('categoryId: $categoryId, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('amount: $amount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    uuid,
    categoryId,
    month,
    year,
    amount,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.categoryId == this.categoryId &&
          other.month == this.month &&
          other.year == this.year &&
          other.amount == this.amount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<int> categoryId;
  final Value<int> month;
  final Value<int> year;
  final Value<double> amount;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.amount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required int categoryId,
    required int month,
    required int year,
    required double amount,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : categoryId = Value(categoryId),
       month = Value(month),
       year = Value(year),
       amount = Value(amount),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<int>? categoryId,
    Expression<int>? month,
    Expression<int>? year,
    Expression<double>? amount,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (categoryId != null) 'category_id': categoryId,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (amount != null) 'amount': amount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<int>? categoryId,
    Value<int>? month,
    Value<int>? year,
    Value<double>? amount,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $BudgetsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $BudgetsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('categoryId: $categoryId, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('amount: $amount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, Tag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
    clientDefault: () => const Uuid().v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($TagsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, uuid, name, color, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Tag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
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
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Tag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      createdAt: $TagsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}created_at'],
        )!,
      ),
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const UtcDateTimeConverter();
}

class Tag extends DataClass implements Insertable<Tag> {
  final int id;
  final String uuid;
  final String name;
  final String? color;
  final DateTime createdAt;
  const Tag({
    required this.id,
    required this.uuid,
    required this.name,
    this.color,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['uuid'] = Variable<String>(uuid);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    {
      map['created_at'] = Variable<DateTime>(
        $TagsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      uuid: Value(uuid),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
    );
  }

  factory Tag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Tag(
      id: serializer.fromJson<int>(json['id']),
      uuid: serializer.fromJson<String>(json['uuid']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<String?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'uuid': serializer.toJson<String>(uuid),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<String?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Tag copyWith({
    int? id,
    String? uuid,
    String? name,
    Value<String?> color = const Value.absent(),
    DateTime? createdAt,
  }) => Tag(
    id: id ?? this.id,
    uuid: uuid ?? this.uuid,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
  );
  Tag copyWithCompanion(TagsCompanion data) {
    return Tag(
      id: data.id.present ? data.id.value : this.id,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Tag(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, uuid, name, color, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Tag &&
          other.id == this.id &&
          other.uuid == this.uuid &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt);
}

class TagsCompanion extends UpdateCompanion<Tag> {
  final Value<int> id;
  final Value<String> uuid;
  final Value<String> name;
  final Value<String?> color;
  final Value<DateTime> createdAt;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TagsCompanion.insert({
    this.id = const Value.absent(),
    this.uuid = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Tag> custom({
    Expression<int>? id,
    Expression<String>? uuid,
    Expression<String>? name,
    Expression<String>? color,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TagsCompanion copyWith({
    Value<int>? id,
    Value<String>? uuid,
    Value<String>? name,
    Value<String?>? color,
    Value<DateTime>? createdAt,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
        $TagsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('uuid: $uuid, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ReceiptTagsTable extends ReceiptTags
    with TableInfo<$ReceiptTagsTable, ReceiptTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _receiptIdMeta = const VerificationMeta(
    'receiptId',
  );
  @override
  late final GeneratedColumn<int> receiptId = GeneratedColumn<int>(
    'receipt_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (id)',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<int> tagId = GeneratedColumn<int>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [receiptId, tagId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('receipt_id')) {
      context.handle(
        _receiptIdMeta,
        receiptId.isAcceptableOrUnknown(data['receipt_id']!, _receiptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_receiptIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {receiptId, tagId};
  @override
  ReceiptTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptTag(
      receiptId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}receipt_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $ReceiptTagsTable createAlias(String alias) {
    return $ReceiptTagsTable(attachedDatabase, alias);
  }
}

class ReceiptTag extends DataClass implements Insertable<ReceiptTag> {
  final int receiptId;
  final int tagId;
  const ReceiptTag({required this.receiptId, required this.tagId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['receipt_id'] = Variable<int>(receiptId);
    map['tag_id'] = Variable<int>(tagId);
    return map;
  }

  ReceiptTagsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptTagsCompanion(
      receiptId: Value(receiptId),
      tagId: Value(tagId),
    );
  }

  factory ReceiptTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptTag(
      receiptId: serializer.fromJson<int>(json['receiptId']),
      tagId: serializer.fromJson<int>(json['tagId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'receiptId': serializer.toJson<int>(receiptId),
      'tagId': serializer.toJson<int>(tagId),
    };
  }

  ReceiptTag copyWith({int? receiptId, int? tagId}) => ReceiptTag(
    receiptId: receiptId ?? this.receiptId,
    tagId: tagId ?? this.tagId,
  );
  ReceiptTag copyWithCompanion(ReceiptTagsCompanion data) {
    return ReceiptTag(
      receiptId: data.receiptId.present ? data.receiptId.value : this.receiptId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptTag(')
          ..write('receiptId: $receiptId, ')
          ..write('tagId: $tagId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(receiptId, tagId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptTag &&
          other.receiptId == this.receiptId &&
          other.tagId == this.tagId);
}

class ReceiptTagsCompanion extends UpdateCompanion<ReceiptTag> {
  final Value<int> receiptId;
  final Value<int> tagId;
  final Value<int> rowid;
  const ReceiptTagsCompanion({
    this.receiptId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptTagsCompanion.insert({
    required int receiptId,
    required int tagId,
    this.rowid = const Value.absent(),
  }) : receiptId = Value(receiptId),
       tagId = Value(tagId);
  static Insertable<ReceiptTag> custom({
    Expression<int>? receiptId,
    Expression<int>? tagId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (receiptId != null) 'receipt_id': receiptId,
      if (tagId != null) 'tag_id': tagId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptTagsCompanion copyWith({
    Value<int>? receiptId,
    Value<int>? tagId,
    Value<int>? rowid,
  }) {
    return ReceiptTagsCompanion(
      receiptId: receiptId ?? this.receiptId,
      tagId: tagId ?? this.tagId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (receiptId.present) {
      map['receipt_id'] = Variable<int>(receiptId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<int>(tagId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptTagsCompanion(')
          ..write('receiptId: $receiptId, ')
          ..write('tagId: $tagId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserSettingsTable extends UserSettings
    with TableInfo<$UserSettingsTable, UserSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserSettingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('string'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($UserSettingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [id, key, value, type, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserSetting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      updatedAt: $UserSettingsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $UserSettingsTable createAlias(String alias) {
    return $UserSettingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class UserSetting extends DataClass implements Insertable<UserSetting> {
  final int id;
  final String key;
  final String? value;
  final String type;
  final DateTime updatedAt;
  const UserSetting({
    required this.id,
    required this.key,
    this.value,
    required this.type,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['type'] = Variable<String>(type);
    {
      map['updated_at'] = Variable<DateTime>(
        $UserSettingsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  UserSettingsCompanion toCompanion(bool nullToAbsent) {
    return UserSettingsCompanion(
      id: Value(id),
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      type: Value(type),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserSetting(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
      type: serializer.fromJson<String>(json['type']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
      'type': serializer.toJson<String>(type),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserSetting copyWith({
    int? id,
    String? key,
    Value<String?> value = const Value.absent(),
    String? type,
    DateTime? updatedAt,
  }) => UserSetting(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
    type: type ?? this.type,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserSetting copyWithCompanion(UserSettingsCompanion data) {
    return UserSetting(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      type: data.type.present ? data.type.value : this.type,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserSetting(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('type: $type, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value, type, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserSetting &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value &&
          other.type == this.type &&
          other.updatedAt == this.updatedAt);
}

class UserSettingsCompanion extends UpdateCompanion<UserSetting> {
  final Value<int> id;
  final Value<String> key;
  final Value<String?> value;
  final Value<String> type;
  final Value<DateTime> updatedAt;
  const UserSettingsCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.type = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserSettingsCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    this.value = const Value.absent(),
    this.type = const Value.absent(),
    required DateTime updatedAt,
  }) : key = Value(key),
       updatedAt = Value(updatedAt);
  static Insertable<UserSetting> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? type,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (type != null) 'type': type,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String?>? value,
    Value<String>? type,
    Value<DateTime>? updatedAt,
  }) {
    return UserSettingsCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      type: type ?? this.type,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
        $UserSettingsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserSettingsCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('type: $type, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $SuppliersTable suppliers = $SuppliersTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  late final $ReceiptItemsTable receiptItems = $ReceiptItemsTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $PriceHistoryTable priceHistory = $PriceHistoryTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $ReceiptTagsTable receiptTags = $ReceiptTagsTable(this);
  late final $UserSettingsTable userSettings = $UserSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    suppliers,
    items,
    receipts,
    receiptItems,
    payments,
    priceHistory,
    budgets,
    tags,
    receiptTags,
    userSettings,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required String name,
  Value<String?> description,
  Value<String?> icon,
  Value<String?> color,
  Value<int?> parentId,
  Value<int> level,
  Value<int> sortOrder,
  Value<bool> isActive,
  Value<String?> createdBy,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<String?> description,
  Value<String?> icon,
  Value<String?> color,
  Value<int?> parentId,
  Value<int> level,
  Value<int> sortOrder,
  Value<bool> isActive,
  Value<String?> createdBy,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias('categories__parent_id__categories__id');

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<int>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<Item>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'categories__id__items__category_id',
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
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

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
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

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
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

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool parentId,
            bool itemsRefs,
            bool budgetsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                uuid: uuid,
                name: name,
                description: description,
                icon: icon,
                color: color,
                parentId: parentId,
                level: level,
                sortOrder: sortOrder,
                isActive: isActive,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<int?> parentId = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<String?> createdBy = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => CategoriesCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                description: description,
                icon: icon,
                color: color,
                parentId: parentId,
                level: level,
                sortOrder: sortOrder,
                isActive: isActive,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({parentId = false, itemsRefs = false, budgetsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (itemsRefs) db.items,
                    if (budgetsRefs) db.budgets,
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
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$CategoriesTableReferences
                                ._parentIdTable(db),
                            referencedColumn: $$CategoriesTableReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (itemsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Item
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).itemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool parentId, bool itemsRefs, bool budgetsRefs})
    >;
typedef $$SuppliersTableCreateCompanionBuilder = SuppliersCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required String name,
  Value<String?> vatNumber,
  Value<String?> taxOffice,
  Value<String?> phone,
  Value<String?> mobile,
  Value<String?> email,
  Value<String?> website,
  Value<String?> address,
  Value<String?> city,
  Value<String?> postalCode,
  Value<String> country,
  Value<String?> bankName,
  Value<String?> bankAccount,
  Value<String?> iban,
  Value<String?> notes,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$SuppliersTableUpdateCompanionBuilder = SuppliersCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<String?> vatNumber,
  Value<String?> taxOffice,
  Value<String?> phone,
  Value<String?> mobile,
  Value<String?> email,
  Value<String?> website,
  Value<String?> address,
  Value<String?> city,
  Value<String?> postalCode,
  Value<String> country,
  Value<String?> bankName,
  Value<String?> bankAccount,
  Value<String?> iban,
  Value<String?> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$SuppliersTableReferences
    extends BaseReferences<_$AppDatabase, $SuppliersTable, Supplier> {
  $$SuppliersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptsTable, List<Receipt>> _receiptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.receipts,
    aliasName: 'suppliers__id__receipts__supplier_id',
  );

  $$ReceiptsTableProcessedTableManager get receiptsRefs {
    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PriceHistoryTable, List<PriceHistoryData>>
  _priceHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.priceHistory,
    aliasName: 'suppliers__id__price_history__supplier_id',
  );

  $$PriceHistoryTableProcessedTableManager get priceHistoryRefs {
    final manager = $$PriceHistoryTableTableManager(
      $_db,
      $_db.priceHistory,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_priceHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SuppliersTableFilterComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vatNumber => $composableBuilder(
    column: $table.vatNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taxOffice => $composableBuilder(
    column: $table.taxOffice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get postalCode => $composableBuilder(
    column: $table.postalCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankAccount => $composableBuilder(
    column: $table.bankAccount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> receiptsRefs(
    Expression<bool> Function($$ReceiptsTableFilterComposer f) f,
  ) {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> priceHistoryRefs(
    Expression<bool> Function($$PriceHistoryTableFilterComposer f) f,
  ) {
    final $$PriceHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistory,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryTableFilterComposer(
            $db: $db,
            $table: $db.priceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuppliersTableOrderingComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vatNumber => $composableBuilder(
    column: $table.vatNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taxOffice => $composableBuilder(
    column: $table.taxOffice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mobile => $composableBuilder(
    column: $table.mobile,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get postalCode => $composableBuilder(
    column: $table.postalCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankAccount => $composableBuilder(
    column: $table.bankAccount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

class $$SuppliersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SuppliersTable> {
  $$SuppliersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get vatNumber =>
      $composableBuilder(column: $table.vatNumber, builder: (column) => column);

  GeneratedColumn<String> get taxOffice =>
      $composableBuilder(column: $table.taxOffice, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get postalCode => $composableBuilder(
    column: $table.postalCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get bankAccount => $composableBuilder(
    column: $table.bankAccount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iban =>
      $composableBuilder(column: $table.iban, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> receiptsRefs<T extends Object>(
    Expression<T> Function($$ReceiptsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> priceHistoryRefs<T extends Object>(
    Expression<T> Function($$PriceHistoryTableAnnotationComposer a) f,
  ) {
    final $$PriceHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistory,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.priceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SuppliersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SuppliersTable,
          Supplier,
          $$SuppliersTableFilterComposer,
          $$SuppliersTableOrderingComposer,
          $$SuppliersTableAnnotationComposer,
          $$SuppliersTableCreateCompanionBuilder,
          $$SuppliersTableUpdateCompanionBuilder,
          (Supplier, $$SuppliersTableReferences),
          Supplier,
          PrefetchHooks Function({bool receiptsRefs, bool priceHistoryRefs})
        > {
  $$SuppliersTableTableManager(_$AppDatabase db, $SuppliersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuppliersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuppliersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuppliersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> vatNumber = const Value.absent(),
                Value<String?> taxOffice = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> postalCode = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankAccount = const Value.absent(),
                Value<String?> iban = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => SuppliersCompanion(
                id: id,
                uuid: uuid,
                name: name,
                vatNumber: vatNumber,
                taxOffice: taxOffice,
                phone: phone,
                mobile: mobile,
                email: email,
                website: website,
                address: address,
                city: city,
                postalCode: postalCode,
                country: country,
                bankName: bankName,
                bankAccount: bankAccount,
                iban: iban,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                Value<String?> vatNumber = const Value.absent(),
                Value<String?> taxOffice = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> mobile = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> website = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> city = const Value.absent(),
                Value<String?> postalCode = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<String?> bankName = const Value.absent(),
                Value<String?> bankAccount = const Value.absent(),
                Value<String?> iban = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => SuppliersCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                vatNumber: vatNumber,
                taxOffice: taxOffice,
                phone: phone,
                mobile: mobile,
                email: email,
                website: website,
                address: address,
                city: city,
                postalCode: postalCode,
                country: country,
                bankName: bankName,
                bankAccount: bankAccount,
                iban: iban,
                notes: notes,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SuppliersTable, Supplier>(table),
                  $$SuppliersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({receiptsRefs = false, priceHistoryRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (receiptsRefs) db.receipts,
                    if (priceHistoryRefs) db.priceHistory,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (receiptsRefs)
                        await $_getPrefetchedData<
                          Supplier,
                          $SuppliersTable,
                          Receipt
                        >(
                          currentTable: table,
                          referencedTable: $$SuppliersTableReferences
                              ._receiptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SuppliersTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.supplierId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (priceHistoryRefs)
                        await $_getPrefetchedData<
                          Supplier,
                          $SuppliersTable,
                          PriceHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$SuppliersTableReferences
                              ._priceHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SuppliersTableReferences(
                                db,
                                table,
                                p0,
                              ).priceHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.supplierId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SuppliersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SuppliersTable,
      Supplier,
      $$SuppliersTableFilterComposer,
      $$SuppliersTableOrderingComposer,
      $$SuppliersTableAnnotationComposer,
      $$SuppliersTableCreateCompanionBuilder,
      $$SuppliersTableUpdateCompanionBuilder,
      (Supplier, $$SuppliersTableReferences),
      Supplier,
      PrefetchHooks Function({bool receiptsRefs, bool priceHistoryRefs})
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required String name,
  required int categoryId,
  Value<String?> barcode,
  Value<String?> sku,
  Value<String> unit,
  Value<double?> unitWeight,
  Value<double> minStock,
  Value<double> maxStock,
  Value<double> currentStock,
  Value<double> reorderLevel,
  Value<double?> lastPrice,
  Value<int?> lastSupplierId,
  Value<int?> preferredSupplierId,
  Value<String?> notes,
  Value<bool> isTaxable,
  Value<double> defaultVatRate,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<int> categoryId,
  Value<String?> barcode,
  Value<String?> sku,
  Value<String> unit,
  Value<double?> unitWeight,
  Value<double> minStock,
  Value<double> maxStock,
  Value<double> currentStock,
  Value<double> reorderLevel,
  Value<double?> lastPrice,
  Value<int?> lastSupplierId,
  Value<int?> preferredSupplierId,
  Value<String?> notes,
  Value<bool> isTaxable,
  Value<double> defaultVatRate,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, Item> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('items__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SuppliersTable _lastSupplierIdTable(_$AppDatabase db) =>
      db.suppliers.createAlias('items__last_supplier_id__suppliers__id');

  $$SuppliersTableProcessedTableManager? get lastSupplierId {
    final $_column = $_itemColumn<int>('last_supplier_id');
    if ($_column == null) return null;
    final manager = $$SuppliersTableTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lastSupplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SuppliersTable _preferredSupplierIdTable(_$AppDatabase db) =>
      db.suppliers.createAlias('items__preferred_supplier_id__suppliers__id');

  $$SuppliersTableProcessedTableManager? get preferredSupplierId {
    final $_column = $_itemColumn<int>('preferred_supplier_id');
    if ($_column == null) return null;
    final manager = $$SuppliersTableTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_preferredSupplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReceiptItemsTable, List<ReceiptItem>>
  _receiptItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptItems,
    aliasName: 'items__id__receipt_items__item_id',
  );

  $$ReceiptItemsTableProcessedTableManager get receiptItemsRefs {
    final manager = $$ReceiptItemsTableTableManager(
      $_db,
      $_db.receiptItems,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PriceHistoryTable, List<PriceHistoryData>>
  _priceHistoryRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.priceHistory,
    aliasName: 'items__id__price_history__item_id',
  );

  $$PriceHistoryTableProcessedTableManager get priceHistoryRefs {
    final manager = $$PriceHistoryTableTableManager(
      $_db,
      $_db.priceHistory,
    ).filter((f) => f.itemId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_priceHistoryRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitWeight => $composableBuilder(
    column: $table.unitWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get maxStock => $composableBuilder(
    column: $table.maxStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lastPrice => $composableBuilder(
    column: $table.lastPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTaxable => $composableBuilder(
    column: $table.isTaxable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultVatRate => $composableBuilder(
    column: $table.defaultVatRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableFilterComposer get lastSupplierId {
    final $$SuppliersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastSupplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableFilterComposer get preferredSupplierId {
    final $$SuppliersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.preferredSupplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> receiptItemsRefs(
    Expression<bool> Function($$ReceiptItemsTableFilterComposer f) f,
  ) {
    final $$ReceiptItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableFilterComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> priceHistoryRefs(
    Expression<bool> Function($$PriceHistoryTableFilterComposer f) f,
  ) {
    final $$PriceHistoryTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistory,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryTableFilterComposer(
            $db: $db,
            $table: $db.priceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitWeight => $composableBuilder(
    column: $table.unitWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minStock => $composableBuilder(
    column: $table.minStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get maxStock => $composableBuilder(
    column: $table.maxStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lastPrice => $composableBuilder(
    column: $table.lastPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTaxable => $composableBuilder(
    column: $table.isTaxable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultVatRate => $composableBuilder(
    column: $table.defaultVatRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
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

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableOrderingComposer get lastSupplierId {
    final $$SuppliersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastSupplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableOrderingComposer get preferredSupplierId {
    final $$SuppliersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.preferredSupplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<double> get unitWeight => $composableBuilder(
    column: $table.unitWeight,
    builder: (column) => column,
  );

  GeneratedColumn<double> get minStock =>
      $composableBuilder(column: $table.minStock, builder: (column) => column);

  GeneratedColumn<double> get maxStock =>
      $composableBuilder(column: $table.maxStock, builder: (column) => column);

  GeneratedColumn<double> get currentStock => $composableBuilder(
    column: $table.currentStock,
    builder: (column) => column,
  );

  GeneratedColumn<double> get reorderLevel => $composableBuilder(
    column: $table.reorderLevel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lastPrice =>
      $composableBuilder(column: $table.lastPrice, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isTaxable =>
      $composableBuilder(column: $table.isTaxable, builder: (column) => column);

  GeneratedColumn<double> get defaultVatRate => $composableBuilder(
    column: $table.defaultVatRate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableAnnotationComposer get lastSupplierId {
    final $$SuppliersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastSupplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableAnnotationComposer get preferredSupplierId {
    final $$SuppliersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.preferredSupplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> receiptItemsRefs<T extends Object>(
    Expression<T> Function($$ReceiptItemsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> priceHistoryRefs<T extends Object>(
    Expression<T> Function($$PriceHistoryTableAnnotationComposer a) f,
  ) {
    final $$PriceHistoryTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.priceHistory,
      getReferencedColumn: (t) => t.itemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PriceHistoryTableAnnotationComposer(
            $db: $db,
            $table: $db.priceHistory,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          Item,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (Item, $$ItemsTableReferences),
          Item,
          PrefetchHooks Function({
            bool categoryId,
            bool lastSupplierId,
            bool preferredSupplierId,
            bool receiptItemsRefs,
            bool priceHistoryRefs,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> unitWeight = const Value.absent(),
                Value<double> minStock = const Value.absent(),
                Value<double> maxStock = const Value.absent(),
                Value<double> currentStock = const Value.absent(),
                Value<double> reorderLevel = const Value.absent(),
                Value<double?> lastPrice = const Value.absent(),
                Value<int?> lastSupplierId = const Value.absent(),
                Value<int?> preferredSupplierId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isTaxable = const Value.absent(),
                Value<double> defaultVatRate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                categoryId: categoryId,
                barcode: barcode,
                sku: sku,
                unit: unit,
                unitWeight: unitWeight,
                minStock: minStock,
                maxStock: maxStock,
                currentStock: currentStock,
                reorderLevel: reorderLevel,
                lastPrice: lastPrice,
                lastSupplierId: lastSupplierId,
                preferredSupplierId: preferredSupplierId,
                notes: notes,
                isTaxable: isTaxable,
                defaultVatRate: defaultVatRate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                required int categoryId,
                Value<String?> barcode = const Value.absent(),
                Value<String?> sku = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<double?> unitWeight = const Value.absent(),
                Value<double> minStock = const Value.absent(),
                Value<double> maxStock = const Value.absent(),
                Value<double> currentStock = const Value.absent(),
                Value<double> reorderLevel = const Value.absent(),
                Value<double?> lastPrice = const Value.absent(),
                Value<int?> lastSupplierId = const Value.absent(),
                Value<int?> preferredSupplierId = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isTaxable = const Value.absent(),
                Value<double> defaultVatRate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ItemsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                categoryId: categoryId,
                barcode: barcode,
                sku: sku,
                unit: unit,
                unitWeight: unitWeight,
                minStock: minStock,
                maxStock: maxStock,
                currentStock: currentStock,
                reorderLevel: reorderLevel,
                lastPrice: lastPrice,
                lastSupplierId: lastSupplierId,
                preferredSupplierId: preferredSupplierId,
                notes: notes,
                isTaxable: isTaxable,
                defaultVatRate: defaultVatRate,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, Item>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                lastSupplierId = false,
                preferredSupplierId = false,
                receiptItemsRefs = false,
                priceHistoryRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (receiptItemsRefs) db.receiptItems,
                    if (priceHistoryRefs) db.priceHistory,
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
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$ItemsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (lastSupplierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.lastSupplierId,
                            referencedTable: $$ItemsTableReferences
                                ._lastSupplierIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._lastSupplierIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (preferredSupplierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.preferredSupplierId,
                            referencedTable: $$ItemsTableReferences
                                ._preferredSupplierIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._preferredSupplierIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (receiptItemsRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          ReceiptItem
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._receiptItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (priceHistoryRefs)
                        await $_getPrefetchedData<
                          Item,
                          $ItemsTable,
                          PriceHistoryData
                        >(
                          currentTable: table,
                          referencedTable: $$ItemsTableReferences
                              ._priceHistoryRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).priceHistoryRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.itemId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      Item,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (Item, $$ItemsTableReferences),
      Item,
      PrefetchHooks Function({
        bool categoryId,
        bool lastSupplierId,
        bool preferredSupplierId,
        bool receiptItemsRefs,
        bool priceHistoryRefs,
      })
    >;
typedef $$ReceiptsTableCreateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required int receiptNumber,
  required DateTime receiptDate,
  required int supplierId,
  Value<String?> invoiceNumber,
  Value<String?> invoiceSeries,
  Value<String?> paymentMethod,
  Value<double> totalAmount,
  Value<double> vatTotal,
  Value<double> discountTotal,
  Value<double> paidAmount,
  Value<double> remainingAmount,
  Value<String> paymentStatus,
  Value<String?> notes,
  Value<String?> attachmentPath,
  Value<bool> isSynced,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$ReceiptsTableUpdateCompanionBuilder = ReceiptsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> receiptNumber,
  Value<DateTime> receiptDate,
  Value<int> supplierId,
  Value<String?> invoiceNumber,
  Value<String?> invoiceSeries,
  Value<String?> paymentMethod,
  Value<double> totalAmount,
  Value<double> vatTotal,
  Value<double> discountTotal,
  Value<double> paidAmount,
  Value<double> remainingAmount,
  Value<String> paymentStatus,
  Value<String?> notes,
  Value<String?> attachmentPath,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$ReceiptsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SuppliersTable _supplierIdTable(_$AppDatabase db) =>
      db.suppliers.createAlias('receipts__supplier_id__suppliers__id');

  $$SuppliersTableProcessedTableManager get supplierId {
    final $_column = $_itemColumn<int>('supplier_id')!;

    final manager = $$SuppliersTableTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ReceiptItemsTable, List<ReceiptItem>>
  _receiptItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptItems,
    aliasName: 'receipts__id__receipt_items__receipt_id',
  );

  $$ReceiptItemsTableProcessedTableManager get receiptItemsRefs {
    final manager = $$ReceiptItemsTableTableManager(
      $_db,
      $_db.receiptItems,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'receipts__id__payments__receipt_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReceiptTagsTable, List<ReceiptTag>>
  _receiptTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptTags,
    aliasName: 'receipts__id__receipt_tags__receipt_id',
  );

  $$ReceiptTagsTableProcessedTableManager get receiptTagsRefs {
    final manager = $$ReceiptTagsTableTableManager(
      $_db,
      $_db.receiptTags,
    ).filter((f) => f.receiptId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ReceiptsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceSeries => $composableBuilder(
    column: $table.invoiceSeries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatTotal => $composableBuilder(
    column: $table.vatTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$SuppliersTableFilterComposer get supplierId {
    final $$SuppliersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> receiptItemsRefs(
    Expression<bool> Function($$ReceiptItemsTableFilterComposer f) f,
  ) {
    final $$ReceiptItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableFilterComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> receiptTagsRefs(
    Expression<bool> Function($$ReceiptTagsTableFilterComposer f) f,
  ) {
    final $$ReceiptTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptTags,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptTagsTableFilterComposer(
            $db: $db,
            $table: $db.receiptTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceSeries => $composableBuilder(
    column: $table.invoiceSeries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatTotal => $composableBuilder(
    column: $table.vatTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSynced => $composableBuilder(
    column: $table.isSynced,
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

  $$SuppliersTableOrderingComposer get supplierId {
    final $$SuppliersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get receiptNumber => $composableBuilder(
    column: $table.receiptNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get receiptDate =>
      $composableBuilder(
        column: $table.receiptDate,
        builder: (column) => column,
      );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceSeries => $composableBuilder(
    column: $table.invoiceSeries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vatTotal =>
      $composableBuilder(column: $table.vatTotal, builder: (column) => column);

  GeneratedColumn<double> get discountTotal => $composableBuilder(
    column: $table.discountTotal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get paidAmount => $composableBuilder(
    column: $table.paidAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get remainingAmount => $composableBuilder(
    column: $table.remainingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get attachmentPath => $composableBuilder(
    column: $table.attachmentPath,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$SuppliersTableAnnotationComposer get supplierId {
    final $$SuppliersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> receiptItemsRefs<T extends Object>(
    Expression<T> Function($$ReceiptItemsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptItems,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> receiptTagsRefs<T extends Object>(
    Expression<T> Function($$ReceiptTagsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptTags,
      getReferencedColumn: (t) => t.receiptId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, $$ReceiptsTableReferences),
          Receipt,
          PrefetchHooks Function({
            bool supplierId,
            bool receiptItemsRefs,
            bool paymentsRefs,
            bool receiptTagsRefs,
          })
        > {
  $$ReceiptsTableTableManager(_$AppDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> receiptNumber = const Value.absent(),
                Value<DateTime> receiptDate = const Value.absent(),
                Value<int> supplierId = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> invoiceSeries = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> vatTotal = const Value.absent(),
                Value<double> discountTotal = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> remainingAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => ReceiptsCompanion(
                id: id,
                uuid: uuid,
                receiptNumber: receiptNumber,
                receiptDate: receiptDate,
                supplierId: supplierId,
                invoiceNumber: invoiceNumber,
                invoiceSeries: invoiceSeries,
                paymentMethod: paymentMethod,
                totalAmount: totalAmount,
                vatTotal: vatTotal,
                discountTotal: discountTotal,
                paidAmount: paidAmount,
                remainingAmount: remainingAmount,
                paymentStatus: paymentStatus,
                notes: notes,
                attachmentPath: attachmentPath,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int receiptNumber,
                required DateTime receiptDate,
                required int supplierId,
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> invoiceSeries = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<double> vatTotal = const Value.absent(),
                Value<double> discountTotal = const Value.absent(),
                Value<double> paidAmount = const Value.absent(),
                Value<double> remainingAmount = const Value.absent(),
                Value<String> paymentStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> attachmentPath = const Value.absent(),
                Value<bool> isSynced = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => ReceiptsCompanion.insert(
                id: id,
                uuid: uuid,
                receiptNumber: receiptNumber,
                receiptDate: receiptDate,
                supplierId: supplierId,
                invoiceNumber: invoiceNumber,
                invoiceSeries: invoiceSeries,
                paymentMethod: paymentMethod,
                totalAmount: totalAmount,
                vatTotal: vatTotal,
                discountTotal: discountTotal,
                paidAmount: paidAmount,
                remainingAmount: remainingAmount,
                paymentStatus: paymentStatus,
                notes: notes,
                attachmentPath: attachmentPath,
                isSynced: isSynced,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptsTable, Receipt>(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                supplierId = false,
                receiptItemsRefs = false,
                paymentsRefs = false,
                receiptTagsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (receiptItemsRefs) db.receiptItems,
                    if (paymentsRefs) db.payments,
                    if (receiptTagsRefs) db.receiptTags,
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
                        if (supplierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.supplierId,
                            referencedTable: $$ReceiptsTableReferences
                                ._supplierIdTable(db),
                            referencedColumn: $$ReceiptsTableReferences
                                ._supplierIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (receiptItemsRefs)
                        await $_getPrefetchedData<
                          Receipt,
                          $ReceiptsTable,
                          ReceiptItem
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._receiptItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.receiptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsRefs)
                        await $_getPrefetchedData<
                          Receipt,
                          $ReceiptsTable,
                          Payment
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.receiptId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (receiptTagsRefs)
                        await $_getPrefetchedData<
                          Receipt,
                          $ReceiptsTable,
                          ReceiptTag
                        >(
                          currentTable: table,
                          referencedTable: $$ReceiptsTableReferences
                              ._receiptTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ReceiptsTableReferences(
                                db,
                                table,
                                p0,
                              ).receiptTagsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.receiptId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, $$ReceiptsTableReferences),
      Receipt,
      PrefetchHooks Function({
        bool supplierId,
        bool receiptItemsRefs,
        bool paymentsRefs,
        bool receiptTagsRefs,
      })
    >;
typedef $$ReceiptItemsTableCreateCompanionBuilder =
    ReceiptItemsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required int receiptId,
      required int itemId,
      Value<double> quantity,
      required double unitPrice,
      Value<double> vatRate,
      Value<double> vatAmount,
      Value<double> discount,
      required double totalPrice,
      required double totalWithVat,
      Value<String?> notes,
      required DateTime createdAt,
    });
typedef $$ReceiptItemsTableUpdateCompanionBuilder =
    ReceiptItemsCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> receiptId,
      Value<int> itemId,
      Value<double> quantity,
      Value<double> unitPrice,
      Value<double> vatRate,
      Value<double> vatAmount,
      Value<double> discount,
      Value<double> totalPrice,
      Value<double> totalWithVat,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$ReceiptItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptItemsTable, ReceiptItem> {
  $$ReceiptItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('receipt_items__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('receipt_items__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTable> {
  $$ReceiptItemsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalWithVat => $composableBuilder(
    column: $table.totalWithVat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTable> {
  $$ReceiptItemsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatAmount => $composableBuilder(
    column: $table.vatAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get discount => $composableBuilder(
    column: $table.discount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalWithVat => $composableBuilder(
    column: $table.totalWithVat,
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

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptItemsTable> {
  $$ReceiptItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get vatRate =>
      $composableBuilder(column: $table.vatRate, builder: (column) => column);

  GeneratedColumn<double> get vatAmount =>
      $composableBuilder(column: $table.vatAmount, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get totalPrice => $composableBuilder(
    column: $table.totalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalWithVat => $composableBuilder(
    column: $table.totalWithVat,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptItemsTable,
          ReceiptItem,
          $$ReceiptItemsTableFilterComposer,
          $$ReceiptItemsTableOrderingComposer,
          $$ReceiptItemsTableAnnotationComposer,
          $$ReceiptItemsTableCreateCompanionBuilder,
          $$ReceiptItemsTableUpdateCompanionBuilder,
          (ReceiptItem, $$ReceiptItemsTableReferences),
          ReceiptItem,
          PrefetchHooks Function({bool receiptId, bool itemId})
        > {
  $$ReceiptItemsTableTableManager(_$AppDatabase db, $ReceiptItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> vatRate = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<double> discount = const Value.absent(),
                Value<double> totalPrice = const Value.absent(),
                Value<double> totalWithVat = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReceiptItemsCompanion(
                id: id,
                uuid: uuid,
                receiptId: receiptId,
                itemId: itemId,
                quantity: quantity,
                unitPrice: unitPrice,
                vatRate: vatRate,
                vatAmount: vatAmount,
                discount: discount,
                totalPrice: totalPrice,
                totalWithVat: totalWithVat,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int receiptId,
                required int itemId,
                Value<double> quantity = const Value.absent(),
                required double unitPrice,
                Value<double> vatRate = const Value.absent(),
                Value<double> vatAmount = const Value.absent(),
                Value<double> discount = const Value.absent(),
                required double totalPrice,
                required double totalWithVat,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
              }) => ReceiptItemsCompanion.insert(
                id: id,
                uuid: uuid,
                receiptId: receiptId,
                itemId: itemId,
                quantity: quantity,
                unitPrice: unitPrice,
                vatRate: vatRate,
                vatAmount: vatAmount,
                discount: discount,
                totalPrice: totalPrice,
                totalWithVat: totalWithVat,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptItemsTable, ReceiptItem>(table),
                  $$ReceiptItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false, itemId = false}) {
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
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$ReceiptItemsTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$ReceiptItemsTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$ReceiptItemsTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$ReceiptItemsTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ReceiptItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptItemsTable,
      ReceiptItem,
      $$ReceiptItemsTableFilterComposer,
      $$ReceiptItemsTableOrderingComposer,
      $$ReceiptItemsTableAnnotationComposer,
      $$ReceiptItemsTableCreateCompanionBuilder,
      $$ReceiptItemsTableUpdateCompanionBuilder,
      (ReceiptItem, $$ReceiptItemsTableReferences),
      ReceiptItem,
      PrefetchHooks Function({bool receiptId, bool itemId})
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required int receiptId,
  required double amount,
  required DateTime paymentDate,
  required String paymentMethod,
  Value<String?> reference,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> receiptId,
  Value<double> amount,
  Value<DateTime> paymentDate,
  Value<String> paymentMethod,
  Value<String?> reference,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('payments__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reference => $composableBuilder(
    column: $table.reference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
    column: $table.paymentDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reference => $composableBuilder(
    column: $table.reference,
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

  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get paymentDate =>
      $composableBuilder(
        column: $table.paymentDate,
        builder: (column) => column,
      );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reference =>
      $composableBuilder(column: $table.reference, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, $$PaymentsTableReferences),
          Payment,
          PrefetchHooks Function({bool receiptId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> receiptId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> paymentDate = const Value.absent(),
                Value<String> paymentMethod = const Value.absent(),
                Value<String?> reference = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                uuid: uuid,
                receiptId: receiptId,
                amount: amount,
                paymentDate: paymentDate,
                paymentMethod: paymentMethod,
                reference: reference,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int receiptId,
                required double amount,
                required DateTime paymentDate,
                required String paymentMethod,
                Value<String?> reference = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
              }) => PaymentsCompanion.insert(
                id: id,
                uuid: uuid,
                receiptId: receiptId,
                amount: amount,
                paymentDate: paymentDate,
                paymentMethod: paymentMethod,
                reference: reference,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaymentsTable, Payment>(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false}) {
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
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$PaymentsTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$PaymentsTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, $$PaymentsTableReferences),
      Payment,
      PrefetchHooks Function({bool receiptId})
    >;
typedef $$PriceHistoryTableCreateCompanionBuilder =
    PriceHistoryCompanion Function({
      Value<int> id,
      Value<String> uuid,
      required int itemId,
      required double price,
      Value<double> vatRate,
      required DateTime receiptDate,
      required int supplierId,
      Value<double> quantity,
      Value<String?> notes,
      required DateTime createdAt,
    });
typedef $$PriceHistoryTableUpdateCompanionBuilder =
    PriceHistoryCompanion Function({
      Value<int> id,
      Value<String> uuid,
      Value<int> itemId,
      Value<double> price,
      Value<double> vatRate,
      Value<DateTime> receiptDate,
      Value<int> supplierId,
      Value<double> quantity,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$PriceHistoryTableReferences
    extends
        BaseReferences<_$AppDatabase, $PriceHistoryTable, PriceHistoryData> {
  $$PriceHistoryTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ItemsTable _itemIdTable(_$AppDatabase db) =>
      db.items.createAlias('price_history__item_id__items__id');

  $$ItemsTableProcessedTableManager get itemId {
    final $_column = $_itemColumn<int>('item_id')!;

    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_itemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $SuppliersTable _supplierIdTable(_$AppDatabase db) =>
      db.suppliers.createAlias('price_history__supplier_id__suppliers__id');

  $$SuppliersTableProcessedTableManager get supplierId {
    final $_column = $_itemColumn<int>('supplier_id')!;

    final manager = $$SuppliersTableTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PriceHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $PriceHistoryTable> {
  $$PriceHistoryTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime>
  get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$ItemsTableFilterComposer get itemId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableFilterComposer get supplierId {
    final $$SuppliersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $PriceHistoryTable> {
  $$PriceHistoryTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vatRate => $composableBuilder(
    column: $table.vatRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receiptDate => $composableBuilder(
    column: $table.receiptDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
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

  $$ItemsTableOrderingComposer get itemId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableOrderingComposer get supplierId {
    final $$SuppliersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $PriceHistoryTable> {
  $$PriceHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get vatRate =>
      $composableBuilder(column: $table.vatRate, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get receiptDate =>
      $composableBuilder(
        column: $table.receiptDate,
        builder: (column) => column,
      );

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ItemsTableAnnotationComposer get itemId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.itemId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$SuppliersTableAnnotationComposer get supplierId {
    final $$SuppliersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SuppliersTableAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PriceHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PriceHistoryTable,
          PriceHistoryData,
          $$PriceHistoryTableFilterComposer,
          $$PriceHistoryTableOrderingComposer,
          $$PriceHistoryTableAnnotationComposer,
          $$PriceHistoryTableCreateCompanionBuilder,
          $$PriceHistoryTableUpdateCompanionBuilder,
          (PriceHistoryData, $$PriceHistoryTableReferences),
          PriceHistoryData,
          PrefetchHooks Function({bool itemId, bool supplierId})
        > {
  $$PriceHistoryTableTableManager(_$AppDatabase db, $PriceHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PriceHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PriceHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PriceHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> itemId = const Value.absent(),
                Value<double> price = const Value.absent(),
                Value<double> vatRate = const Value.absent(),
                Value<DateTime> receiptDate = const Value.absent(),
                Value<int> supplierId = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PriceHistoryCompanion(
                id: id,
                uuid: uuid,
                itemId: itemId,
                price: price,
                vatRate: vatRate,
                receiptDate: receiptDate,
                supplierId: supplierId,
                quantity: quantity,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int itemId,
                required double price,
                Value<double> vatRate = const Value.absent(),
                required DateTime receiptDate,
                required int supplierId,
                Value<double> quantity = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
              }) => PriceHistoryCompanion.insert(
                id: id,
                uuid: uuid,
                itemId: itemId,
                price: price,
                vatRate: vatRate,
                receiptDate: receiptDate,
                supplierId: supplierId,
                quantity: quantity,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PriceHistoryTable, PriceHistoryData>(table),
                  $$PriceHistoryTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({itemId = false, supplierId = false}) {
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
                    if (itemId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.itemId,
                        referencedTable: $$PriceHistoryTableReferences
                            ._itemIdTable(db),
                        referencedColumn: $$PriceHistoryTableReferences
                            ._itemIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (supplierId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.supplierId,
                        referencedTable: $$PriceHistoryTableReferences
                            ._supplierIdTable(db),
                        referencedColumn: $$PriceHistoryTableReferences
                            ._supplierIdTable(db)
                            .id,
                      ) as T;
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

typedef $$PriceHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PriceHistoryTable,
      PriceHistoryData,
      $$PriceHistoryTableFilterComposer,
      $$PriceHistoryTableOrderingComposer,
      $$PriceHistoryTableAnnotationComposer,
      $$PriceHistoryTableCreateCompanionBuilder,
      $$PriceHistoryTableUpdateCompanionBuilder,
      (PriceHistoryData, $$PriceHistoryTableReferences),
      PriceHistoryData,
      PrefetchHooks Function({bool itemId, bool supplierId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required int categoryId,
  required int month,
  required int year,
  required double amount,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<int> categoryId,
  Value<int> month,
  Value<int> year,
  Value<double> amount,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<int>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
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

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> categoryId = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                uuid: uuid,
                categoryId: categoryId,
                month: month,
                year: year,
                amount: amount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required int categoryId,
                required int month,
                required int year,
                required double amount,
                Value<String?> notes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => BudgetsCompanion.insert(
                id: id,
                uuid: uuid,
                categoryId: categoryId,
                month: month,
                year: year,
                amount: amount,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
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

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  required String name,
  Value<String?> color,
  required DateTime createdAt,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<int> id,
  Value<String> uuid,
  Value<String> name,
  Value<String?> color,
  Value<DateTime> createdAt,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, Tag> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptTagsTable, List<ReceiptTag>>
  _receiptTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.receiptTags,
    aliasName: 'tags__id__receipt_tags__tag_id',
  );

  $$ReceiptTagsTableProcessedTableManager get receiptTagsRefs {
    final manager = $$ReceiptTagsTableTableManager(
      $_db,
      $_db.receiptTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_receiptTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
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

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  Expression<bool> receiptTagsRefs(
    Expression<bool> Function($$ReceiptTagsTableFilterComposer f) f,
  ) {
    final $$ReceiptTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptTagsTableFilterComposer(
            $db: $db,
            $table: $db.receiptTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
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

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> receiptTagsRefs<T extends Object>(
    Expression<T> Function($$ReceiptTagsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.receiptTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          Tag,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (Tag, $$TagsTableReferences),
          Tag,
          PrefetchHooks Function({bool receiptTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                uuid: uuid,
                name: name,
                color: color,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String name,
                Value<String?> color = const Value.absent(),
                required DateTime createdAt,
              }) => TagsCompanion.insert(
                id: id,
                uuid: uuid,
                name: name,
                color: color,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, Tag>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (receiptTagsRefs) db.receiptTags],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (receiptTagsRefs)
                    await $_getPrefetchedData<Tag, $TagsTable, ReceiptTag>(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences
                          ._receiptTagsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).receiptTagsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.tagId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      Tag,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (Tag, $$TagsTableReferences),
      Tag,
      PrefetchHooks Function({bool receiptTagsRefs})
    >;
typedef $$ReceiptTagsTableCreateCompanionBuilder =
    ReceiptTagsCompanion Function({
      required int receiptId,
      required int tagId,
      Value<int> rowid,
    });
typedef $$ReceiptTagsTableUpdateCompanionBuilder =
    ReceiptTagsCompanion Function({
      Value<int> receiptId,
      Value<int> tagId,
      Value<int> rowid,
    });

final class $$ReceiptTagsTableReferences
    extends BaseReferences<_$AppDatabase, $ReceiptTagsTable, ReceiptTag> {
  $$ReceiptTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ReceiptsTable _receiptIdTable(_$AppDatabase db) =>
      db.receipts.createAlias('receipt_tags__receipt_id__receipts__id');

  $$ReceiptsTableProcessedTableManager get receiptId {
    final $_column = $_itemColumn<int>('receipt_id')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('receipt_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<int>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptTagsTableFilterComposer
    extends Composer<_$AppDatabase, $ReceiptTagsTable> {
  $$ReceiptTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ReceiptsTableFilterComposer get receiptId {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReceiptTagsTable> {
  $$ReceiptTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ReceiptsTableOrderingComposer get receiptId {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReceiptTagsTable> {
  $$ReceiptTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$ReceiptsTableAnnotationComposer get receiptId {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptId,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReceiptTagsTable,
          ReceiptTag,
          $$ReceiptTagsTableFilterComposer,
          $$ReceiptTagsTableOrderingComposer,
          $$ReceiptTagsTableAnnotationComposer,
          $$ReceiptTagsTableCreateCompanionBuilder,
          $$ReceiptTagsTableUpdateCompanionBuilder,
          (ReceiptTag, $$ReceiptTagsTableReferences),
          ReceiptTag,
          PrefetchHooks Function({bool receiptId, bool tagId})
        > {
  $$ReceiptTagsTableTableManager(_$AppDatabase db, $ReceiptTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> receiptId = const Value.absent(),
                Value<int> tagId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptTagsCompanion(
                receiptId: receiptId,
                tagId: tagId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int receiptId,
                required int tagId,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptTagsCompanion.insert(
                receiptId: receiptId,
                tagId: tagId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ReceiptTagsTable, ReceiptTag>(table),
                  $$ReceiptTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptId = false, tagId = false}) {
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
                    if (receiptId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.receiptId,
                        referencedTable: $$ReceiptTagsTableReferences
                            ._receiptIdTable(db),
                        referencedColumn: $$ReceiptTagsTableReferences
                            ._receiptIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$ReceiptTagsTableReferences
                            ._tagIdTable(db),
                        referencedColumn: $$ReceiptTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ReceiptTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReceiptTagsTable,
      ReceiptTag,
      $$ReceiptTagsTableFilterComposer,
      $$ReceiptTagsTableOrderingComposer,
      $$ReceiptTagsTableAnnotationComposer,
      $$ReceiptTagsTableCreateCompanionBuilder,
      $$ReceiptTagsTableUpdateCompanionBuilder,
      (ReceiptTag, $$ReceiptTagsTableReferences),
      ReceiptTag,
      PrefetchHooks Function({bool receiptId, bool tagId})
    >;
typedef $$UserSettingsTableCreateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      required String key,
      Value<String?> value,
      Value<String> type,
      required DateTime updatedAt,
    });
typedef $$UserSettingsTableUpdateCompanionBuilder =
    UserSettingsCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String?> value,
      Value<String> type,
      Value<DateTime> updatedAt,
    });

class $$UserSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableFilterComposer({
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

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$UserSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableOrderingComposer({
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

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserSettingsTable> {
  $$UserSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserSettingsTable,
          UserSetting,
          $$UserSettingsTableFilterComposer,
          $$UserSettingsTableOrderingComposer,
          $$UserSettingsTableAnnotationComposer,
          $$UserSettingsTableCreateCompanionBuilder,
          $$UserSettingsTableUpdateCompanionBuilder,
          (
            UserSetting,
            BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
          ),
          UserSetting,
          PrefetchHooks Function()
        > {
  $$UserSettingsTableTableManager(_$AppDatabase db, $UserSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserSettingsCompanion(
                id: id,
                key: key,
                value: value,
                type: type,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                Value<String?> value = const Value.absent(),
                Value<String> type = const Value.absent(),
                required DateTime updatedAt,
              }) => UserSettingsCompanion.insert(
                id: id,
                key: key,
                value: value,
                type: type,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserSettingsTable, UserSetting>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $UserSettingsTable,
                    UserSetting
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserSettingsTable,
      UserSetting,
      $$UserSettingsTableFilterComposer,
      $$UserSettingsTableOrderingComposer,
      $$UserSettingsTableAnnotationComposer,
      $$UserSettingsTableCreateCompanionBuilder,
      $$UserSettingsTableUpdateCompanionBuilder,
      (
        UserSetting,
        BaseReferences<_$AppDatabase, $UserSettingsTable, UserSetting>,
      ),
      UserSetting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db, _db.suppliers);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceiptItemsTableTableManager get receiptItems =>
      $$ReceiptItemsTableTableManager(_db, _db.receiptItems);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$PriceHistoryTableTableManager get priceHistory =>
      $$PriceHistoryTableTableManager(_db, _db.priceHistory);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$ReceiptTagsTableTableManager get receiptTags =>
      $$ReceiptTagsTableTableManager(_db, _db.receiptTags);
  $$UserSettingsTableTableManager get userSettings =>
      $$UserSettingsTableTableManager(_db, _db.userSettings);
}
