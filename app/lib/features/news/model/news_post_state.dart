import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:acter/features/news/model/news_slide_model.dart';

part 'news_post_state.freezed.dart';

@freezed
class NewsPostState with _$NewsPostState {
  const factory NewsPostState({
    UpdateSlideItem? currentUpdateSlide,
    @Default([]) List<UpdateSlideItem> newsSlideList,
    String? newsPostSpaceId,
  }) = _NewsPostState;
}
