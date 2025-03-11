// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatListState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Convo> chats) data,
    required TResult Function(String? error) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Convo> chats)? data,
    TResult? Function(String? error)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Convo> chats)? data,
    TResult Function(String? error)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ChatListStateInitial value) initial,
    required TResult Function(_ChatListStateLoading value) loading,
    required TResult Function(_ChatListStateData value) data,
    required TResult Function(_ChatListStateError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ChatListStateInitial value)? initial,
    TResult? Function(_ChatListStateLoading value)? loading,
    TResult? Function(_ChatListStateData value)? data,
    TResult? Function(_ChatListStateError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ChatListStateInitial value)? initial,
    TResult Function(_ChatListStateLoading value)? loading,
    TResult Function(_ChatListStateData value)? data,
    TResult Function(_ChatListStateError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatListStateCopyWith<$Res> {
  factory $ChatListStateCopyWith(
    ChatListState value,
    $Res Function(ChatListState) then,
  ) = _$ChatListStateCopyWithImpl<$Res, ChatListState>;
}

/// @nodoc
class _$ChatListStateCopyWithImpl<$Res, $Val extends ChatListState>
    implements $ChatListStateCopyWith<$Res> {
  _$ChatListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$ChatListStateInitialImplCopyWith<$Res> {
  factory _$$ChatListStateInitialImplCopyWith(
    _$ChatListStateInitialImpl value,
    $Res Function(_$ChatListStateInitialImpl) then,
  ) = __$$ChatListStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChatListStateInitialImplCopyWithImpl<$Res>
    extends _$ChatListStateCopyWithImpl<$Res, _$ChatListStateInitialImpl>
    implements _$$ChatListStateInitialImplCopyWith<$Res> {
  __$$ChatListStateInitialImplCopyWithImpl(
    _$ChatListStateInitialImpl _value,
    $Res Function(_$ChatListStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ChatListStateInitialImpl implements _ChatListStateInitial {
  const _$ChatListStateInitialImpl();

  @override
  String toString() {
    return 'ChatListState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatListStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Convo> chats) data,
    required TResult Function(String? error) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Convo> chats)? data,
    TResult? Function(String? error)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Convo> chats)? data,
    TResult Function(String? error)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ChatListStateInitial value) initial,
    required TResult Function(_ChatListStateLoading value) loading,
    required TResult Function(_ChatListStateData value) data,
    required TResult Function(_ChatListStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ChatListStateInitial value)? initial,
    TResult? Function(_ChatListStateLoading value)? loading,
    TResult? Function(_ChatListStateData value)? data,
    TResult? Function(_ChatListStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ChatListStateInitial value)? initial,
    TResult Function(_ChatListStateLoading value)? loading,
    TResult Function(_ChatListStateData value)? data,
    TResult Function(_ChatListStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _ChatListStateInitial implements ChatListState {
  const factory _ChatListStateInitial() = _$ChatListStateInitialImpl;
}

/// @nodoc
abstract class _$$ChatListStateLoadingImplCopyWith<$Res> {
  factory _$$ChatListStateLoadingImplCopyWith(
    _$ChatListStateLoadingImpl value,
    $Res Function(_$ChatListStateLoadingImpl) then,
  ) = __$$ChatListStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChatListStateLoadingImplCopyWithImpl<$Res>
    extends _$ChatListStateCopyWithImpl<$Res, _$ChatListStateLoadingImpl>
    implements _$$ChatListStateLoadingImplCopyWith<$Res> {
  __$$ChatListStateLoadingImplCopyWithImpl(
    _$ChatListStateLoadingImpl _value,
    $Res Function(_$ChatListStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$ChatListStateLoadingImpl implements _ChatListStateLoading {
  const _$ChatListStateLoadingImpl();

  @override
  String toString() {
    return 'ChatListState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatListStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Convo> chats) data,
    required TResult Function(String? error) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Convo> chats)? data,
    TResult? Function(String? error)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Convo> chats)? data,
    TResult Function(String? error)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ChatListStateInitial value) initial,
    required TResult Function(_ChatListStateLoading value) loading,
    required TResult Function(_ChatListStateData value) data,
    required TResult Function(_ChatListStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ChatListStateInitial value)? initial,
    TResult? Function(_ChatListStateLoading value)? loading,
    TResult? Function(_ChatListStateData value)? data,
    TResult? Function(_ChatListStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ChatListStateInitial value)? initial,
    TResult Function(_ChatListStateLoading value)? loading,
    TResult Function(_ChatListStateData value)? data,
    TResult Function(_ChatListStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _ChatListStateLoading implements ChatListState {
  const factory _ChatListStateLoading() = _$ChatListStateLoadingImpl;
}

/// @nodoc
abstract class _$$ChatListStateDataImplCopyWith<$Res> {
  factory _$$ChatListStateDataImplCopyWith(
    _$ChatListStateDataImpl value,
    $Res Function(_$ChatListStateDataImpl) then,
  ) = __$$ChatListStateDataImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<Convo> chats});
}

/// @nodoc
class __$$ChatListStateDataImplCopyWithImpl<$Res>
    extends _$ChatListStateCopyWithImpl<$Res, _$ChatListStateDataImpl>
    implements _$$ChatListStateDataImplCopyWith<$Res> {
  __$$ChatListStateDataImplCopyWithImpl(
    _$ChatListStateDataImpl _value,
    $Res Function(_$ChatListStateDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? chats = null}) {
    return _then(
      _$ChatListStateDataImpl(
        chats:
            null == chats
                ? _value._chats
                : chats // ignore: cast_nullable_to_non_nullable
                    as List<Convo>,
      ),
    );
  }
}

/// @nodoc

class _$ChatListStateDataImpl implements _ChatListStateData {
  const _$ChatListStateDataImpl({required final List<Convo> chats})
    : _chats = chats;

  final List<Convo> _chats;
  @override
  List<Convo> get chats {
    if (_chats is EqualUnmodifiableListView) return _chats;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_chats);
  }

  @override
  String toString() {
    return 'ChatListState.data(chats: $chats)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatListStateDataImpl &&
            const DeepCollectionEquality().equals(other._chats, _chats));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_chats));

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatListStateDataImplCopyWith<_$ChatListStateDataImpl> get copyWith =>
      __$$ChatListStateDataImplCopyWithImpl<_$ChatListStateDataImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Convo> chats) data,
    required TResult Function(String? error) error,
  }) {
    return data(chats);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Convo> chats)? data,
    TResult? Function(String? error)? error,
  }) {
    return data?.call(chats);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Convo> chats)? data,
    TResult Function(String? error)? error,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(chats);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ChatListStateInitial value) initial,
    required TResult Function(_ChatListStateLoading value) loading,
    required TResult Function(_ChatListStateData value) data,
    required TResult Function(_ChatListStateError value) error,
  }) {
    return data(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ChatListStateInitial value)? initial,
    TResult? Function(_ChatListStateLoading value)? loading,
    TResult? Function(_ChatListStateData value)? data,
    TResult? Function(_ChatListStateError value)? error,
  }) {
    return data?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ChatListStateInitial value)? initial,
    TResult Function(_ChatListStateLoading value)? loading,
    TResult Function(_ChatListStateData value)? data,
    TResult Function(_ChatListStateError value)? error,
    required TResult orElse(),
  }) {
    if (data != null) {
      return data(this);
    }
    return orElse();
  }
}

