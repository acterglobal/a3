// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, override_on_non_overriding_member
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'failure.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$Failure {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) unprocessableEntity,
    required TResult Function() unauthorized,
    required TResult Function() badRequest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? unprocessableEntity,
    TResult? Function()? unauthorized,
    TResult? Function()? badRequest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? unprocessableEntity,
    TResult Function()? unauthorized,
    TResult Function()? badRequest,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EmptyFailure value) empty,
    required TResult Function(_UnprocessableEntityFailure value)
        unprocessableEntity,
    required TResult Function(_UnauthorizedFailure value) unauthorized,
    required TResult Function(_BadRequestFailure value) badRequest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EmptyFailure value)? empty,
    TResult? Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult? Function(_UnauthorizedFailure value)? unauthorized,
    TResult? Function(_BadRequestFailure value)? badRequest,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EmptyFailure value)? empty,
    TResult Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult Function(_UnauthorizedFailure value)? unauthorized,
    TResult Function(_BadRequestFailure value)? badRequest,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FailureCopyWith<$Res> {
  factory $FailureCopyWith(Failure value, $Res Function(Failure) then) =
      _$FailureCopyWithImpl<$Res, Failure>;
}

/// @nodoc
class _$FailureCopyWithImpl<$Res, $Val extends Failure>
    implements $FailureCopyWith<$Res> {
  _$FailureCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$_EmptyFailureCopyWith<$Res> {
  factory _$$_EmptyFailureCopyWith(
          _$_EmptyFailure value, $Res Function(_$_EmptyFailure) then) =
      __$$_EmptyFailureCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_EmptyFailureCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$_EmptyFailure>
    implements _$$_EmptyFailureCopyWith<$Res> {
  __$$_EmptyFailureCopyWithImpl(
      _$_EmptyFailure _value, $Res Function(_$_EmptyFailure) _then)
      : super(_value, _then);
}

/// @nodoc

class _$_EmptyFailure extends _EmptyFailure {
  const _$_EmptyFailure() : super._();

  @override
  String toString() {
    return 'Failure.empty()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_EmptyFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) unprocessableEntity,
    required TResult Function() unauthorized,
    required TResult Function() badRequest,
  }) {
    return empty();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? unprocessableEntity,
    TResult? Function()? unauthorized,
    TResult? Function()? badRequest,
  }) {
    return empty?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? unprocessableEntity,
    TResult Function()? unauthorized,
    TResult Function()? badRequest,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EmptyFailure value) empty,
    required TResult Function(_UnprocessableEntityFailure value)
        unprocessableEntity,
    required TResult Function(_UnauthorizedFailure value) unauthorized,
    required TResult Function(_BadRequestFailure value) badRequest,
  }) {
    return empty(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EmptyFailure value)? empty,
    TResult? Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult? Function(_UnauthorizedFailure value)? unauthorized,
    TResult? Function(_BadRequestFailure value)? badRequest,
  }) {
    return empty?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EmptyFailure value)? empty,
    TResult Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult Function(_UnauthorizedFailure value)? unauthorized,
    TResult Function(_BadRequestFailure value)? badRequest,
    required TResult orElse(),
  }) {
    if (empty != null) {
      return empty(this);
    }
    return orElse();
  }
}

abstract class _EmptyFailure extends Failure {
  const factory _EmptyFailure() = _$_EmptyFailure;
  const _EmptyFailure._() : super._();
}

/// @nodoc
abstract class _$$_UnprocessableEntityFailureCopyWith<$Res> {
  factory _$$_UnprocessableEntityFailureCopyWith(
          _$_UnprocessableEntityFailure value,
          $Res Function(_$_UnprocessableEntityFailure) then) =
      __$$_UnprocessableEntityFailureCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$_UnprocessableEntityFailureCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$_UnprocessableEntityFailure>
    implements _$$_UnprocessableEntityFailureCopyWith<$Res> {
  __$$_UnprocessableEntityFailureCopyWithImpl(
      _$_UnprocessableEntityFailure _value,
      $Res Function(_$_UnprocessableEntityFailure) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$_UnprocessableEntityFailure(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$_UnprocessableEntityFailure extends _UnprocessableEntityFailure {
  const _$_UnprocessableEntityFailure({required this.message}) : super._();

  @override
  final String message;

  @override
  String toString() {
    return 'Failure.unprocessableEntity(message: $message)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_UnprocessableEntityFailure &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_UnprocessableEntityFailureCopyWith<_$_UnprocessableEntityFailure>
      get copyWith => __$$_UnprocessableEntityFailureCopyWithImpl<
          _$_UnprocessableEntityFailure>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) unprocessableEntity,
    required TResult Function() unauthorized,
    required TResult Function() badRequest,
  }) {
    return unprocessableEntity(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? unprocessableEntity,
    TResult? Function()? unauthorized,
    TResult? Function()? badRequest,
  }) {
    return unprocessableEntity?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? unprocessableEntity,
    TResult Function()? unauthorized,
    TResult Function()? badRequest,
    required TResult orElse(),
  }) {
    if (unprocessableEntity != null) {
      return unprocessableEntity(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EmptyFailure value) empty,
    required TResult Function(_UnprocessableEntityFailure value)
        unprocessableEntity,
    required TResult Function(_UnauthorizedFailure value) unauthorized,
    required TResult Function(_BadRequestFailure value) badRequest,
  }) {
    return unprocessableEntity(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EmptyFailure value)? empty,
    TResult? Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult? Function(_UnauthorizedFailure value)? unauthorized,
    TResult? Function(_BadRequestFailure value)? badRequest,
  }) {
    return unprocessableEntity?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EmptyFailure value)? empty,
    TResult Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult Function(_UnauthorizedFailure value)? unauthorized,
    TResult Function(_BadRequestFailure value)? badRequest,
    required TResult orElse(),
  }) {
    if (unprocessableEntity != null) {
      return unprocessableEntity(this);
    }
    return orElse();
  }
}

