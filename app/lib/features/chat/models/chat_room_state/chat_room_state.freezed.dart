// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_room_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ChatRoomState {
  Conversation? get currentRoom => throw _privateConstructorUsedError;
  List<User> get typingUsers => throw _privateConstructorUsedError;
  List<Member> get activeMembers => throw _privateConstructorUsedError;
  Widget? get replyMessageWidget => throw _privateConstructorUsedError;
  Message? get repliedToMessage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatRoomStateCopyWith<ChatRoomState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatRoomStateCopyWith<$Res> {
  factory $ChatRoomStateCopyWith(
          ChatRoomState value, $Res Function(ChatRoomState) then) =
      _$ChatRoomStateCopyWithImpl<$Res, ChatRoomState>;
  @useResult
  $Res call(
      {Conversation? currentRoom,
      List<User> typingUsers,
      List<Member> activeMembers,
      Widget? replyMessageWidget,
      Message? repliedToMessage});
}

/// @nodoc
class _$ChatRoomStateCopyWithImpl<$Res, $Val extends ChatRoomState>
    implements $ChatRoomStateCopyWith<$Res> {
  _$ChatRoomStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentRoom = freezed,
    Object? typingUsers = null,
    Object? activeMembers = null,
    Object? replyMessageWidget = freezed,
    Object? repliedToMessage = freezed,
  }) {
    return _then(_value.copyWith(
      currentRoom: freezed == currentRoom
          ? _value.currentRoom
          : currentRoom // ignore: cast_nullable_to_non_nullable
              as Conversation?,
      typingUsers: null == typingUsers
          ? _value.typingUsers
          : typingUsers // ignore: cast_nullable_to_non_nullable
              as List<User>,
      activeMembers: null == activeMembers
          ? _value.activeMembers
          : activeMembers // ignore: cast_nullable_to_non_nullable
              as List<Member>,
      replyMessageWidget: freezed == replyMessageWidget
          ? _value.replyMessageWidget
          : replyMessageWidget // ignore: cast_nullable_to_non_nullable
              as Widget?,
      repliedToMessage: freezed == repliedToMessage
          ? _value.repliedToMessage
          : repliedToMessage // ignore: cast_nullable_to_non_nullable
              as Message?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ChatRoomStateCopyWith<$Res>
    implements $ChatRoomStateCopyWith<$Res> {
  factory _$$_ChatRoomStateCopyWith(
          _$_ChatRoomState value, $Res Function(_$_ChatRoomState) then) =
      __$$_ChatRoomStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Conversation? currentRoom,
      List<User> typingUsers,
      List<Member> activeMembers,
      Widget? replyMessageWidget,
      Message? repliedToMessage});
}

/// @nodoc
class __$$_ChatRoomStateCopyWithImpl<$Res>
    extends _$ChatRoomStateCopyWithImpl<$Res, _$_ChatRoomState>
    implements _$$_ChatRoomStateCopyWith<$Res> {
  __$$_ChatRoomStateCopyWithImpl(
      _$_ChatRoomState _value, $Res Function(_$_ChatRoomState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentRoom = freezed,
    Object? typingUsers = null,
    Object? activeMembers = null,
    Object? replyMessageWidget = freezed,
    Object? repliedToMessage = freezed,
  }) {
    return _then(_$_ChatRoomState(
      currentRoom: freezed == currentRoom
          ? _value.currentRoom
          : currentRoom // ignore: cast_nullable_to_non_nullable
              as Conversation?,
      typingUsers: null == typingUsers
          ? _value._typingUsers
          : typingUsers // ignore: cast_nullable_to_non_nullable
              as List<User>,
      activeMembers: null == activeMembers
          ? _value._activeMembers
          : activeMembers // ignore: cast_nullable_to_non_nullable
              as List<Member>,
      replyMessageWidget: freezed == replyMessageWidget
          ? _value.replyMessageWidget
          : replyMessageWidget // ignore: cast_nullable_to_non_nullable
              as Widget?,
      repliedToMessage: freezed == repliedToMessage
          ? _value.repliedToMessage
          : repliedToMessage // ignore: cast_nullable_to_non_nullable
              as Message?,
    ));
  }
}

/// @nodoc

class _$_ChatRoomState implements _ChatRoomState {
  const _$_ChatRoomState(
      {this.currentRoom = null,
      final List<User> typingUsers = const [],
      final List<Member> activeMembers = const [],
      this.replyMessageWidget = null,
      this.repliedToMessage = null})
      : _typingUsers = typingUsers,
        _activeMembers = activeMembers;

  @override
  @JsonKey()
  final Conversation? currentRoom;
  final List<User> _typingUsers;
  @override
  @JsonKey()
  List<User> get typingUsers {
    if (_typingUsers is EqualUnmodifiableListView) return _typingUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_typingUsers);
  }

  final List<Member> _activeMembers;
  @override
  @JsonKey()
  List<Member> get activeMembers {
    if (_activeMembers is EqualUnmodifiableListView) return _activeMembers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeMembers);
  }

  @override
  @JsonKey()
  final Widget? replyMessageWidget;
  @override
  @JsonKey()
  final Message? repliedToMessage;

  @override
  String toString() {
    return 'ChatRoomState(currentRoom: $currentRoom, typingUsers: $typingUsers, activeMembers: $activeMembers, replyMessageWidget: $replyMessageWidget, repliedToMessage: $repliedToMessage)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ChatRoomState &&
            (identical(other.currentRoom, currentRoom) ||
                other.currentRoom == currentRoom) &&
            const DeepCollectionEquality()
                .equals(other._typingUsers, _typingUsers) &&
            const DeepCollectionEquality()
                .equals(other._activeMembers, _activeMembers) &&
            (identical(other.replyMessageWidget, replyMessageWidget) ||
                other.replyMessageWidget == replyMessageWidget) &&
            (identical(other.repliedToMessage, repliedToMessage) ||
                other.repliedToMessage == repliedToMessage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      currentRoom,
      const DeepCollectionEquality().hash(_typingUsers),
      const DeepCollectionEquality().hash(_activeMembers),
      replyMessageWidget,
      repliedToMessage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ChatRoomStateCopyWith<_$_ChatRoomState> get copyWith =>
      __$$_ChatRoomStateCopyWithImpl<_$_ChatRoomState>(this, _$identity);
}

abstract class _ChatRoomState implements ChatRoomState {
  const factory _ChatRoomState(
      {final Conversation? currentRoom,
      final List<User> typingUsers,
      final List<Member> activeMembers,
      final Widget? replyMessageWidget,
      final Message? repliedToMessage}) = _$_ChatRoomState;

  @override
  Conversation? get currentRoom;
  @override
  List<User> get typingUsers;
  @override
  List<Member> get activeMembers;
  @override
  Widget? get replyMessageWidget;
  @override
  Message? get repliedToMessage;
  @override
  @JsonKey(ignore: true)
  _$$_ChatRoomStateCopyWith<_$_ChatRoomState> get copyWith =>
      throw _privateConstructorUsedError;
}
