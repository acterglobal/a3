// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'create_pin_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CreatePinState {
  String? get pinTitle => throw _privateConstructorUsedError;
  ({String htmlBodyDescription, String plainDescription})?
  get pinDescriptionParams => throw _privateConstructorUsedError;
  List<PinAttachment> get pinAttachmentList =>
      throw _privateConstructorUsedError;

  /// Create a copy of CreatePinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CreatePinStateCopyWith<CreatePinState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CreatePinStateCopyWith<$Res> {
  factory $CreatePinStateCopyWith(
    CreatePinState value,
    $Res Function(CreatePinState) then,
  ) = _$CreatePinStateCopyWithImpl<$Res, CreatePinState>;
  @useResult
  $Res call({
    String? pinTitle,
    ({String htmlBodyDescription, String plainDescription})?
    pinDescriptionParams,
    List<PinAttachment> pinAttachmentList,
  });
}

/// @nodoc
class _$CreatePinStateCopyWithImpl<$Res, $Val extends CreatePinState>
    implements $CreatePinStateCopyWith<$Res> {
  _$CreatePinStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CreatePinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pinTitle = freezed,
    Object? pinDescriptionParams = freezed,
    Object? pinAttachmentList = null,
  }) {
    return _then(
      _value.copyWith(
            pinTitle:
                freezed == pinTitle
                    ? _value.pinTitle
                    : pinTitle // ignore: cast_nullable_to_non_nullable
                        as String?,
            pinDescriptionParams:
                freezed == pinDescriptionParams
                    ? _value.pinDescriptionParams
                    : pinDescriptionParams // ignore: cast_nullable_to_non_nullable
                        as ({
                          String htmlBodyDescription,
                          String plainDescription,
                        })?,
            pinAttachmentList:
                null == pinAttachmentList
                    ? _value.pinAttachmentList
                    : pinAttachmentList // ignore: cast_nullable_to_non_nullable
                        as List<PinAttachment>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CreatePinStateImplCopyWith<$Res>
    implements $CreatePinStateCopyWith<$Res> {
  factory _$$CreatePinStateImplCopyWith(
    _$CreatePinStateImpl value,
    $Res Function(_$CreatePinStateImpl) then,
  ) = __$$CreatePinStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? pinTitle,
    ({String htmlBodyDescription, String plainDescription})?
    pinDescriptionParams,
    List<PinAttachment> pinAttachmentList,
  });
}

/// @nodoc
class __$$CreatePinStateImplCopyWithImpl<$Res>
    extends _$CreatePinStateCopyWithImpl<$Res, _$CreatePinStateImpl>
    implements _$$CreatePinStateImplCopyWith<$Res> {
  __$$CreatePinStateImplCopyWithImpl(
    _$CreatePinStateImpl _value,
    $Res Function(_$CreatePinStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CreatePinState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pinTitle = freezed,
    Object? pinDescriptionParams = freezed,
    Object? pinAttachmentList = null,
  }) {
    return _then(
      _$CreatePinStateImpl(
        pinTitle:
            freezed == pinTitle
                ? _value.pinTitle
                : pinTitle // ignore: cast_nullable_to_non_nullable
                    as String?,
        pinDescriptionParams:
            freezed == pinDescriptionParams
                ? _value.pinDescriptionParams
                : pinDescriptionParams // ignore: cast_nullable_to_non_nullable
                    as ({String htmlBodyDescription, String plainDescription})?,
        pinAttachmentList:
            null == pinAttachmentList
                ? _value._pinAttachmentList
                : pinAttachmentList // ignore: cast_nullable_to_non_nullable
                    as List<PinAttachment>,
      ),
    );
  }
}

/// @nodoc

class _$CreatePinStateImpl implements _CreatePinState {
  const _$CreatePinStateImpl({
    this.pinTitle,
    this.pinDescriptionParams,
    final List<PinAttachment> pinAttachmentList = const [],
  }) : _pinAttachmentList = pinAttachmentList;

  @override
  final String? pinTitle;
  @override
  final ({String htmlBodyDescription, String plainDescription})?
  pinDescriptionParams;
  final List<PinAttachment> _pinAttachmentList;
  @override
  @JsonKey()
  List<PinAttachment> get pinAttachmentList {
    if (_pinAttachmentList is EqualUnmodifiableListView)
      return _pinAttachmentList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pinAttachmentList);
  }

  @override
  String toString() {
    return 'CreatePinState(pinTitle: $pinTitle, pinDescriptionParams: $pinDescriptionParams, pinAttachmentList: $pinAttachmentList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CreatePinStateImpl &&
            (identical(other.pinTitle, pinTitle) ||
                other.pinTitle == pinTitle) &&
            (identical(other.pinDescriptionParams, pinDescriptionParams) ||
                other.pinDescriptionParams == pinDescriptionParams) &&
            const DeepCollectionEquality().equals(
              other._pinAttachmentList,
              _pinAttachmentList,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pinTitle,
    pinDescriptionParams,
    const DeepCollectionEquality().hash(_pinAttachmentList),
  );

  /// Create a copy of CreatePinState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CreatePinStateImplCopyWith<_$CreatePinStateImpl> get copyWith =>
      __$$CreatePinStateImplCopyWithImpl<_$CreatePinStateImpl>(
        this,
        _$identity,
      );
}

abstract class _CreatePinState implements CreatePinState {
  const factory _CreatePinState({
    final String? pinTitle,
    final ({String htmlBodyDescription, String plainDescription})?
    pinDescriptionParams,
    final List<PinAttachment> pinAttachmentList,
  }) = _$CreatePinStateImpl;

  @override
  String? get pinTitle;
  @override
  ({String htmlBodyDescription, String plainDescription})?
  get pinDescriptionParams;
  @override
  List<PinAttachment> get pinAttachmentList;

  /// Create a copy of CreatePinState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CreatePinStateImplCopyWith<_$CreatePinStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
