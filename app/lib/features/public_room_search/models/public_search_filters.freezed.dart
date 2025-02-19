// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'public_search_filters.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PublicSearchFilters {
  String? get searchTerm => throw _privateConstructorUsedError;
  String? get server => throw _privateConstructorUsedError;
  FilterBy get filterBy => throw _privateConstructorUsedError;

  /// Create a copy of PublicSearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicSearchFiltersCopyWith<PublicSearchFilters> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicSearchFiltersCopyWith<$Res> {
  factory $PublicSearchFiltersCopyWith(
          PublicSearchFilters value, $Res Function(PublicSearchFilters) then) =
      _$PublicSearchFiltersCopyWithImpl<$Res, PublicSearchFilters>;
  @useResult
  $Res call({String? searchTerm, String? server, FilterBy filterBy});
}

/// @nodoc
class _$PublicSearchFiltersCopyWithImpl<$Res, $Val extends PublicSearchFilters>
    implements $PublicSearchFiltersCopyWith<$Res> {
  _$PublicSearchFiltersCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicSearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchTerm = freezed,
    Object? server = freezed,
    Object? filterBy = null,
  }) {
    return _then(_value.copyWith(
      searchTerm: freezed == searchTerm
          ? _value.searchTerm
          : searchTerm // ignore: cast_nullable_to_non_nullable
              as String?,
      server: freezed == server
          ? _value.server
          : server // ignore: cast_nullable_to_non_nullable
              as String?,
      filterBy: null == filterBy
          ? _value.filterBy
          : filterBy // ignore: cast_nullable_to_non_nullable
              as FilterBy,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewPublicSearchFiltersImplCopyWith<$Res>
    implements $PublicSearchFiltersCopyWith<$Res> {
  factory _$$NewPublicSearchFiltersImplCopyWith(
          _$NewPublicSearchFiltersImpl value,
          $Res Function(_$NewPublicSearchFiltersImpl) then) =
      __$$NewPublicSearchFiltersImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? searchTerm, String? server, FilterBy filterBy});
}

/// @nodoc
class __$$NewPublicSearchFiltersImplCopyWithImpl<$Res>
    extends _$PublicSearchFiltersCopyWithImpl<$Res,
        _$NewPublicSearchFiltersImpl>
    implements _$$NewPublicSearchFiltersImplCopyWith<$Res> {
  __$$NewPublicSearchFiltersImplCopyWithImpl(
      _$NewPublicSearchFiltersImpl _value,
      $Res Function(_$NewPublicSearchFiltersImpl) _then)
      : super(_value, _then);

  /// Create a copy of PublicSearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? searchTerm = freezed,
    Object? server = freezed,
    Object? filterBy = null,
  }) {
    return _then(_$NewPublicSearchFiltersImpl(
      searchTerm: freezed == searchTerm
          ? _value.searchTerm
          : searchTerm // ignore: cast_nullable_to_non_nullable
              as String?,
      server: freezed == server
          ? _value.server
          : server // ignore: cast_nullable_to_non_nullable
              as String?,
      filterBy: null == filterBy
          ? _value.filterBy
          : filterBy // ignore: cast_nullable_to_non_nullable
              as FilterBy,
    ));
  }
}

/// @nodoc

class _$NewPublicSearchFiltersImpl
    with DiagnosticableTreeMixin
    implements _NewPublicSearchFilters {
  const _$NewPublicSearchFiltersImpl(
      {this.searchTerm, this.server, this.filterBy = FilterBy.both});

  @override
  final String? searchTerm;
  @override
  final String? server;
  @override
  @JsonKey()
  final FilterBy filterBy;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'PublicSearchFilters(searchTerm: $searchTerm, server: $server, filterBy: $filterBy)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'PublicSearchFilters'))
      ..add(DiagnosticsProperty('searchTerm', searchTerm))
      ..add(DiagnosticsProperty('server', server))
      ..add(DiagnosticsProperty('filterBy', filterBy));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewPublicSearchFiltersImpl &&
            (identical(other.searchTerm, searchTerm) ||
                other.searchTerm == searchTerm) &&
            (identical(other.server, server) || other.server == server) &&
            (identical(other.filterBy, filterBy) ||
                other.filterBy == filterBy));
  }

  @override
  int get hashCode => Object.hash(runtimeType, searchTerm, server, filterBy);

  /// Create a copy of PublicSearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewPublicSearchFiltersImplCopyWith<_$NewPublicSearchFiltersImpl>
      get copyWith => __$$NewPublicSearchFiltersImplCopyWithImpl<
          _$NewPublicSearchFiltersImpl>(this, _$identity);
}

abstract class _NewPublicSearchFilters implements PublicSearchFilters {
  const factory _NewPublicSearchFilters(
      {final String? searchTerm,
      final String? server,
      final FilterBy filterBy}) = _$NewPublicSearchFiltersImpl;

  @override
  String? get searchTerm;
  @override
  String? get server;
  @override
  FilterBy get filterBy;

  /// Create a copy of PublicSearchFilters
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewPublicSearchFiltersImplCopyWith<_$NewPublicSearchFiltersImpl>
      get copyWith => throw _privateConstructorUsedError;
}
