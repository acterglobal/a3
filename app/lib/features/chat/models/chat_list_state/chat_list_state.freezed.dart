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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ChatListState {
  bool get showSearch => throw _privateConstructorUsedError;
  List<JoinedRoom> get searchData => throw _privateConstructorUsedError;
  bool get initialLoaded => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatListStateCopyWith<ChatListState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatListStateCopyWith<$Res> {
  factory $ChatListStateCopyWith(
          ChatListState value, $Res Function(ChatListState) then) =
      _$ChatListStateCopyWithImpl<$Res, ChatListState>;
  @useResult
  $Res call({bool showSearch, List<JoinedRoom> searchData, bool initialLoaded});
}

/// @nodoc
class _$ChatListStateCopyWithImpl<$Res, $Val extends ChatListState>
    implements $ChatListStateCopyWith<$Res> {
  _$ChatListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showSearch = null,
    Object? searchData = null,
    Object? initialLoaded = null,
  }) {
    return _then(_value.copyWith(
      showSearch: null == showSearch
          ? _value.showSearch
          : showSearch // ignore: cast_nullable_to_non_nullable
              as bool,
      searchData: null == searchData
          ? _value.searchData
          : searchData // ignore: cast_nullable_to_non_nullable
              as List<JoinedRoom>,
      initialLoaded: null == initialLoaded
          ? _value.initialLoaded
          : initialLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ChatListStateCopyWith<$Res>
    implements $ChatListStateCopyWith<$Res> {
  factory _$$_ChatListStateCopyWith(
          _$_ChatListState value, $Res Function(_$_ChatListState) then) =
      __$$_ChatListStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({bool showSearch, List<JoinedRoom> searchData, bool initialLoaded});
}

/// @nodoc
class __$$_ChatListStateCopyWithImpl<$Res>
    extends _$ChatListStateCopyWithImpl<$Res, _$_ChatListState>
    implements _$$_ChatListStateCopyWith<$Res> {
  __$$_ChatListStateCopyWithImpl(
      _$_ChatListState _value, $Res Function(_$_ChatListState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showSearch = null,
    Object? searchData = null,
    Object? initialLoaded = null,
  }) {
    return _then(_$_ChatListState(
      showSearch: null == showSearch
          ? _value.showSearch
          : showSearch // ignore: cast_nullable_to_non_nullable
              as bool,
      searchData: null == searchData
          ? _value.searchData
          : searchData // ignore: cast_nullable_to_non_nullable
              as List<JoinedRoom>,
      initialLoaded: null == initialLoaded
          ? _value.initialLoaded
          : initialLoaded // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_ChatListState implements _ChatListState {
  const _$_ChatListState(
      {this.showSearch = false,
      this.searchData = const [],
      this.initialLoaded = false});

  @override
  @JsonKey()
  final bool showSearch;
  @override
  @JsonKey()
  final List<JoinedRoom> searchData;
  @override
  @JsonKey()
  final bool initialLoaded;

  @override
  String toString() {
    return 'ChatListState(showSearch: $showSearch, searchData: $searchData, initialLoaded: $initialLoaded)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ChatListState &&
            (identical(other.showSearch, showSearch) ||
                other.showSearch == showSearch) &&
            const DeepCollectionEquality()
                .equals(other.searchData, searchData) &&
            (identical(other.initialLoaded, initialLoaded) ||
                other.initialLoaded == initialLoaded));
  }

  @override
  int get hashCode => Object.hash(runtimeType, showSearch,
      const DeepCollectionEquality().hash(searchData), initialLoaded);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ChatListStateCopyWith<_$_ChatListState> get copyWith =>
      __$$_ChatListStateCopyWithImpl<_$_ChatListState>(this, _$identity);
}

abstract class _ChatListState implements ChatListState {
  const factory _ChatListState(
      {final bool showSearch,
      final List<JoinedRoom> searchData,
      final bool initialLoaded}) = _$_ChatListState;

  @override
  bool get showSearch;
  @override
  List<JoinedRoom> get searchData;
  @override
  bool get initialLoaded;
  @override
  @JsonKey(ignore: true)
  _$$_ChatListStateCopyWith<_$_ChatListState> get copyWith =>
      throw _privateConstructorUsedError;
}
