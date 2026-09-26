// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_chart_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChartEntry {

 bool get visible; int get order; PeriodType get period; DateTime? get customFrom; DateTime? get customTo;
/// Create a copy of ChartEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<ChartEntry> get copyWith => _$ChartEntryCopyWithImpl<ChartEntry>(this as ChartEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ChartEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartEntry&&(identical(other.visible, _this.visible) || other.visible == _this.visible)&&(identical(other.order, _this.order) || other.order == _this.order)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.customFrom, _this.customFrom) || other.customFrom == _this.customFrom)&&(identical(other.customTo, _this.customTo) || other.customTo == _this.customTo));
}


@override
int get hashCode {
  final _this = this as ChartEntry;
  return Object.hash(runtimeType,_this.visible,_this.order,_this.period,_this.customFrom,_this.customTo);
}

@override
String toString() {
  final _this = this as ChartEntry;
  return 'ChartEntry(visible: ${_this.visible}, order: ${_this.order}, period: ${_this.period}, customFrom: ${_this.customFrom}, customTo: ${_this.customTo})';
}


}

/// @nodoc
abstract mixin class $ChartEntryCopyWith<$Res>  {
  factory $ChartEntryCopyWith(ChartEntry value, $Res Function(ChartEntry) _then) = _$ChartEntryCopyWithImpl;
@useResult
$Res call({
 bool visible, int order, PeriodType period, DateTime? customFrom, DateTime? customTo
});




}
/// @nodoc
class _$ChartEntryCopyWithImpl<$Res>
    implements $ChartEntryCopyWith<$Res> {
  _$ChartEntryCopyWithImpl(this._self, this._then);

  final ChartEntry _self;
  final $Res Function(ChartEntry) _then;

/// Create a copy of ChartEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? visible = null,Object? order = null,Object? period = null,Object? customFrom = freezed,Object? customTo = freezed,}) {
  return _then(ChartEntry(
visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodType,customFrom: freezed == customFrom ? _self.customFrom : customFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,customTo: freezed == customTo ? _self.customTo : customTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartEntry].
extension ChartEntryPatterns on ChartEntry {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartEntry() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartEntry value)  $default,){
final _that = this;
switch (_that) {
case _ChartEntry():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ChartEntry() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool visible,  int order,  PeriodType period,  DateTime? customFrom,  DateTime? customTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartEntry() when $default != null:
return $default(_that.visible,_that.order,_that.period,_that.customFrom,_that.customTo);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool visible,  int order,  PeriodType period,  DateTime? customFrom,  DateTime? customTo)  $default,) {final _that = this;
switch (_that) {
case _ChartEntry():
return $default(_that.visible,_that.order,_that.period,_that.customFrom,_that.customTo);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool visible,  int order,  PeriodType period,  DateTime? customFrom,  DateTime? customTo)?  $default,) {final _that = this;
switch (_that) {
case _ChartEntry() when $default != null:
return $default(_that.visible,_that.order,_that.period,_that.customFrom,_that.customTo);case _:
  return null;

}
}

}

/// @nodoc


class _ChartEntry implements ChartEntry {
  const _ChartEntry({this.visible = true, this.order = 0, this.period = PeriodType.month, this.customFrom, this.customTo});
  

@override@JsonKey() final  bool visible;
@override@JsonKey() final  int order;
@override@JsonKey() final  PeriodType period;
@override final  DateTime? customFrom;
@override final  DateTime? customTo;

/// Create a copy of ChartEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartEntryCopyWith<_ChartEntry> get copyWith => __$ChartEntryCopyWithImpl<_ChartEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartEntry&&(identical(other.visible, visible) || other.visible == visible)&&(identical(other.order, order) || other.order == order)&&(identical(other.period, period) || other.period == period)&&(identical(other.customFrom, customFrom) || other.customFrom == customFrom)&&(identical(other.customTo, customTo) || other.customTo == customTo));
}


@override
int get hashCode {
    return Object.hash(runtimeType,visible,order,period,customFrom,customTo);
}

@override
String toString() {
    return 'ChartEntry(visible: $visible, order: $order, period: $period, customFrom: $customFrom, customTo: $customTo)';
}


}

