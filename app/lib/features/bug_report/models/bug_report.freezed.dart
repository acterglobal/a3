// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bug_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

/// @nodoc
mixin _$BugReport {
  String get description => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  bool get withLog => throw _privateConstructorUsedError;
  bool get withScreenshot => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $BugReportCopyWith<BugReport> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BugReportCopyWith<$Res> {
  factory $BugReportCopyWith(BugReport value, $Res Function(BugReport) then) =
      _$BugReportCopyWithImpl<$Res, BugReport>;
  @useResult
  $Res call(
      {String description,
      List<String> tags,
      bool withLog,
      bool withScreenshot});
}

/// @nodoc
class _$BugReportCopyWithImpl<$Res, $Val extends BugReport>
    implements $BugReportCopyWith<$Res> {
  _$BugReportCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? tags = null,
    Object? withLog = null,
    Object? withScreenshot = null,
  }) {
    return _then(_value.copyWith(
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      withLog: null == withLog
          ? _value.withLog
          : withLog // ignore: cast_nullable_to_non_nullable
              as bool,
      withScreenshot: null == withScreenshot
          ? _value.withScreenshot
          : withScreenshot // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BugReportImplCopyWith<$Res>
    implements $BugReportCopyWith<$Res> {
  factory _$$BugReportImplCopyWith(
          _$BugReportImpl value, $Res Function(_$BugReportImpl) then) =
      __$$BugReportImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String description,
      List<String> tags,
      bool withLog,
      bool withScreenshot});
}

/// @nodoc
class __$$BugReportImplCopyWithImpl<$Res>
    extends _$BugReportCopyWithImpl<$Res, _$BugReportImpl>
    implements _$$BugReportImplCopyWith<$Res> {
  __$$BugReportImplCopyWithImpl(
      _$BugReportImpl _value, $Res Function(_$BugReportImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? description = null,
    Object? tags = null,
    Object? withLog = null,
    Object? withScreenshot = null,
  }) {
    return _then(_$BugReportImpl(
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      withLog: null == withLog
          ? _value.withLog
          : withLog // ignore: cast_nullable_to_non_nullable
              as bool,
      withScreenshot: null == withScreenshot
          ? _value.withScreenshot
          : withScreenshot // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$BugReportImpl implements _BugReport {
  const _$BugReportImpl(
      {required this.description,
      required final List<String> tags,
      this.withLog = false,
      this.withScreenshot = false})
      : _tags = tags;

  @override
  final String description;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  @JsonKey()
  final bool withLog;
  @override
  @JsonKey()
  final bool withScreenshot;

  @override
  String toString() {
    return 'BugReport(description: $description, tags: $tags, withLog: $withLog, withScreenshot: $withScreenshot)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BugReportImpl &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.withLog, withLog) || other.withLog == withLog) &&
            (identical(other.withScreenshot, withScreenshot) ||
                other.withScreenshot == withScreenshot));
  }

  @override
  int get hashCode => Object.hash(runtimeType, description,
      const DeepCollectionEquality().hash(_tags), withLog, withScreenshot);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BugReportImplCopyWith<_$BugReportImpl> get copyWith =>
      __$$BugReportImplCopyWithImpl<_$BugReportImpl>(this, _$identity);
}

abstract class _BugReport implements BugReport {
  const factory _BugReport(
      {required final String description,
      required final List<String> tags,
      final bool withLog,
      final bool withScreenshot}) = _$BugReportImpl;

  @override
  String get description;
  @override
  List<String> get tags;
  @override
  bool get withLog;
  @override
  bool get withScreenshot;
  @override
  @JsonKey(ignore: true)
  _$$BugReportImplCopyWith<_$BugReportImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
