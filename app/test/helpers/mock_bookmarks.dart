import 'package:acter/features/bookmarks/providers/notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockedBookmarksManager extends Mock implements Bookmarks {}

class MockBookmarksManagerNotifier extends AsyncNotifier<Bookmarks>
    with Mock
    implements BookmarksManagerNotifier {
  final MockedBookmarksManager manager;

  MockBookmarksManagerNotifier({required this.manager});

  @override
  Future<Bookmarks> build() async => manager;
}