/// @nodoc
abstract mixin class _$ChartEntryCopyWith<$Res> implements $ChartEntryCopyWith<$Res> {
  factory _$ChartEntryCopyWith(_ChartEntry value, $Res Function(_ChartEntry) _then) = __$ChartEntryCopyWithImpl;
@override @useResult
$Res call({
 bool visible, int order, PeriodType period, DateTime? customFrom, DateTime? customTo
});




}
/// @nodoc
class __$ChartEntryCopyWithImpl<$Res>
    implements _$ChartEntryCopyWith<$Res> {
  __$ChartEntryCopyWithImpl(this._self, this._then);

  final _ChartEntry _self;
  final $Res Function(_ChartEntry) _then;

/// Create a copy of ChartEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? visible = null,Object? order = null,Object? period = null,Object? customFrom = freezed,Object? customTo = freezed,}) {
  return _then(_ChartEntry(
visible: null == visible ? _self.visible : visible // ignore: cast_nullable_to_non_nullable
as bool,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodType,customFrom: freezed == customFrom ? _self.customFrom : customFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,customTo: freezed == customTo ? _self.customTo : customTo // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$HomeChartConfig {

 ChartEntry get supplier; ChartEntry get category; ChartEntry get subCategory; ChartEntry get topItems;
/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeChartConfigCopyWith<HomeChartConfig> get copyWith => _$HomeChartConfigCopyWithImpl<HomeChartConfig>(this as HomeChartConfig, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HomeChartConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeChartConfig&&(identical(other.supplier, _this.supplier) || other.supplier == _this.supplier)&&(identical(other.category, _this.category) || other.category == _this.category)&&(identical(other.subCategory, _this.subCategory) || other.subCategory == _this.subCategory)&&(identical(other.topItems, _this.topItems) || other.topItems == _this.topItems));
}


@override
int get hashCode {
  final _this = this as HomeChartConfig;
  return Object.hash(runtimeType,_this.supplier,_this.category,_this.subCategory,_this.topItems);
}

@override
String toString() {
  final _this = this as HomeChartConfig;
  return 'HomeChartConfig(supplier: ${_this.supplier}, category: ${_this.category}, subCategory: ${_this.subCategory}, topItems: ${_this.topItems})';
}


}

/// @nodoc
abstract mixin class $HomeChartConfigCopyWith<$Res>  {
  factory $HomeChartConfigCopyWith(HomeChartConfig value, $Res Function(HomeChartConfig) _then) = _$HomeChartConfigCopyWithImpl;
@useResult
$Res call({
 ChartEntry supplier, ChartEntry category, ChartEntry subCategory, ChartEntry topItems
});


$ChartEntryCopyWith<$Res> get supplier;$ChartEntryCopyWith<$Res> get category;$ChartEntryCopyWith<$Res> get subCategory;$ChartEntryCopyWith<$Res> get topItems;

}
/// @nodoc
class _$HomeChartConfigCopyWithImpl<$Res>
    implements $HomeChartConfigCopyWith<$Res> {
  _$HomeChartConfigCopyWithImpl(this._self, this._then);

  final HomeChartConfig _self;
  final $Res Function(HomeChartConfig) _then;

/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? supplier = null,Object? category = null,Object? subCategory = null,Object? topItems = null,}) {
  return _then(HomeChartConfig(
supplier: null == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as ChartEntry,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ChartEntry,subCategory: null == subCategory ? _self.subCategory : subCategory // ignore: cast_nullable_to_non_nullable
as ChartEntry,topItems: null == topItems ? _self.topItems : topItems // ignore: cast_nullable_to_non_nullable
as ChartEntry,
  ));
}
/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get supplier {
  
  return $ChartEntryCopyWith<$Res>(_self.supplier, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get category {
  
  return $ChartEntryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get subCategory {
  
  return $ChartEntryCopyWith<$Res>(_self.subCategory, (value) {
    return _then(_self.copyWith(subCategory: value));
  });
}/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get topItems {
  
  return $ChartEntryCopyWith<$Res>(_self.topItems, (value) {
    return _then(_self.copyWith(topItems: value));
  });
}
}


/// Adds pattern-matching-related methods to [HomeChartConfig].
extension HomeChartConfigPatterns on HomeChartConfig {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeChartConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeChartConfig() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeChartConfig value)  $default,){
final _that = this;
switch (_that) {
case _HomeChartConfig():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeChartConfig value)?  $default,){
final _that = this;
switch (_that) {
case _HomeChartConfig() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ChartEntry supplier,  ChartEntry category,  ChartEntry subCategory,  ChartEntry topItems)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeChartConfig() when $default != null:
return $default(_that.supplier,_that.category,_that.subCategory,_that.topItems);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ChartEntry supplier,  ChartEntry category,  ChartEntry subCategory,  ChartEntry topItems)  $default,) {final _that = this;
switch (_that) {
case _HomeChartConfig():
return $default(_that.supplier,_that.category,_that.subCategory,_that.topItems);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ChartEntry supplier,  ChartEntry category,  ChartEntry subCategory,  ChartEntry topItems)?  $default,) {final _that = this;
switch (_that) {
case _HomeChartConfig() when $default != null:
return $default(_that.supplier,_that.category,_that.subCategory,_that.topItems);case _:
  return null;

}
}

}

