// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_form_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ReceiptFormState {

 DateTime get date;
/// Create a copy of ReceiptFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReceiptFormStateCopyWith<ReceiptFormState> get copyWith => _$ReceiptFormStateCopyWithImpl<ReceiptFormState>(this as ReceiptFormState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ReceiptFormState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReceiptFormState&&(identical(other.date, _this.date) || other.date == _this.date));
}


@override
int get hashCode {
  final _this = this as ReceiptFormState;
  return Object.hash(runtimeType,_this.date);
}

@override
String toString() {
  final _this = this as ReceiptFormState;
  return 'ReceiptFormState(date: ${_this.date})';
}


}

/// @nodoc
abstract mixin class $ReceiptFormStateCopyWith<$Res>  {
  factory $ReceiptFormStateCopyWith(ReceiptFormState value, $Res Function(ReceiptFormState) _then) = _$ReceiptFormStateCopyWithImpl;
@useResult
$Res call({
 DateTime date
});




}
/// @nodoc
class _$ReceiptFormStateCopyWithImpl<$Res>
    implements $ReceiptFormStateCopyWith<$Res> {
  _$ReceiptFormStateCopyWithImpl(this._self, this._then);

  final ReceiptFormState _self;
  final $Res Function(ReceiptFormState) _then;

/// Create a copy of ReceiptFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,}) {
  return _then(ReceiptFormState(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ReceiptFormState].
extension ReceiptFormStatePatterns on ReceiptFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReceiptFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReceiptFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReceiptFormState value)  $default,){
final _that = this;
switch (_that) {
case _ReceiptFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReceiptFormState value)?  $default,){
final _that = this;
switch (_that) {
case _ReceiptFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReceiptFormState() when $default != null:
return $default(_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date)  $default,) {final _that = this;
switch (_that) {
case _ReceiptFormState():
return $default(_that.date);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date)?  $default,) {final _that = this;
switch (_that) {
case _ReceiptFormState() when $default != null:
return $default(_that.date);case _:
  return null;

}
}

}

/// @nodoc


class _ReceiptFormState implements ReceiptFormState {
  const _ReceiptFormState({required this.date});
  

@override final  DateTime date;

/// Create a copy of ReceiptFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReceiptFormStateCopyWith<_ReceiptFormState> get copyWith => __$ReceiptFormStateCopyWithImpl<_ReceiptFormState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReceiptFormState&&(identical(other.date, date) || other.date == date));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date);
}

@override
String toString() {
    return 'ReceiptFormState(date: $date)';
}


}

/// @nodoc
abstract mixin class _$ReceiptFormStateCopyWith<$Res> implements $ReceiptFormStateCopyWith<$Res> {
  factory _$ReceiptFormStateCopyWith(_ReceiptFormState value, $Res Function(_ReceiptFormState) _then) = __$ReceiptFormStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime date
});




}
/// @nodoc
class __$ReceiptFormStateCopyWithImpl<$Res>
    implements _$ReceiptFormStateCopyWith<$Res> {
  __$ReceiptFormStateCopyWithImpl(this._self, this._then);

  final _ReceiptFormState _self;
  final $Res Function(_ReceiptFormState) _then;

/// Create a copy of ReceiptFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,}) {
  return _then(_ReceiptFormState(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
