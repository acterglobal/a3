
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:riverpod/riverpod.dart';

final currentNewsSlideProvider = StateProvider<NewsSlideItem?>((ref) => null);

final newSlideListProvider = Provider<NewSlideListNotifier>((ref) {
  return NewSlideListNotifier(ref: ref);
});

class NewSlideListNotifier extends StateNotifier<List<NewsSlideItem>> {
  final Ref ref;

  NewSlideListNotifier({
    required this.ref,
  }) : super([]);

  List<NewsSlideItem> getNewsList() {
    return state;
  }

  void addSlide(NewsSlideItem newsSlideModel) {
    state.add(newsSlideModel);
    ref.read(currentNewsSlideProvider.notifier).state = newsSlideModel;
  }

  void deleteSlide(int index) {
    state.removeAt(index);
    if (state.isEmpty) {
      ref.read(currentNewsSlideProvider.notifier).state = null;
    } else if (index == state.length) {
      ref.read(currentNewsSlideProvider.notifier).state = state[index - 1];
    } else {
      ref.read(currentNewsSlideProvider.notifier).state = state[index];
    }
  }
}
