// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'receipt_room.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ReceiptRoom {
  Map<String, ReceiptUser> get users => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReceiptRoomCopyWith<ReceiptRoom> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceiptRoomCopyWith<$Res> {
  factory $ReceiptRoomCopyWith(
          ReceiptRoom value, $Res Function(ReceiptRoom) then) =
      _$ReceiptRoomCopyWithImpl<$Res, ReceiptRoom>;
  @useResult
  $Res call({Map<String, ReceiptUser> users});
}

/// @nodoc
class _$ReceiptRoomCopyWithImpl<$Res, $Val extends ReceiptRoom>
    implements $ReceiptRoomCopyWith<$Res> {
  _$ReceiptRoomCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? users = null,
  }) {
    return _then(_value.copyWith(
      users: null == users
          ? _value.users
          : users // ignore: cast_nullable_to_non_nullable
              as Map<String, ReceiptUser>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ReceiptRoomCopyWith<$Res>
    implements $ReceiptRoomCopyWith<$Res> {
  factory _$$_ReceiptRoomCopyWith(
          _$_ReceiptRoom value, $Res Function(_$_ReceiptRoom) then) =
      __$$_ReceiptRoomCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<String, ReceiptUser> users});
}

/// @nodoc
class __$$_ReceiptRoomCopyWithImpl<$Res>
    extends _$ReceiptRoomCopyWithImpl<$Res, _$_ReceiptRoom>
    implements _$$_ReceiptRoomCopyWith<$Res> {
  __$$_ReceiptRoomCopyWithImpl(
      _$_ReceiptRoom _value, $Res Function(_$_ReceiptRoom) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? users = null,
  }) {
    return _then(_$_ReceiptRoom(
      users: null == users
          ? _value._users
          : users // ignore: cast_nullable_to_non_nullable
              as Map<String, ReceiptUser>,
    ));
  }
}

/// @nodoc

class _$_ReceiptRoom implements _ReceiptRoom {
  const _$_ReceiptRoom({final Map<String, ReceiptUser> users = const {}})
      : _users = users;

  final Map<String, ReceiptUser> _users;
  @override
  @JsonKey()
  Map<String, ReceiptUser> get users {
    if (_users is EqualUnmodifiableMapView) return _users;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_users);
  }

  @override
  String toString() {
    return 'ReceiptRoom(users: $users)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ReceiptRoom &&
            const DeepCollectionEquality().equals(other._users, _users));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_users));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ReceiptRoomCopyWith<_$_ReceiptRoom> get copyWith =>
      __$$_ReceiptRoomCopyWithImpl<_$_ReceiptRoom>(this, _$identity);
}

abstract class _ReceiptRoom implements ReceiptRoom {
  const factory _ReceiptRoom({final Map<String, ReceiptUser> users}) =
      _$_ReceiptRoom;

  @override
  Map<String, ReceiptUser> get users;
  @override
  @JsonKey(ignore: true)
  _$$_ReceiptRoomCopyWith<_$_ReceiptRoom> get copyWith =>
      throw _privateConstructorUsedError;
}
