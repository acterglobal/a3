import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/extensions/options.dart';

void main() {
  group('Option Map Tests', () {
    testWidgets('map is not called on null', (tester) async {
      bool wasCalled = false;
      String? target;

      target.map((a) => wasCalled = true);

      expect(wasCalled, false);
    });
    testWidgets('map is called on string', (tester) async {
      bool wasCalled = false;
      String? target = 'asdf';

      target.map((a) => wasCalled = a == 'asdf');

      expect(wasCalled, true);
    });

    testWidgets('asyncMap is called on string', (tester) async {
      bool wasCalled = false;
      String? target = 'asdf';

      await target.mapAsync((a) async => wasCalled = a == 'asdf');

      expect(wasCalled, true);
    });
    testWidgets('asyncMap is not called on null', (tester) async {
      bool wasCalled = false;
      String? target;

      await target.mapAsync((a) async => wasCalled = true);

      expect(wasCalled, false);
    });
  });
}
