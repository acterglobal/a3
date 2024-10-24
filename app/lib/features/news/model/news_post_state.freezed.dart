// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'news_post_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$NewsPostState {
  NewsSlideItem? get currentNewsSlide => throw _privateConstructorUsedError;
  List<NewsSlideItem> get newsSlideList => throw _privateConstructorUsedError;
  String? get newsPostSpaceId => throw _privateConstructorUsedError;

  /// Create a copy of NewsPostState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NewsPostStateCopyWith<NewsPostState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NewsPostStateCopyWith<$Res> {
  factory $NewsPostStateCopyWith(
          NewsPostState value, $Res Function(NewsPostState) then) =
      _$NewsPostStateCopyWithImpl<$Res, NewsPostState>;
  @useResult
  $Res call(
      {NewsSlideItem? currentNewsSlide,
      List<NewsSlideItem> newsSlideList,
      String? newsPostSpaceId});
}

/// @nodoc
class _$NewsPostStateCopyWithImpl<$Res, $Val extends NewsPostState>
    implements $NewsPostStateCopyWith<$Res> {
  _$NewsPostStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NewsPostState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentNewsSlide = freezed,
    Object? newsSlideList = null,
    Object? newsPostSpaceId = freezed,
  }) {
    return _then(_value.copyWith(
      currentNewsSlide: freezed == currentNewsSlide
          ? _value.currentNewsSlide
          : currentNewsSlide // ignore: cast_nullable_to_non_nullable
              as NewsSlideItem?,
      newsSlideList: null == newsSlideList
          ? _value.newsSlideList
          : newsSlideList // ignore: cast_nullable_to_non_nullable
              as List<NewsSlideItem>,
      newsPostSpaceId: freezed == newsPostSpaceId
          ? _value.newsPostSpaceId
          : newsPostSpaceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NewsPostStateImplCopyWith<$Res>
    implements $NewsPostStateCopyWith<$Res> {
  factory _$$NewsPostStateImplCopyWith(
          _$NewsPostStateImpl value, $Res Function(_$NewsPostStateImpl) then) =
      __$$NewsPostStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {NewsSlideItem? currentNewsSlide,
      List<NewsSlideItem> newsSlideList,
      String? newsPostSpaceId});
}

/// @nodoc
class __$$NewsPostStateImplCopyWithImpl<$Res>
    extends _$NewsPostStateCopyWithImpl<$Res, _$NewsPostStateImpl>
    implements _$$NewsPostStateImplCopyWith<$Res> {
  __$$NewsPostStateImplCopyWithImpl(
      _$NewsPostStateImpl _value, $Res Function(_$NewsPostStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of NewsPostState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentNewsSlide = freezed,
    Object? newsSlideList = null,
    Object? newsPostSpaceId = freezed,
  }) {
    return _then(_$NewsPostStateImpl(
      currentNewsSlide: freezed == currentNewsSlide
          ? _value.currentNewsSlide
          : currentNewsSlide // ignore: cast_nullable_to_non_nullable
              as NewsSlideItem?,
      newsSlideList: null == newsSlideList
          ? _value._newsSlideList
          : newsSlideList // ignore: cast_nullable_to_non_nullable
              as List<NewsSlideItem>,
      newsPostSpaceId: freezed == newsPostSpaceId
          ? _value.newsPostSpaceId
          : newsPostSpaceId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NewsPostStateImpl implements _NewsPostState {
  const _$NewsPostStateImpl(
      {this.currentNewsSlide,
      final List<NewsSlideItem> newsSlideList = const [],
      this.newsPostSpaceId})
      : _newsSlideList = newsSlideList;

  @override
  final NewsSlideItem? currentNewsSlide;
  final List<NewsSlideItem> _newsSlideList;
  @override
  @JsonKey()
  List<NewsSlideItem> get newsSlideList {
    if (_newsSlideList is EqualUnmodifiableListView) return _newsSlideList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_newsSlideList);
  }

  @override
  final String? newsPostSpaceId;

  @override
  String toString() {
    return 'NewsPostState(currentNewsSlide: $currentNewsSlide, newsSlideList: $newsSlideList, newsPostSpaceId: $newsPostSpaceId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NewsPostStateImpl &&
            (identical(other.currentNewsSlide, currentNewsSlide) ||
                other.currentNewsSlide == currentNewsSlide) &&
            const DeepCollectionEquality()
                .equals(other._newsSlideList, _newsSlideList) &&
            (identical(other.newsPostSpaceId, newsPostSpaceId) ||
                other.newsPostSpaceId == newsPostSpaceId));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentNewsSlide,
      const DeepCollectionEquality().hash(_newsSlideList), newsPostSpaceId);

  /// Create a copy of NewsPostState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NewsPostStateImplCopyWith<_$NewsPostStateImpl> get copyWith =>
      __$$NewsPostStateImplCopyWithImpl<_$NewsPostStateImpl>(this, _$identity);
}

abstract class _NewsPostState implements NewsPostState {
  const factory _NewsPostState(
      {final NewsSlideItem? currentNewsSlide,
      final List<NewsSlideItem> newsSlideList,
      final String? newsPostSpaceId}) = _$NewsPostStateImpl;

  @override
  NewsSlideItem? get currentNewsSlide;
  @override
  List<NewsSlideItem> get newsSlideList;
  @override
  String? get newsPostSpaceId;

  /// Create a copy of NewsPostState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NewsPostStateImplCopyWith<_$NewsPostStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
