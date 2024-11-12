import 'dart:async';

import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:acter/features/comments/types.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';
import '../mock_data/mock_comments_manager.dart';

// Define a mock class for AsyncCommentsManagerNotifier
class MockAsyncCommentsManagerNotifier extends Mock
    implements AsyncCommentsManagerNotifier {
  @override
  FutureOr<CommentsManager> build(CommentsManagerProvider arg) async {
    return MockCommentsManager();
  }
}
