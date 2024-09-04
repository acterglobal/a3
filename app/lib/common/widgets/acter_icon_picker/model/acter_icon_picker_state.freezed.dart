// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'acter_icon_picker_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ActerIconPickerState {
  Color get selectedColor => throw _privateConstructorUsedError;
  ActerIcons get selectedIcon => throw _privateConstructorUsedError;
  String? get newsPostSpaceId => throw _privateConstructorUsedError;

  /// Create a copy of ActerIconPickerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ActerIconPickerStateCopyWith<ActerIconPickerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ActerIconPickerStateCopyWith<$Res> {
  factory $ActerIconPickerStateCopyWith(ActerIconPickerState value,
          $Res Function(ActerIconPickerState) then) =
      _$ActerIconPickerStateCopyWithImpl<$Res, ActerIconPickerState>;
  @useResult
  $Res call(
      {Color selectedColor, ActerIcons selectedIcon, String? newsPostSpaceId});
}

/// @nodoc
class _$ActerIconPickerStateCopyWithImpl<$Res,
        $Val extends ActerIconPickerState>
    implements $ActerIconPickerStateCopyWith<$Res> {
  _$ActerIconPickerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ActerIconPickerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedColor = null,
    Object? selectedIcon = null,
    Object? newsPostSpaceId = freezed,
  }) {
    return _then(_value.copyWith(
      selectedColor: null == selectedColor
          ? _value.selectedColor
          : selectedColor // ignore: cast_nullable_to_non_nullable
              as Color,
      selectedIcon: null == selectedIcon
          ? _value.selectedIcon
          : selectedIcon // ignore: cast_nullable_to_non_nullable
              as ActerIcons,
      newsPostSpaceId: freezed == newsPostSpaceId
          ? _value.newsPostSpaceId
          : newsPostSpaceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ActerIconPickerStateImplCopyWith<$Res>
    implements $ActerIconPickerStateCopyWith<$Res> {
  factory _$$ActerIconPickerStateImplCopyWith(_$ActerIconPickerStateImpl value,
          $Res Function(_$ActerIconPickerStateImpl) then) =
      __$$ActerIconPickerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Color selectedColor, ActerIcons selectedIcon, String? newsPostSpaceId});
}

/// @nodoc
class __$$ActerIconPickerStateImplCopyWithImpl<$Res>
    extends _$ActerIconPickerStateCopyWithImpl<$Res, _$ActerIconPickerStateImpl>
    implements _$$ActerIconPickerStateImplCopyWith<$Res> {
  __$$ActerIconPickerStateImplCopyWithImpl(_$ActerIconPickerStateImpl _value,
      $Res Function(_$ActerIconPickerStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ActerIconPickerState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedColor = null,
    Object? selectedIcon = null,
    Object? newsPostSpaceId = freezed,
  }) {
    return _then(_$ActerIconPickerStateImpl(
      selectedColor: null == selectedColor
          ? _value.selectedColor
          : selectedColor // ignore: cast_nullable_to_non_nullable
              as Color,
      selectedIcon: null == selectedIcon
          ? _value.selectedIcon
          : selectedIcon // ignore: cast_nullable_to_non_nullable
              as ActerIcons,
      newsPostSpaceId: freezed == newsPostSpaceId
          ? _value.newsPostSpaceId
          : newsPostSpaceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ActerIconPickerStateImpl implements _ActerIconPickerState {
  const _$ActerIconPickerStateImpl(
      {this.selectedColor = Colors.blueGrey,
      this.selectedIcon = ActerIcons.list,
      this.newsPostSpaceId});

  @override
  @JsonKey()
  final Color selectedColor;
  @override
  @JsonKey()
  final ActerIcons selectedIcon;
  @override
  final String? newsPostSpaceId;

  @override
  String toString() {
    return 'ActerIconPickerState(selectedColor: $selectedColor, selectedIcon: $selectedIcon, newsPostSpaceId: $newsPostSpaceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ActerIconPickerStateImpl &&
            (identical(other.selectedColor, selectedColor) ||
                other.selectedColor == selectedColor) &&
            (identical(other.selectedIcon, selectedIcon) ||
                other.selectedIcon == selectedIcon) &&
            (identical(other.newsPostSpaceId, newsPostSpaceId) ||
                other.newsPostSpaceId == newsPostSpaceId));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, selectedColor, selectedIcon, newsPostSpaceId);

  /// Create a copy of ActerIconPickerState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ActerIconPickerStateImplCopyWith<_$ActerIconPickerStateImpl>
      get copyWith =>
          __$$ActerIconPickerStateImplCopyWithImpl<_$ActerIconPickerStateImpl>(
              this, _$identity);
}

abstract class _ActerIconPickerState implements ActerIconPickerState {
  const factory _ActerIconPickerState(
      {final Color selectedColor,
      final ActerIcons selectedIcon,
      final String? newsPostSpaceId}) = _$ActerIconPickerStateImpl;

  @override
  Color get selectedColor;
  @override
  ActerIcons get selectedIcon;
  @override
  String? get newsPostSpaceId;

  /// Create a copy of ActerIconPickerState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ActerIconPickerStateImplCopyWith<_$ActerIconPickerStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
