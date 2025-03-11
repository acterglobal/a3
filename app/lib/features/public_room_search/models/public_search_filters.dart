import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'public_search_filters.freezed.dart';

enum FilterBy { spaces, chats, both }

@freezed
class PublicSearchFilters with _$PublicSearchFilters {
  const factory PublicSearchFilters({
    String? searchTerm,
    String? server,
    @Default(FilterBy.both) FilterBy filterBy,
  }) = _NewPublicSearchFilters;
}
