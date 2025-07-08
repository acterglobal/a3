import 'package:acter/features/activities/providers/notifiers/activities_notifiers.dart';

class FakeAllActivitiesNotifier extends AllActivitiesNotifier {
  bool loadMoreCalled = false;
  bool _hasMoreData;

  FakeAllActivitiesNotifier({bool hasMore = true}) : _hasMoreData = hasMore;

  void setHasMore(bool hasMore) {
    _hasMoreData = hasMore;
  }
  
  @override
  bool get hasMore => _hasMoreData;
  
  @override
  Future<void> loadMoreActivities() async {
    loadMoreCalled = true;
  }

  @override
  Future<List<RoomActivitiesInfo>> build() async {
    // Return a non-empty list to ensure scroll area
    return List.generate(5, (i) => (roomId: 'Room $i', activities: []));
  }
}