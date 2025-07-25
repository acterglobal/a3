import 'package:acter/features/chat_ng/widgets/chat_editor/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSimplyMentions', () {
    test('works fine on plain text', () {
      final source = 'this is a simple source string';
      final parsed = parseSimplyMentions(source);
      expect(parsed.plainText, equals(source));
      expect(parsed.htmlText, equals(source));
      expect(parsed.userMentions, equals([]));
    });

    test('finds a mentions plain text', () {
      final source =
          'this is a simple source string, //cc <###@sari:acter.global###>';
      final parsed = parseSimplyMentions(source);
      expect(
        parsed.plainText,
        equals('this is a simple source string, //cc @sari:acter.global'),
      );
      expect(
        parsed.htmlText,
        equals(
          'this is a simple source string, //cc <a href="matrix:u/sari:acter.global">@sari:acter.global</a>',
        ),
      );
      expect(parsed.userMentions, equals(['@sari:acter.global']));
    });

    test('finds a mentions with double @', () {
      final source =
          'this is a simple source string, //cc <###@@sari:acter.global###>';
      final parsed = parseSimplyMentions(source);
      expect(
        parsed.plainText,
        equals('this is a simple source string, //cc @sari:acter.global'),
      );
      expect(
        parsed.htmlText,
        equals(
          'this is a simple source string, //cc <a href="matrix:u/sari:acter.global">@sari:acter.global</a>',
        ),
      );
      expect(parsed.userMentions, equals(['@sari:acter.global']));
    });
  });
}
