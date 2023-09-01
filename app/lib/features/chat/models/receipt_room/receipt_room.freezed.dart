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
  String get roomId => throw _privateConstructorUsedError;
  Map<String, List<String>> get receipts => throw _privateConstructorUsedError;

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
  $Res call({String roomId, Map<String, List<String>> receipts});
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
    Object? roomId = null,
    Object? receipts = null,
  }) {
    return _then(_value.copyWith(
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
      receipts: null == receipts
          ? _value.receipts
          : receipts // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
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
  $Res call({String roomId, Map<String, List<String>> receipts});
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
    Object? roomId = null,
    Object? receipts = null,
  }) {
    return _then(_$_ReceiptRoom(
      roomId: null == roomId
          ? _value.roomId
          : roomId // ignore: cast_nullable_to_non_nullable
              as String,
      receipts: null == receipts
          ? _value._receipts
          : receipts // ignore: cast_nullable_to_non_nullable
              as Map<String, List<String>>,
    ));
  }
}

/// @nodoc

class _$_ReceiptRoom implements _ReceiptRoom {
  const _$_ReceiptRoom(
      {required this.roomId,
      final Map<String, List<String>> receipts = const {}})
      : _receipts = receipts;

  @override
  final String roomId;
  final Map<String, List<String>> _receipts;
  @override
  @JsonKey()
  Map<String, List<String>> get receipts {
    if (_receipts is EqualUnmodifiableMapView) return _receipts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_receipts);
  }

  @override
  String toString() {
    return 'ReceiptRoom(roomId: $roomId, receipts: $receipts)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ReceiptRoom &&
            (identical(other.roomId, roomId) || other.roomId == roomId) &&
            const DeepCollectionEquality().equals(other._receipts, _receipts));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, roomId, const DeepCollectionEquality().hash(_receipts));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ReceiptRoomCopyWith<_$_ReceiptRoom> get copyWith =>
      __$$_ReceiptRoomCopyWithImpl<_$_ReceiptRoom>(this, _$identity);
}

abstract class _ReceiptRoom implements ReceiptRoom {
  const factory _ReceiptRoom(
      {required final String roomId,
      final Map<String, List<String>> receipts}) = _$_ReceiptRoom;

  @override
  String get roomId;
  @override
  Map<String, List<String>> get receipts;
  @override
  @JsonKey(ignore: true)
  _$$_ReceiptRoomCopyWith<_$_ReceiptRoom> get copyWith =>
      throw _privateConstructorUsedError;
}
