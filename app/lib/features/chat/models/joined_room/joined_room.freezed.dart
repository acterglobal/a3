// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'joined_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$JoinedRoom {
  String get id => throw _privateConstructorUsedError;
  Convo get convo => throw _privateConstructorUsedError;
  RoomMessage? get latestMessage => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  List<User> get typingUsers => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $JoinedRoomCopyWith<JoinedRoom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $JoinedRoomCopyWith<$Res> {
  factory $JoinedRoomCopyWith(
          JoinedRoom value, $Res Function(JoinedRoom) then) =
      _$JoinedRoomCopyWithImpl<$Res, JoinedRoom>;
  @useResult
  $Res call({
    String id,
    Convo convo,
    RoomMessage? latestMessage,
    String? displayName,
    List<User> typingUsers,
  });
}

/// @nodoc
class _$JoinedRoomCopyWithImpl<$Res, $Val extends JoinedRoom>
    implements $JoinedRoomCopyWith<$Res> {
  _$JoinedRoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? convo = null,
    Object? latestMessage = freezed,
    Object? displayName = freezed,
    Object? typingUsers = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      convo: null == convo
          ? _value.convo
          : convo // ignore: cast_nullable_to_non_nullable
              as Convo,
      latestMessage: freezed == latestMessage
          ? _value.latestMessage
          : latestMessage // ignore: cast_nullable_to_non_nullable
              as RoomMessage?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      typingUsers: null == typingUsers
          ? _value.typingUsers
          : typingUsers // ignore: cast_nullable_to_non_nullable
              as List<User>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_JoinedRoomCopyWith<$Res>
    implements $JoinedRoomCopyWith<$Res> {
  factory _$$_JoinedRoomCopyWith(
          _$_JoinedRoom value, $Res Function(_$_JoinedRoom) then) =
      __$$_JoinedRoomCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    Convo convo,
    RoomMessage? latestMessage,
    String? displayName,
    List<User> typingUsers,
  });
}

/// @nodoc
class __$$_JoinedRoomCopyWithImpl<$Res>
    extends _$JoinedRoomCopyWithImpl<$Res, _$_JoinedRoom>
    implements _$$_JoinedRoomCopyWith<$Res> {
  __$$_JoinedRoomCopyWithImpl(
      _$_JoinedRoom _value, $Res Function(_$_JoinedRoom) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? convo = null,
    Object? latestMessage = freezed,
    Object? displayName = freezed,
    Object? typingUsers = null,
  }) {
    return _then(_$_JoinedRoom(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      convo: null == convo
          ? _value.convo
          : convo // ignore: cast_nullable_to_non_nullable
              as Convo,
      latestMessage: freezed == latestMessage
          ? _value.latestMessage
          : latestMessage // ignore: cast_nullable_to_non_nullable
              as RoomMessage?,
      displayName: freezed == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      typingUsers: null == typingUsers
          ? _value.typingUsers
          : typingUsers // ignore: cast_nullable_to_non_nullable
              as List<User>,
    ));
  }
}

/// @nodoc

class _$_JoinedRoom implements _JoinedRoom {
  const _$_JoinedRoom({
    required this.id,
    required this.convo,
    this.latestMessage = null,
    this.displayName = null,
    this.typingUsers = const [],
  });

  @override
  final String id;
  @override
  final Convo convo;
  @override
  @JsonKey()
  final RoomMessage? latestMessage;
  @override
  @JsonKey()
  final String? displayName;
  @override
  @JsonKey()
  final List<User> typingUsers;

  @override
  String toString() {
    return 'JoinedRoom(id: $id, convo: $convo, latestMessage: $latestMessage, displayName: $displayName, typingUsers: $typingUsers)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_JoinedRoom &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.convo, convo) || other.convo == convo) &&
            (identical(other.latestMessage, latestMessage) ||
                other.latestMessage == latestMessage) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            const DeepCollectionEquality()
                .equals(other.typingUsers, typingUsers));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, convo, latestMessage,
      displayName, const DeepCollectionEquality().hash(typingUsers));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_JoinedRoomCopyWith<_$_JoinedRoom> get copyWith =>
      __$$_JoinedRoomCopyWithImpl<_$_JoinedRoom>(this, _$identity);
}

abstract class _JoinedRoom implements JoinedRoom {
  const factory _JoinedRoom({
    required final String id,
    required final Convo convo,
    final RoomMessage? latestMessage,
    final String? displayName,
    final List<User> typingUsers,
  }) = _$_JoinedRoom;

  @override
  String get id;
  @override
  Convo get convo;
  @override
  RoomMessage? get latestMessage;
  @override
  String? get displayName;
  @override
  List<User> get typingUsers;
  @override
  @JsonKey(ignore: true)
  _$$_JoinedRoomCopyWith<_$_JoinedRoom> get copyWith =>
      throw _privateConstructorUsedError;
}
