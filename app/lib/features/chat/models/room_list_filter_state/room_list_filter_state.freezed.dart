// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'room_list_filter_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$RoomListFilterState {
  String? get searchTerm => throw _privateConstructorUsedError;
  FilterSelection get selection => throw _privateConstructorUsedError;

  /// Create a copy of RoomListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomListFilterStateCopyWith<RoomListFilterState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomListFilterStateCopyWith<$Res> {
  factory $RoomListFilterStateCopyWith(
          RoomListFilterState value, $Res Function(RoomListFilterState) then) =
      _$RoomListFilterStateCopyWithImpl<$Res, RoomListFilterState>;
  @useResult
  $Res call({String? searchTerm, FilterSelection selection});
}

/// @nodoc
class _$RoomListFilterStateCopyWithImpl<$Res, $Val extends RoomListFilterState>
    implements $RoomListFilterStateCopyWith<$Res> {
  _$RoomListFilterStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchTerm = freezed,
    Object? selection = null,
  }) {
    return _then(_value.copyWith(
      searchTerm: freezed == searchTerm
          ? _value.searchTerm
          : searchTerm // ignore: cast_nullable_to_non_nullable
              as String?,
      selection: null == selection
          ? _value.selection
          : selection // ignore: cast_nullable_to_non_nullable
              as FilterSelection,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoomListFilterStateImplCopyWith<$Res>
    implements $RoomListFilterStateCopyWith<$Res> {
  factory _$$RoomListFilterStateImplCopyWith(_$RoomListFilterStateImpl value,
          $Res Function(_$RoomListFilterStateImpl) then) =
      __$$RoomListFilterStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? searchTerm, FilterSelection selection});
}

/// @nodoc
class __$$RoomListFilterStateImplCopyWithImpl<$Res>
    extends _$RoomListFilterStateCopyWithImpl<$Res, _$RoomListFilterStateImpl>
    implements _$$RoomListFilterStateImplCopyWith<$Res> {
  __$$RoomListFilterStateImplCopyWithImpl(_$RoomListFilterStateImpl _value,
      $Res Function(_$RoomListFilterStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoomListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchTerm = freezed,
    Object? selection = null,
  }) {
    return _then(_$RoomListFilterStateImpl(
      searchTerm: freezed == searchTerm
          ? _value.searchTerm
          : searchTerm // ignore: cast_nullable_to_non_nullable
              as String?,
      selection: null == selection
          ? _value.selection
          : selection // ignore: cast_nullable_to_non_nullable
              as FilterSelection,
    ));
  }
}

/// @nodoc

class _$RoomListFilterStateImpl implements _RoomListFilterState {
  const _$RoomListFilterStateImpl(
      {this.searchTerm, this.selection = FilterSelection.all});

  @override
  final String? searchTerm;
  @override
  @JsonKey()
  final FilterSelection selection;

  @override
  String toString() {
    return 'RoomListFilterState(searchTerm: $searchTerm, selection: $selection)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomListFilterStateImpl &&
            (identical(other.searchTerm, searchTerm) ||
                other.searchTerm == searchTerm) &&
            (identical(other.selection, selection) ||
                other.selection == selection));
  }

  @override
  int get hashCode => Object.hash(runtimeType, searchTerm, selection);

  /// Create a copy of RoomListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomListFilterStateImplCopyWith<_$RoomListFilterStateImpl> get copyWith =>
      __$$RoomListFilterStateImplCopyWithImpl<_$RoomListFilterStateImpl>(
          this, _$identity);
}

abstract class _RoomListFilterState implements RoomListFilterState {
  const factory _RoomListFilterState(
      {final String? searchTerm,
      final FilterSelection selection}) = _$RoomListFilterStateImpl;

  @override
  String? get searchTerm;
  @override
  FilterSelection get selection;

  /// Create a copy of RoomListFilterState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomListFilterStateImplCopyWith<_$RoomListFilterStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
