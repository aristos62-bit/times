// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'item_search_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ItemSearchState {

 String get query; ItemSearchStatus get status; List<Item> get results; Item? get selectedItem; bool get errorOccurred;
/// Create a copy of ItemSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemSearchStateCopyWith<ItemSearchState> get copyWith => _$ItemSearchStateCopyWithImpl<ItemSearchState>(this as ItemSearchState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ItemSearchState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemSearchState&&(identical(other.query, _this.query) || other.query == _this.query)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.results, _this.results)&&const DeepCollectionEquality().equals(other.selectedItem, _this.selectedItem)&&(identical(other.errorOccurred, _this.errorOccurred) || other.errorOccurred == _this.errorOccurred));
}


@override
int get hashCode {
  final _this = this as ItemSearchState;
  return Object.hash(runtimeType,_this.query,_this.status,const DeepCollectionEquality().hash(_this.results),const DeepCollectionEquality().hash(_this.selectedItem),_this.errorOccurred);
}

@override
String toString() {
  final _this = this as ItemSearchState;
  return 'ItemSearchState(query: ${_this.query}, status: ${_this.status}, results: ${_this.results}, selectedItem: ${_this.selectedItem}, errorOccurred: ${_this.errorOccurred})';
}


}

/// @nodoc
abstract mixin class $ItemSearchStateCopyWith<$Res>  {
  factory $ItemSearchStateCopyWith(ItemSearchState value, $Res Function(ItemSearchState) _then) = _$ItemSearchStateCopyWithImpl;
@useResult
$Res call({
 String query, ItemSearchStatus status, List<Item> results, Item? selectedItem, bool errorOccurred
});




}
/// @nodoc
class _$ItemSearchStateCopyWithImpl<$Res>
    implements $ItemSearchStateCopyWith<$Res> {
  _$ItemSearchStateCopyWithImpl(this._self, this._then);

  final ItemSearchState _self;
  final $Res Function(ItemSearchState) _then;

/// Create a copy of ItemSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? status = null,Object? results = null,Object? selectedItem = freezed,Object? errorOccurred = null,}) {
  return _then(ItemSearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ItemSearchStatus,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<Item>,selectedItem: freezed == selectedItem ? _self.selectedItem : selectedItem // ignore: cast_nullable_to_non_nullable
as Item?,errorOccurred: null == errorOccurred ? _self.errorOccurred : errorOccurred // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ItemSearchState].
extension ItemSearchStatePatterns on ItemSearchState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ItemSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ItemSearchState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ItemSearchState value)  $default,){
final _that = this;
switch (_that) {
case _ItemSearchState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ItemSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _ItemSearchState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  ItemSearchStatus status,  List<Item> results,  Item? selectedItem,  bool errorOccurred)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ItemSearchState() when $default != null:
return $default(_that.query,_that.status,_that.results,_that.selectedItem,_that.errorOccurred);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  ItemSearchStatus status,  List<Item> results,  Item? selectedItem,  bool errorOccurred)  $default,) {final _that = this;
switch (_that) {
case _ItemSearchState():
return $default(_that.query,_that.status,_that.results,_that.selectedItem,_that.errorOccurred);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  ItemSearchStatus status,  List<Item> results,  Item? selectedItem,  bool errorOccurred)?  $default,) {final _that = this;
switch (_that) {
case _ItemSearchState() when $default != null:
return $default(_that.query,_that.status,_that.results,_that.selectedItem,_that.errorOccurred);case _:
  return null;

}
}

}

/// @nodoc


class _ItemSearchState implements ItemSearchState {
  const _ItemSearchState({this.query = '', this.status = ItemSearchStatus.idle,  List<Item> results = const <Item>[], this.selectedItem, this.errorOccurred = false}): _results = results;
  

@override@JsonKey() final  String query;
@override@JsonKey() final  ItemSearchStatus status;
 final  List<Item> _results;
@override@JsonKey() List<Item> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}

@override final  Item? selectedItem;
@override@JsonKey() final  bool errorOccurred;

/// Create a copy of ItemSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ItemSearchStateCopyWith<_ItemSearchState> get copyWith => __$ItemSearchStateCopyWithImpl<_ItemSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ItemSearchState&&(identical(other.query, query) || other.query == query)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.results, _results)&&const DeepCollectionEquality().equals(other.selectedItem, selectedItem)&&(identical(other.errorOccurred, errorOccurred) || other.errorOccurred == errorOccurred));
}


@override
int get hashCode {
    return Object.hash(runtimeType,query,status,const DeepCollectionEquality().hash(_results),const DeepCollectionEquality().hash(selectedItem),errorOccurred);
}

@override
String toString() {
    return 'ItemSearchState(query: $query, status: $status, results: $results, selectedItem: $selectedItem, errorOccurred: $errorOccurred)';
}


}

/// @nodoc
abstract mixin class _$ItemSearchStateCopyWith<$Res> implements $ItemSearchStateCopyWith<$Res> {
  factory _$ItemSearchStateCopyWith(_ItemSearchState value, $Res Function(_ItemSearchState) _then) = __$ItemSearchStateCopyWithImpl;
@override @useResult
$Res call({
 String query, ItemSearchStatus status, List<Item> results, Item? selectedItem, bool errorOccurred
});




}
/// @nodoc
class __$ItemSearchStateCopyWithImpl<$Res>
    implements _$ItemSearchStateCopyWith<$Res> {
  __$ItemSearchStateCopyWithImpl(this._self, this._then);

  final _ItemSearchState _self;
  final $Res Function(_ItemSearchState) _then;

/// Create a copy of ItemSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? status = null,Object? results = null,Object? selectedItem = freezed,Object? errorOccurred = null,}) {
  return _then(_ItemSearchState(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ItemSearchStatus,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<Item>,selectedItem: freezed == selectedItem ? _self.selectedItem : selectedItem // ignore: cast_nullable_to_non_nullable
as Item?,errorOccurred: null == errorOccurred ? _self.errorOccurred : errorOccurred // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