abstract class _ChatListStateData implements ChatListState {
  const factory _ChatListStateData({required final List<Convo> chats}) =
      _$ChatListStateDataImpl;

  List<Convo> get chats;

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatListStateDataImplCopyWith<_$ChatListStateDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatListStateErrorImplCopyWith<$Res> {
  factory _$$ChatListStateErrorImplCopyWith(
    _$ChatListStateErrorImpl value,
    $Res Function(_$ChatListStateErrorImpl) then,
  ) = __$$ChatListStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? error});
}

/// @nodoc
class __$$ChatListStateErrorImplCopyWithImpl<$Res>
    extends _$ChatListStateCopyWithImpl<$Res, _$ChatListStateErrorImpl>
    implements _$$ChatListStateErrorImplCopyWith<$Res> {
  __$$ChatListStateErrorImplCopyWithImpl(
    _$ChatListStateErrorImpl _value,
    $Res Function(_$ChatListStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? error = freezed}) {
    return _then(
      _$ChatListStateErrorImpl(
        freezed == error
            ? _value.error
            : error // ignore: cast_nullable_to_non_nullable
                as String?,
      ),
    );
  }
}

/// @nodoc

class _$ChatListStateErrorImpl implements _ChatListStateError {
  const _$ChatListStateErrorImpl([this.error]);

  @override
  final String? error;

  @override
  String toString() {
    return 'ChatListState.error(error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatListStateErrorImpl &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, error);

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatListStateErrorImplCopyWith<_$ChatListStateErrorImpl> get copyWith =>
      __$$ChatListStateErrorImplCopyWithImpl<_$ChatListStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<Convo> chats) data,
    required TResult Function(String? error) error,
  }) {
    return error(this.error);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<Convo> chats)? data,
    TResult? Function(String? error)? error,
  }) {
    return error?.call(this.error);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<Convo> chats)? data,
    TResult Function(String? error)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this.error);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_ChatListStateInitial value) initial,
    required TResult Function(_ChatListStateLoading value) loading,
    required TResult Function(_ChatListStateData value) data,
    required TResult Function(_ChatListStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_ChatListStateInitial value)? initial,
    TResult? Function(_ChatListStateLoading value)? loading,
    TResult? Function(_ChatListStateData value)? data,
    TResult? Function(_ChatListStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_ChatListStateInitial value)? initial,
    TResult Function(_ChatListStateLoading value)? loading,
    TResult Function(_ChatListStateData value)? data,
    TResult Function(_ChatListStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _ChatListStateError implements ChatListState {
  const factory _ChatListStateError([final String? error]) =
      _$ChatListStateErrorImpl;

  String? get error;

  /// Create a copy of ChatListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatListStateErrorImplCopyWith<_$ChatListStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
