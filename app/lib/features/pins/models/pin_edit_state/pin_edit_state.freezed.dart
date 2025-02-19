// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pin_edit_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PinEditState {
  String get title => throw _privateConstructorUsedError;
  String get link => throw _privateConstructorUsedError;
  String get markdown => throw _privateConstructorUsedError;
  String? get html => throw _privateConstructorUsedError;
  bool get editMode => throw _privateConstructorUsedError;

  /// Create a copy of PinEditState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PinEditStateCopyWith<PinEditState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PinEditStateCopyWith<$Res> {
  factory $PinEditStateCopyWith(
          PinEditState value, $Res Function(PinEditState) then) =
      _$PinEditStateCopyWithImpl<$Res, PinEditState>;
  @useResult
  $Res call(
      {String title,
      String link,
      String markdown,
      String? html,
      bool editMode});
}

/// @nodoc
class _$PinEditStateCopyWithImpl<$Res, $Val extends PinEditState>
    implements $PinEditStateCopyWith<$Res> {
  _$PinEditStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PinEditState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? link = null,
    Object? markdown = null,
    Object? html = freezed,
    Object? editMode = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      markdown: null == markdown
          ? _value.markdown
          : markdown // ignore: cast_nullable_to_non_nullable
              as String,
      html: freezed == html
          ? _value.html
          : html // ignore: cast_nullable_to_non_nullable
              as String?,
      editMode: null == editMode
          ? _value.editMode
          : editMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PinEditStateImplCopyWith<$Res>
    implements $PinEditStateCopyWith<$Res> {
  factory _$$PinEditStateImplCopyWith(
          _$PinEditStateImpl value, $Res Function(_$PinEditStateImpl) then) =
      __$$PinEditStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      String link,
      String markdown,
      String? html,
      bool editMode});
}

/// @nodoc
class __$$PinEditStateImplCopyWithImpl<$Res>
    extends _$PinEditStateCopyWithImpl<$Res, _$PinEditStateImpl>
    implements _$$PinEditStateImplCopyWith<$Res> {
  __$$PinEditStateImplCopyWithImpl(
      _$PinEditStateImpl _value, $Res Function(_$PinEditStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PinEditState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? link = null,
    Object? markdown = null,
    Object? html = freezed,
    Object? editMode = null,
  }) {
    return _then(_$PinEditStateImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      link: null == link
          ? _value.link
          : link // ignore: cast_nullable_to_non_nullable
              as String,
      markdown: null == markdown
          ? _value.markdown
          : markdown // ignore: cast_nullable_to_non_nullable
              as String,
      html: freezed == html
          ? _value.html
          : html // ignore: cast_nullable_to_non_nullable
              as String?,
      editMode: null == editMode
          ? _value.editMode
          : editMode // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$PinEditStateImpl implements _PinEditState {
  const _$PinEditStateImpl(
      {required this.title,
      required this.link,
      this.markdown = '',
      this.html = null,
      this.editMode = false});

  @override
  final String title;
  @override
  final String link;
  @override
  @JsonKey()
  final String markdown;
  @override
  @JsonKey()
  final String? html;
  @override
  @JsonKey()
  final bool editMode;

  @override
  String toString() {
    return 'PinEditState(title: $title, link: $link, markdown: $markdown, html: $html, editMode: $editMode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PinEditStateImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.link, link) || other.link == link) &&
            (identical(other.markdown, markdown) ||
                other.markdown == markdown) &&
            (identical(other.html, html) || other.html == html) &&
            (identical(other.editMode, editMode) ||
                other.editMode == editMode));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, title, link, markdown, html, editMode);

  /// Create a copy of PinEditState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PinEditStateImplCopyWith<_$PinEditStateImpl> get copyWith =>
      __$$PinEditStateImplCopyWithImpl<_$PinEditStateImpl>(this, _$identity);
}

abstract class _PinEditState implements PinEditState {
  const factory _PinEditState(
      {required final String title,
      required final String link,
      final String markdown,
      final String? html,
      final bool editMode}) = _$PinEditStateImpl;

  @override
  String get title;
  @override
  String get link;
  @override
  String get markdown;
  @override
  String? get html;
  @override
  bool get editMode;

  /// Create a copy of PinEditState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PinEditStateImplCopyWith<_$PinEditStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
