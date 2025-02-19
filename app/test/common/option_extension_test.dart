import 'package:acter/common/extensions/options.dart';
import 'package:flutter_test/flutter_test.dart';

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

    testWidgets('default on null', (tester) async {
      bool wasCalled = false;
      String? target;

      String? targetValue = target.map(
        (a) {
          wasCalled = true;
          return 'inner';
        },
        defaultValue: 'ok',
      );

      expect(wasCalled, false);
      expect(targetValue, 'ok');
    });

    testWidgets('default on null for async', (tester) async {
      bool wasCalled = false;
      String? target;

      String? targetValue = await target.mapAsync(
        (a) async {
          wasCalled = true;
          return 'inner';
        },
        defaultValue: 'ok',
      );

      expect(wasCalled, false);
      expect(targetValue, 'ok');
    });

    testWidgets('orElse on null', (tester) async {
      bool wasCalled = false;
      String? target;

      String? targetValue = target.map(
        (a) {
          wasCalled = true;
          return 'inner';
        },
        orElse: () => 'ok',
      );

      expect(wasCalled, false);
      expect(targetValue, 'ok');
    });

    testWidgets('default on null for async', (tester) async {
      bool wasCalled = false;
      String? target;

      String? targetValue = await target.mapAsync(
        (a) async {
          wasCalled = true;
          return 'inner';
        },
        orElse: () => 'ok',
      );

      expect(wasCalled, false);
      expect(targetValue, 'ok');
    });
  });

  group('Option Expect', () {
    testWidgets('expect', (tester) async {
      String? target = 'jo';

      String targetValue = target.expect('error');

      expect(targetValue, 'jo');
    });
    testWidgets('expect throws', (tester) async {
      String? target;

      expect(
        () => target.expect('my custom error'),
        throwsA(predicate((e) => e == 'my custom error')),
      );
      expect(
        () => target.expect('totally custom'),
        throwsA(predicate((e) => e == 'totally custom')),
      );
    });
  });
}