/// @nodoc


class _HomeChartConfig implements HomeChartConfig {
  const _HomeChartConfig({required this.supplier, required this.category, required this.subCategory, required this.topItems});
  

@override final  ChartEntry supplier;
@override final  ChartEntry category;
@override final  ChartEntry subCategory;
@override final  ChartEntry topItems;

/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeChartConfigCopyWith<_HomeChartConfig> get copyWith => __$HomeChartConfigCopyWithImpl<_HomeChartConfig>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeChartConfig&&(identical(other.supplier, supplier) || other.supplier == supplier)&&(identical(other.category, category) || other.category == category)&&(identical(other.subCategory, subCategory) || other.subCategory == subCategory)&&(identical(other.topItems, topItems) || other.topItems == topItems));
}


@override
int get hashCode {
    return Object.hash(runtimeType,supplier,category,subCategory,topItems);
}

@override
String toString() {
    return 'HomeChartConfig(supplier: $supplier, category: $category, subCategory: $subCategory, topItems: $topItems)';
}


}

/// @nodoc
abstract mixin class _$HomeChartConfigCopyWith<$Res> implements $HomeChartConfigCopyWith<$Res> {
  factory _$HomeChartConfigCopyWith(_HomeChartConfig value, $Res Function(_HomeChartConfig) _then) = __$HomeChartConfigCopyWithImpl;
@override @useResult
$Res call({
 ChartEntry supplier, ChartEntry category, ChartEntry subCategory, ChartEntry topItems
});


@override $ChartEntryCopyWith<$Res> get supplier;@override $ChartEntryCopyWith<$Res> get category;@override $ChartEntryCopyWith<$Res> get subCategory;@override $ChartEntryCopyWith<$Res> get topItems;

}
/// @nodoc
class __$HomeChartConfigCopyWithImpl<$Res>
    implements _$HomeChartConfigCopyWith<$Res> {
  __$HomeChartConfigCopyWithImpl(this._self, this._then);

  final _HomeChartConfig _self;
  final $Res Function(_HomeChartConfig) _then;

/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? supplier = null,Object? category = null,Object? subCategory = null,Object? topItems = null,}) {
  return _then(_HomeChartConfig(
supplier: null == supplier ? _self.supplier : supplier // ignore: cast_nullable_to_non_nullable
as ChartEntry,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ChartEntry,subCategory: null == subCategory ? _self.subCategory : subCategory // ignore: cast_nullable_to_non_nullable
as ChartEntry,topItems: null == topItems ? _self.topItems : topItems // ignore: cast_nullable_to_non_nullable
as ChartEntry,
  ));
}

/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get supplier {
  
  return $ChartEntryCopyWith<$Res>(_self.supplier, (value) {
    return _then(_self.copyWith(supplier: value));
  });
}/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get category {
  
  return $ChartEntryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get subCategory {
  
  return $ChartEntryCopyWith<$Res>(_self.subCategory, (value) {
    return _then(_self.copyWith(subCategory: value));
  });
}/// Create a copy of HomeChartConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChartEntryCopyWith<$Res> get topItems {
  
  return $ChartEntryCopyWith<$Res>(_self.topItems, (value) {
    return _then(_self.copyWith(topItems: value));
  });
}
}

// dart format on
