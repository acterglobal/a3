import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/bookmarks/types.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/mock_pins_providers.dart';

void main() {
  group('Bookmarks are first', () {
    test('Pins', () async {
      final mockedPinsList = SimplyRetuningAsyncPinListNotifier([
        FakeActerPin(eventId: 'a'),
        FakeActerPin(eventId: 'b'),
        FakeActerPin(eventId: '1'),
        FakeActerPin(eventId: '2'),
        FakeActerPin(eventId: 'c'),
      ]);

      final container = ProviderContainer(
        overrides: [
          pinListProvider.overrideWith(() => mockedPinsList),
          bookmarkByTypeProvider.overrideWith(
            (a, b) => (b == BookmarkType.pins) ? ['2', '1', '3'] : [],
          ),
        ],
      );

      final pins = await container.read(pinsProvider(null).future);
      // check if they were reordered correctly
      expect(pins.map((e) => e.eventIdStr()), ['2', '1', 'a', 'b', 'c']);
    });
  });
}