abstract class _UnprocessableEntityFailure extends Failure {
  const factory _UnprocessableEntityFailure({required final String message}) =
      _$_UnprocessableEntityFailure;
  const _UnprocessableEntityFailure._() : super._();

  String get message;
  @JsonKey(ignore: true)
  _$$_UnprocessableEntityFailureCopyWith<_$_UnprocessableEntityFailure>
      get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$_UnauthorizedFailureCopyWith<$Res> {
  factory _$$_UnauthorizedFailureCopyWith(_$_UnauthorizedFailure value,
          $Res Function(_$_UnauthorizedFailure) then) =
      __$$_UnauthorizedFailureCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_UnauthorizedFailureCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$_UnauthorizedFailure>
    implements _$$_UnauthorizedFailureCopyWith<$Res> {
  __$$_UnauthorizedFailureCopyWithImpl(_$_UnauthorizedFailure _value,
      $Res Function(_$_UnauthorizedFailure) _then)
      : super(_value, _then);
}

/// @nodoc

class _$_UnauthorizedFailure extends _UnauthorizedFailure {
  const _$_UnauthorizedFailure() : super._();

  @override
  String toString() {
    return 'Failure.unauthorized()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_UnauthorizedFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) unprocessableEntity,
    required TResult Function() unauthorized,
    required TResult Function() badRequest,
  }) {
    return unauthorized();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? unprocessableEntity,
    TResult? Function()? unauthorized,
    TResult? Function()? badRequest,
  }) {
    return unauthorized?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? unprocessableEntity,
    TResult Function()? unauthorized,
    TResult Function()? badRequest,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EmptyFailure value) empty,
    required TResult Function(_UnprocessableEntityFailure value)
        unprocessableEntity,
    required TResult Function(_UnauthorizedFailure value) unauthorized,
    required TResult Function(_BadRequestFailure value) badRequest,
  }) {
    return unauthorized(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EmptyFailure value)? empty,
    TResult? Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult? Function(_UnauthorizedFailure value)? unauthorized,
    TResult? Function(_BadRequestFailure value)? badRequest,
  }) {
    return unauthorized?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EmptyFailure value)? empty,
    TResult Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult Function(_UnauthorizedFailure value)? unauthorized,
    TResult Function(_BadRequestFailure value)? badRequest,
    required TResult orElse(),
  }) {
    if (unauthorized != null) {
      return unauthorized(this);
    }
    return orElse();
  }
}

abstract class _UnauthorizedFailure extends Failure {
  const factory _UnauthorizedFailure() = _$_UnauthorizedFailure;
  const _UnauthorizedFailure._() : super._();
}

/// @nodoc
abstract class _$$_BadRequestFailureCopyWith<$Res> {
  factory _$$_BadRequestFailureCopyWith(_$_BadRequestFailure value,
          $Res Function(_$_BadRequestFailure) then) =
      __$$_BadRequestFailureCopyWithImpl<$Res>;
}

/// @nodoc
class __$$_BadRequestFailureCopyWithImpl<$Res>
    extends _$FailureCopyWithImpl<$Res, _$_BadRequestFailure>
    implements _$$_BadRequestFailureCopyWith<$Res> {
  __$$_BadRequestFailureCopyWithImpl(
      _$_BadRequestFailure _value, $Res Function(_$_BadRequestFailure) _then)
      : super(_value, _then);
}

/// @nodoc

class _$_BadRequestFailure extends _BadRequestFailure {
  const _$_BadRequestFailure() : super._();

  @override
  String toString() {
    return 'Failure.badRequest()';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$_BadRequestFailure);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() empty,
    required TResult Function(String message) unprocessableEntity,
    required TResult Function() unauthorized,
    required TResult Function() badRequest,
  }) {
    return badRequest();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? empty,
    TResult? Function(String message)? unprocessableEntity,
    TResult? Function()? unauthorized,
    TResult? Function()? badRequest,
  }) {
    return badRequest?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? empty,
    TResult Function(String message)? unprocessableEntity,
    TResult Function()? unauthorized,
    TResult Function()? badRequest,
    required TResult orElse(),
  }) {
    if (badRequest != null) {
      return badRequest();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_EmptyFailure value) empty,
    required TResult Function(_UnprocessableEntityFailure value)
        unprocessableEntity,
    required TResult Function(_UnauthorizedFailure value) unauthorized,
    required TResult Function(_BadRequestFailure value) badRequest,
  }) {
    return badRequest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_EmptyFailure value)? empty,
    TResult? Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult? Function(_UnauthorizedFailure value)? unauthorized,
    TResult? Function(_BadRequestFailure value)? badRequest,
  }) {
    return badRequest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_EmptyFailure value)? empty,
    TResult Function(_UnprocessableEntityFailure value)? unprocessableEntity,
    TResult Function(_UnauthorizedFailure value)? unauthorized,
    TResult Function(_BadRequestFailure value)? badRequest,
    required TResult orElse(),
  }) {
    if (badRequest != null) {
      return badRequest(this);
    }
    return orElse();
  }
}

abstract class _BadRequestFailure extends Failure {
  const factory _BadRequestFailure() = _$_BadRequestFailure;
  const _BadRequestFailure._() : super._();
}
