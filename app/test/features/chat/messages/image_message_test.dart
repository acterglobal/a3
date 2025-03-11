import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/toolkit/errors/inline_error_button.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/image_message_builder.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:convenient_test_dev/convenient_test_dev.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/error_helpers.dart';
import '../../../helpers/mock_chat_providers.dart';
import '../../../helpers/test_util.dart';

class FixedOptionStringMock extends Mock implements OptionString {
  final String? result;

  FixedOptionStringMock(this.result);

  @override
  String? text() => result;
}

/// Mocked version of ActerSdk for test purposes
class RetryMediaConvoMock extends Mock implements Convo {
  bool shouldFail = true;
  @override
  Future<OptionString> mediaPath(String eventId, bool isThumb) async {
    if (shouldFail) {
      shouldFail = false;
      return FixedOptionStringMock('bad_path');
    }
    return FixedOptionStringMock(null);
  }
}

void main() {
  group('Image Fails to Load Error', () {
    testWidgets('shows error and retries', (tester) async {
      const imageMessage = ImageMessage(
        author: User(id: 'sender', firstName: 'userName'),
        remoteId: 'eventItem.uniqueId()',
        createdAt: 1234567,
        height: 20,
        id: 'eventId',
        name: 'msgContent.body()',
        size: 30,
        uri: 'msgContent.source()!.url()',
        width: 30,
      );

      await tester.pumpProviderWidget(
        overrides: [
          // Provider first provides a broken path to trigger the error
          // then null, so it would check for auto-download but not attempt
          chatProvider.overrideWith(
            () => MockAsyncConvoNotifier(retVal: RetryMediaConvoMock()),
          ),
          autoDownloadMediaProvider.overrideWith((a, b) => false),
        ],
        child: const ImageMessageBuilder(
          message: imageMessage,
          roomId: '!roomId',
          messageWidth: 100,
        ),
      );

      await tester.pumpWithRunAsyncUntil(
        () => findsOne.matches(find.byType(ActerInlineErrorButton), {}),
      );
      await tester.ensureInlineErrorWithRetryWorks();
    });
  });
}
