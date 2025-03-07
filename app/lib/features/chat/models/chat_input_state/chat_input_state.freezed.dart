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
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ChatInputState {
  SelectedMessageState get selectedMessageState =>
      throw _privateConstructorUsedError;
  SendingState get sendingState => throw _privateConstructorUsedError;
  bool get emojiPickerVisible => throw _privateConstructorUsedError;
  types.Message? get selectedMessage => throw _privateConstructorUsedError;
  Map<String, String> get mentions => throw _privateConstructorUsedError;
  bool get editBtnVisible => throw _privateConstructorUsedError;

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatInputStateCopyWith<ChatInputState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatInputStateCopyWith<$Res> {
  factory $ChatInputStateCopyWith(
    ChatInputState value,
    $Res Function(ChatInputState) then,
  ) = _$ChatInputStateCopyWithImpl<$Res, ChatInputState>;
  @useResult
  $Res call({
    SelectedMessageState selectedMessageState,
    SendingState sendingState,
    bool emojiPickerVisible,
    types.Message? selectedMessage,
    Map<String, String> mentions,
    bool editBtnVisible,
  });
}

/// @nodoc
class _$ChatInputStateCopyWithImpl<$Res, $Val extends ChatInputState>
    implements $ChatInputStateCopyWith<$Res> {
  _$ChatInputStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedMessageState = null,
    Object? sendingState = null,
    Object? emojiPickerVisible = null,
    Object? selectedMessage = freezed,
    Object? mentions = null,
    Object? editBtnVisible = null,
  }) {
    return _then(
      _value.copyWith(
            selectedMessageState:
                null == selectedMessageState
                    ? _value.selectedMessageState
                    : selectedMessageState // ignore: cast_nullable_to_non_nullable
                        as SelectedMessageState,
            sendingState:
                null == sendingState
                    ? _value.sendingState
                    : sendingState // ignore: cast_nullable_to_non_nullable
                        as SendingState,
            emojiPickerVisible:
                null == emojiPickerVisible
                    ? _value.emojiPickerVisible
                    : emojiPickerVisible // ignore: cast_nullable_to_non_nullable
                        as bool,
            selectedMessage:
                freezed == selectedMessage
                    ? _value.selectedMessage
                    : selectedMessage // ignore: cast_nullable_to_non_nullable
                        as types.Message?,
            mentions:
                null == mentions
                    ? _value.mentions
                    : mentions // ignore: cast_nullable_to_non_nullable
                        as Map<String, String>,
            editBtnVisible:
                null == editBtnVisible
                    ? _value.editBtnVisible
                    : editBtnVisible // ignore: cast_nullable_to_non_nullable
                        as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ChatInputStateImplCopyWith<$Res>
    implements $ChatInputStateCopyWith<$Res> {
  factory _$$ChatInputStateImplCopyWith(
    _$ChatInputStateImpl value,
    $Res Function(_$ChatInputStateImpl) then,
  ) = __$$ChatInputStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    SelectedMessageState selectedMessageState,
    SendingState sendingState,
    bool emojiPickerVisible,
    types.Message? selectedMessage,
    Map<String, String> mentions,
    bool editBtnVisible,
  });
}

/// @nodoc
class __$$ChatInputStateImplCopyWithImpl<$Res>
    extends _$ChatInputStateCopyWithImpl<$Res, _$ChatInputStateImpl>
    implements _$$ChatInputStateImplCopyWith<$Res> {
  __$$ChatInputStateImplCopyWithImpl(
    _$ChatInputStateImpl _value,
    $Res Function(_$ChatInputStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedMessageState = null,
    Object? sendingState = null,
    Object? emojiPickerVisible = null,
    Object? selectedMessage = freezed,
    Object? mentions = null,
    Object? editBtnVisible = null,
  }) {
    return _then(
      _$ChatInputStateImpl(
        selectedMessageState:
            null == selectedMessageState
                ? _value.selectedMessageState
                : selectedMessageState // ignore: cast_nullable_to_non_nullable
                    as SelectedMessageState,
        sendingState:
            null == sendingState
                ? _value.sendingState
                : sendingState // ignore: cast_nullable_to_non_nullable
                    as SendingState,
        emojiPickerVisible:
            null == emojiPickerVisible
                ? _value.emojiPickerVisible
                : emojiPickerVisible // ignore: cast_nullable_to_non_nullable
                    as bool,
        selectedMessage:
            freezed == selectedMessage
                ? _value.selectedMessage
                : selectedMessage // ignore: cast_nullable_to_non_nullable
                    as types.Message?,
        mentions:
            null == mentions
                ? _value._mentions
                : mentions // ignore: cast_nullable_to_non_nullable
                    as Map<String, String>,
        editBtnVisible:
            null == editBtnVisible
                ? _value.editBtnVisible
                : editBtnVisible // ignore: cast_nullable_to_non_nullable
                    as bool,
      ),
    );
  }
}

/// @nodoc

class _$ChatInputStateImpl implements _ChatInputState {
  const _$ChatInputStateImpl({
    this.selectedMessageState = SelectedMessageState.none,
    this.sendingState = SendingState.preparing,
    this.emojiPickerVisible = false,
    this.selectedMessage = null,
    final Map<String, String> mentions = const {},
    this.editBtnVisible = false,
  }) : _mentions = mentions;

  @override
  @JsonKey()
  final SelectedMessageState selectedMessageState;
  @override
  @JsonKey()
  final SendingState sendingState;
  @override
  @JsonKey()
  final bool emojiPickerVisible;
  @override
  @JsonKey()
  final types.Message? selectedMessage;
  final Map<String, String> _mentions;
  @override
  @JsonKey()
  Map<String, String> get mentions {
    if (_mentions is EqualUnmodifiableMapView) return _mentions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_mentions);
  }

  @override
  @JsonKey()
  final bool editBtnVisible;

  @override
  String toString() {
    return 'ChatInputState(selectedMessageState: $selectedMessageState, sendingState: $sendingState, emojiPickerVisible: $emojiPickerVisible, selectedMessage: $selectedMessage, mentions: $mentions, editBtnVisible: $editBtnVisible)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatInputStateImpl &&
            (identical(other.selectedMessageState, selectedMessageState) ||
                other.selectedMessageState == selectedMessageState) &&
            (identical(other.sendingState, sendingState) ||
                other.sendingState == sendingState) &&
            (identical(other.emojiPickerVisible, emojiPickerVisible) ||
                other.emojiPickerVisible == emojiPickerVisible) &&
            (identical(other.selectedMessage, selectedMessage) ||
                other.selectedMessage == selectedMessage) &&
            const DeepCollectionEquality().equals(other._mentions, _mentions) &&
            (identical(other.editBtnVisible, editBtnVisible) ||
                other.editBtnVisible == editBtnVisible));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    selectedMessageState,
    sendingState,
    emojiPickerVisible,
    selectedMessage,
    const DeepCollectionEquality().hash(_mentions),
    editBtnVisible,
  );

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatInputStateImplCopyWith<_$ChatInputStateImpl> get copyWith =>
      __$$ChatInputStateImplCopyWithImpl<_$ChatInputStateImpl>(
        this,
        _$identity,
      );
}

abstract class _ChatInputState implements ChatInputState {
  const factory _ChatInputState({
    final SelectedMessageState selectedMessageState,
    final SendingState sendingState,
    final bool emojiPickerVisible,
    final types.Message? selectedMessage,
    final Map<String, String> mentions,
    final bool editBtnVisible,
  }) = _$ChatInputStateImpl;

  @override
  SelectedMessageState get selectedMessageState;
  @override
  SendingState get sendingState;
  @override
  bool get emojiPickerVisible;
  @override
  types.Message? get selectedMessage;
  @override
  Map<String, String> get mentions;
  @override
  bool get editBtnVisible;

  /// Create a copy of ChatInputState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatInputStateImplCopyWith<_$ChatInputStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
