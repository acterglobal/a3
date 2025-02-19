// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SyncState {
  bool get initialSync => throw _privateConstructorUsedError;
  String? get errorMsg => throw _privateConstructorUsedError;
  int? get countDown => throw _privateConstructorUsedError;
  int? get nextRetry => throw _privateConstructorUsedError;

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SyncStateCopyWith<SyncState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SyncStateCopyWith<$Res> {
  factory $SyncStateCopyWith(SyncState value, $Res Function(SyncState) then) =
      _$SyncStateCopyWithImpl<$Res, SyncState>;
  @useResult
  $Res call(
      {bool initialSync, String? errorMsg, int? countDown, int? nextRetry});
}

/// @nodoc
class _$SyncStateCopyWithImpl<$Res, $Val extends SyncState>
    implements $SyncStateCopyWith<$Res> {
  _$SyncStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? initialSync = null,
    Object? errorMsg = freezed,
    Object? countDown = freezed,
    Object? nextRetry = freezed,
  }) {
    return _then(_value.copyWith(
      initialSync: null == initialSync
          ? _value.initialSync
          : initialSync // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMsg: freezed == errorMsg
          ? _value.errorMsg
          : errorMsg // ignore: cast_nullable_to_non_nullable
              as String?,
      countDown: freezed == countDown
          ? _value.countDown
          : countDown // ignore: cast_nullable_to_non_nullable
              as int?,
      nextRetry: freezed == nextRetry
          ? _value.nextRetry
          : nextRetry // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewSyncStateImplCopyWith<$Res>
    implements $SyncStateCopyWith<$Res> {
  factory _$$NewSyncStateImplCopyWith(
          _$NewSyncStateImpl value, $Res Function(_$NewSyncStateImpl) then) =
      __$$NewSyncStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool initialSync, String? errorMsg, int? countDown, int? nextRetry});
}

/// @nodoc
class __$$NewSyncStateImplCopyWithImpl<$Res>
    extends _$SyncStateCopyWithImpl<$Res, _$NewSyncStateImpl>
    implements _$$NewSyncStateImplCopyWith<$Res> {
  __$$NewSyncStateImplCopyWithImpl(
      _$NewSyncStateImpl _value, $Res Function(_$NewSyncStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? initialSync = null,
    Object? errorMsg = freezed,
    Object? countDown = freezed,
    Object? nextRetry = freezed,
  }) {
    return _then(_$NewSyncStateImpl(
      initialSync: null == initialSync
          ? _value.initialSync
          : initialSync // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMsg: freezed == errorMsg
          ? _value.errorMsg
          : errorMsg // ignore: cast_nullable_to_non_nullable
              as String?,
      countDown: freezed == countDown
          ? _value.countDown
          : countDown // ignore: cast_nullable_to_non_nullable
              as int?,
      nextRetry: freezed == nextRetry
          ? _value.nextRetry
          : nextRetry // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$NewSyncStateImpl with DiagnosticableTreeMixin implements _NewSyncState {
  const _$NewSyncStateImpl(
      {required this.initialSync,
      this.errorMsg,
      this.countDown,
      this.nextRetry});

  @override
  final bool initialSync;
  @override
  final String? errorMsg;
  @override
  final int? countDown;
  @override
  final int? nextRetry;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'SyncState(initialSync: $initialSync, errorMsg: $errorMsg, countDown: $countDown, nextRetry: $nextRetry)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'SyncState'))
      ..add(DiagnosticsProperty('initialSync', initialSync))
      ..add(DiagnosticsProperty('errorMsg', errorMsg))
      ..add(DiagnosticsProperty('countDown', countDown))
      ..add(DiagnosticsProperty('nextRetry', nextRetry));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewSyncStateImpl &&
            (identical(other.initialSync, initialSync) ||
                other.initialSync == initialSync) &&
            (identical(other.errorMsg, errorMsg) ||
                other.errorMsg == errorMsg) &&
            (identical(other.countDown, countDown) ||
                other.countDown == countDown) &&
            (identical(other.nextRetry, nextRetry) ||
                other.nextRetry == nextRetry));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, initialSync, errorMsg, countDown, nextRetry);

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewSyncStateImplCopyWith<_$NewSyncStateImpl> get copyWith =>
      __$$NewSyncStateImplCopyWithImpl<_$NewSyncStateImpl>(this, _$identity);
}

abstract class _NewSyncState implements SyncState {
  const factory _NewSyncState(
      {required final bool initialSync,
      final String? errorMsg,
      final int? countDown,
      final int? nextRetry}) = _$NewSyncStateImpl;

  @override
  bool get initialSync;
  @override
  String? get errorMsg;
  @override
  int? get countDown;
  @override
  int? get nextRetry;

  /// Create a copy of SyncState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewSyncStateImplCopyWith<_$NewSyncStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
