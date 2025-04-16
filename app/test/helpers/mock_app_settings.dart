import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockActerAppSettings extends Mock implements ActerAppSettings {
  final bool newsActive;
  final bool storiesActive;
  final bool pinsActive;
  final bool tasksActive;
  final bool eventsActive;

  MockActerAppSettings({
    this.newsActive = false,
    this.storiesActive = false,
    this.pinsActive = false,
    this.tasksActive = false,
    this.eventsActive = false,
  });

  @override
  NewsSettings news() => MockNewsSettings(on: newsActive);

  @override
  StoriesSettings stories() => MockStoriesSettings(on: storiesActive);

  @override
  PinsSettings pins() => MockPinsSettings(on: pinsActive);

  @override
  TasksSettings tasks() => MockTasksSettings(on: tasksActive);

  @override
  EventsSettings events() => MockEventsSettings(on: eventsActive);
}

class MockNewsSettings extends Mock implements NewsSettings {
  final bool on;
  MockNewsSettings({this.on = false});
  @override
  bool active() => on;
}

class MockStoriesSettings extends Mock implements StoriesSettings {
  final bool on;
  MockStoriesSettings({this.on = false});
  @override
  bool active() => on;
}

class MockPinsSettings extends Mock implements PinsSettings {
  final bool on;
  MockPinsSettings({this.on = false});
  @override
  bool active() => on;
}

class MockTasksSettings extends Mock implements TasksSettings {
  final bool on;
  MockTasksSettings({this.on = false});
  @override
  bool active() => on;
}

class MockEventsSettings extends Mock implements EventsSettings {
  final bool on;
  MockEventsSettings({this.on = false});
  @override
  bool active() => on;
}
