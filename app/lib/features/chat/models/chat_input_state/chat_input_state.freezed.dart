// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_input_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$ChatInputState {
  bool get showReplyView => throw _privateConstructorUsedError;
  Widget? get replyWidget => throw _privateConstructorUsedError;
  bool get sendBtnVisible => throw _privateConstructorUsedError;
  bool get emojiBtnVisible => throw _privateConstructorUsedError;
  bool get attachmentVisible => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ChatInputStateCopyWith<ChatInputState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatInputStateCopyWith<$Res> {
  factory $ChatInputStateCopyWith(
          ChatInputState value, $Res Function(ChatInputState) then) =
      _$ChatInputStateCopyWithImpl<$Res, ChatInputState>;
  @useResult
  $Res call(
      {bool showReplyView,
      Widget? replyWidget,
      bool sendBtnVisible,
      bool emojiBtnVisible,
      bool attachmentVisible});
}

/// @nodoc
class _$ChatInputStateCopyWithImpl<$Res, $Val extends ChatInputState>
    implements $ChatInputStateCopyWith<$Res> {
  _$ChatInputStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showReplyView = null,
    Object? replyWidget = freezed,
    Object? sendBtnVisible = null,
    Object? emojiBtnVisible = null,
    Object? attachmentVisible = null,
  }) {
    return _then(_value.copyWith(
      showReplyView: null == showReplyView
          ? _value.showReplyView
          : showReplyView // ignore: cast_nullable_to_non_nullable
              as bool,
      replyWidget: freezed == replyWidget
          ? _value.replyWidget
          : replyWidget // ignore: cast_nullable_to_non_nullable
              as Widget?,
      sendBtnVisible: null == sendBtnVisible
          ? _value.sendBtnVisible
          : sendBtnVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      emojiBtnVisible: null == emojiBtnVisible
          ? _value.emojiBtnVisible
          : emojiBtnVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      attachmentVisible: null == attachmentVisible
          ? _value.attachmentVisible
          : attachmentVisible // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$_ChatInputStateCopyWith<$Res>
    implements $ChatInputStateCopyWith<$Res> {
  factory _$$_ChatInputStateCopyWith(
          _$_ChatInputState value, $Res Function(_$_ChatInputState) then) =
      __$$_ChatInputStateCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool showReplyView,
      Widget? replyWidget,
      bool sendBtnVisible,
      bool emojiBtnVisible,
      bool attachmentVisible});
}

/// @nodoc
class __$$_ChatInputStateCopyWithImpl<$Res>
    extends _$ChatInputStateCopyWithImpl<$Res, _$_ChatInputState>
    implements _$$_ChatInputStateCopyWith<$Res> {
  __$$_ChatInputStateCopyWithImpl(
      _$_ChatInputState _value, $Res Function(_$_ChatInputState) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? showReplyView = null,
    Object? replyWidget = freezed,
    Object? sendBtnVisible = null,
    Object? emojiBtnVisible = null,
    Object? attachmentVisible = null,
  }) {
    return _then(_$_ChatInputState(
      showReplyView: null == showReplyView
          ? _value.showReplyView
          : showReplyView // ignore: cast_nullable_to_non_nullable
              as bool,
      replyWidget: freezed == replyWidget
          ? _value.replyWidget
          : replyWidget // ignore: cast_nullable_to_non_nullable
              as Widget?,
      sendBtnVisible: null == sendBtnVisible
          ? _value.sendBtnVisible
          : sendBtnVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      emojiBtnVisible: null == emojiBtnVisible
          ? _value.emojiBtnVisible
          : emojiBtnVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      attachmentVisible: null == attachmentVisible
          ? _value.attachmentVisible
          : attachmentVisible // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$_ChatInputState implements _ChatInputState {
  const _$_ChatInputState(
      {this.showReplyView = false,
      this.replyWidget = null,
      this.sendBtnVisible = false,
      this.emojiBtnVisible = false,
      this.attachmentVisible = false});

  @override
  @JsonKey()
  final bool showReplyView;
  @override
  @JsonKey()
  final Widget? replyWidget;
  @override
  @JsonKey()
  final bool sendBtnVisible;
  @override
  @JsonKey()
  final bool emojiBtnVisible;
  @override
  @JsonKey()
  final bool attachmentVisible;

  @override
  String toString() {
    return 'ChatInputState(showReplyView: $showReplyView, replyWidget: $replyWidget, sendBtnVisible: $sendBtnVisible, emojiBtnVisible: $emojiBtnVisible, attachmentVisible: $attachmentVisible)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$_ChatInputState &&
            (identical(other.showReplyView, showReplyView) ||
                other.showReplyView == showReplyView) &&
            (identical(other.replyWidget, replyWidget) ||
                other.replyWidget == replyWidget) &&
            (identical(other.sendBtnVisible, sendBtnVisible) ||
                other.sendBtnVisible == sendBtnVisible) &&
            (identical(other.emojiBtnVisible, emojiBtnVisible) ||
                other.emojiBtnVisible == emojiBtnVisible) &&
            (identical(other.attachmentVisible, attachmentVisible) ||
                other.attachmentVisible == attachmentVisible));
  }

  @override
  int get hashCode => Object.hash(runtimeType, showReplyView, replyWidget,
      sendBtnVisible, emojiBtnVisible, attachmentVisible);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$_ChatInputStateCopyWith<_$_ChatInputState> get copyWith =>
      __$$_ChatInputStateCopyWithImpl<_$_ChatInputState>(this, _$identity);
}

abstract class _ChatInputState implements ChatInputState {
  const factory _ChatInputState(
      {final bool showReplyView,
      final Widget? replyWidget,
      final bool sendBtnVisible,
      final bool emojiBtnVisible,
      final bool attachmentVisible}) = _$_ChatInputState;

  @override
  bool get showReplyView;
  @override
  Widget? get replyWidget;
  @override
  bool get sendBtnVisible;
  @override
  bool get emojiBtnVisible;
  @override
  bool get attachmentVisible;
  @override
  @JsonKey(ignore: true)
  _$$_ChatInputStateCopyWith<_$_ChatInputState> get copyWith =>
      throw _privateConstructorUsedError;
}
