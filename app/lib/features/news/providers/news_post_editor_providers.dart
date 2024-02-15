import 'dart:math';
import 'package:acter/common/widgets/chat/chat_selector_drawer.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:acter/features/news/model/news_post_state.dart';
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
    selectedNewsSlide?.backgroundColor =
        Colors.primaries[Random().nextInt(Colors.primaries.length)];
    state = state.copyWith(
      currentNewsSlide: selectedNewsSlide,
    );
  }

  Future<void> changeNewsPostSpaceId(BuildContext context) async {
    final spaceId = await selectSpaceDrawer(
      context: context,
      canCheck: 'CanPostNews',
    );
    state = state.copyWith(
      newsPostSpaceId: spaceId,
    );
  }

  Future<void> changeInvitedSpaceId(BuildContext context) async {
    final spaceId = await selectSpaceDrawer(context: context);
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.invitedSpaceId = spaceId;
    state = state.copyWith(
      currentNewsSlide: selectedNewsSlide,
    );
  }

  Future<void> changeInvitedChatId(BuildContext context) async {
    final chatId = await selectChatDrawer(context: context);
    NewsSlideItem? selectedNewsSlide = state.currentNewsSlide;
    selectedNewsSlide?.invitedChatId = chatId;
    state = state.copyWith(
      currentNewsSlide: selectedNewsSlide,
    );
  }

  void changeTextSlideValue(String value) {
    state.currentNewsSlide?.text = value;
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
