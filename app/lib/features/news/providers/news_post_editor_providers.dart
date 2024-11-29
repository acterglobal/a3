import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/event/event_selector_drawer.dart';
import 'package:acter/common/widgets/pin/pin_selector_drawer.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/common/widgets/task/taskList_selector_drawer.dart';
import 'package:acter/features/news/model/news_post_color_data.dart';
import 'package:acter/features/news/model/news_post_state.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:riverpod/riverpod.dart';

final newsStateProvider =
    StateNotifierProvider<NewsStateNotifier, NewsPostState>(
  (ref) => NewsStateNotifier(ref: ref),
);

class NewsStateNotifier extends StateNotifier<NewsPostState> {
  final Ref ref;

  NewsStateNotifier({required this.ref}) : super(const NewsPostState());

  void changeTextSlideBackgroundColor() {
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.backgroundColor = getRandomElement(newsPostColors);
    state = state.copyWith(currentNewsSlide: selectedNewsSlide);
  }

  Future<void> changeNewsPostSpaceId(BuildContext context) async {
    final spaceId = await selectSpaceDrawer(
      context: context,
      canCheck: 'CanPostNews',
    );
    //Clear object reference if news post id gets changes
    state.currentNewsSlide?.newsReferencesModel = null;
    for (final slide in state.newsSlideList) {
      slide.newsReferencesModel = null;
    }

    state = state.copyWith(newsPostSpaceId: spaceId);
  }

  void setSpaceId(String spaceId) {
    state = state.copyWith(newsPostSpaceId: spaceId);
  }

  void clear() {
    state = const NewsPostState();
  }

  bool isEmpty() {
    return state == const NewsPostState();
  }

  Future<void> selectEventToShare(BuildContext context) async {
    final lang = L10n.of(context);
    final newsPostSpaceId = state.newsPostSpaceId ??
        await selectSpaceDrawer(
          context: context,
          canCheck: 'CanPostNews',
        );
    state = state.copyWith(newsPostSpaceId: newsPostSpaceId);

    if (newsPostSpaceId == null) {
      EasyLoading.showToast(lang.pleaseFirstSelectASpace);
      return;
    }
    if (!context.mounted) {
      return;
    }
    final eventId = await selectEventDrawer(
      context: context,
      spaceId: newsPostSpaceId,
    );
    final newsSpaceReference = NewsReferencesModel(
      type: NewsReferencesType.calendarEvent,
      id: eventId,
    );
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.newsReferencesModel = newsSpaceReference;
    state = state.copyWith(currentNewsSlide: selectedNewsSlide);
  }

  Future<void> selectPinToShare(BuildContext context) async {
    final lang = L10n.of(context);
    final newsPostSpaceId = state.newsPostSpaceId ??
        await selectSpaceDrawer(
          context: context,
          canCheck: 'CanPostPin',
        );
    state = state.copyWith(newsPostSpaceId: newsPostSpaceId);

    if (newsPostSpaceId == null) {
      EasyLoading.showToast(lang.pleaseFirstSelectASpace);
      return;
    }
    if (!context.mounted) {
      return;
    }
    final pinId = await selectPinDrawer(
      context: context,
      spaceId: newsPostSpaceId,
    );
    final newsSpaceReference = NewsReferencesModel(
      type: NewsReferencesType.pin,
      id: pinId,
    );
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.newsReferencesModel = newsSpaceReference;
    state = state.copyWith(currentNewsSlide: selectedNewsSlide);
  }

  Future<void> selectTaskListToShare(BuildContext context) async {
    final lang = L10n.of(context);
    final newsPostSpaceId = state.newsPostSpaceId ??
        await selectSpaceDrawer(
          context: context,
          canCheck: 'CanPostTask',
        );
    state = state.copyWith(newsPostSpaceId: newsPostSpaceId);

    if (newsPostSpaceId == null) {
      EasyLoading.showToast(lang.pleaseFirstSelectASpace);
      return;
    }
    if (!context.mounted) {
      return;
    }
    final taskListId = await selectTaskListDrawer(
      context: context,
      spaceId: newsPostSpaceId,
    );
    final newsSpaceReference = NewsReferencesModel(
      type: NewsReferencesType.taskList,
      id: taskListId,
    );
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.newsReferencesModel = newsSpaceReference;
    state = state.copyWith(currentNewsSlide: selectedNewsSlide);
  }

  void changeTextSlideValue(String body, String? html) {
    state.currentNewsSlide?.text = body;
    state.currentNewsSlide?.html = html;
  }

  void changeSelectedSlide(NewsSlideItem newsSlideModel) {
    state = state.copyWith(currentNewsSlide: newsSlideModel);
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
      state = state.copyWith(
        newsSlideList: newsSlideList,
        currentNewsSlide: null,
      );
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
