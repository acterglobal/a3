import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/event/event_selector_drawer.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/news/model/news_post_state.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

final newsStateProvider =
    StateNotifierProvider<NewsStateNotifier, NewsPostState>(
  (ref) => NewsStateNotifier(ref: ref),
);

class NewsStateNotifier extends StateNotifier<NewsPostState> {
  final Ref ref;

  NewsStateNotifier({
    required this.ref,
  }) : super(const NewsPostState());

  void changeTextSlideBackgroundColor() {
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.backgroundColor = getRandomElement(Colors.primaries);
    state = state.copyWith(
      currentNewsSlide: selectedNewsSlide,
    );
  }

  Future<void> changeNewsPostSpaceId(BuildContext context) async {
    final spaceId = await selectSpaceDrawer(
      context: context,
      canCheck: 'CanPostNews',
    );
    //Clear object reference if news post id gets changes
    state.currentNewsSlide?.newsReferencesModel = null;

    state = state.copyWith(
      newsPostSpaceId: spaceId,
    );
  }

  Future<void> selectEventToShare(BuildContext context) async {
    final eventId = await selectEventDrawer(
      context: context,
      spaceId: state.newsPostSpaceId!,
    );
    final newsSpaceReference = NewsReferencesModel(
      type: NewsReferencesType.calendarEvent,
      id: eventId,
    );
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.newsReferencesModel = newsSpaceReference;
    state = state.copyWith(
      currentNewsSlide: selectedNewsSlide,
    );
  }

  void changeTextSlideValue(String body, String? html) {
    state.currentNewsSlide?.text = body;
    state.currentNewsSlide?.html = html;
  }

  void changeSelectedSlide(NewsSlideItem newsSlideModel) {
    state = state.copyWith(
      currentNewsSlide: newsSlideModel,
    );
  }

  void addSlide(NewsSlideItem newsSlideModel) {
    List<NewsSlideItem> newsSlideList = [
      ...state.newsSlideList,
      newsSlideModel,
    ];
    state = state.copyWith(
      newsSlideList: newsSlideList,
      currentNewsSlide: newsSlideModel,
    );
  }

  void deleteSlide(int index) {
    List<NewsSlideItem> newsSlideList = [...state.newsSlideList];
    newsSlideList.removeAt(index);
    if (newsSlideList.isEmpty) {
      state =
          state.copyWith(newsSlideList: newsSlideList, currentNewsSlide: null);
    } else if (index == newsSlideList.length) {
      state = state.copyWith(
        newsSlideList: newsSlideList,
        currentNewsSlide: newsSlideList[index - 1],
      );
    } else {
      state = state.copyWith(
        newsSlideList: newsSlideList,
        currentNewsSlide: newsSlideList[index],
      );
    }
  }
}
