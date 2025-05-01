import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockComposeDraft extends Mock implements ComposeDraft {
  final String mockPlainText;
  final String? mockHtmlText;

  MockComposeDraft({required this.mockPlainText, this.mockHtmlText});

  @override
  String plainText() => mockPlainText;

  @override
  String? htmlText() => mockHtmlText;
}

class MockOptionComposeDraft extends Mock implements OptionComposeDraft {
  final MockComposeDraft? mockComposeDraft;

  MockOptionComposeDraft({this.mockComposeDraft});

  @override
  ComposeDraft? draft() => mockComposeDraft;
}
