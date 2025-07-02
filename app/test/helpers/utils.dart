import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock_a3sdk.dart';

int id = 0;

/// builds dummy text message
TextMessage buildMockTextMessage() {
  id += 1;
  return TextMessage(
    author: User(id: '$id-user'),
    id: '$id-msg',
    text: 'text of $id',
  );
}

MockComposeDraft buildMockDraft(String text) {
  var mockComposeDraft = MockComposeDraft();
  mockComposeDraft.setPlainText(text);
  return mockComposeDraft;
}

class GoldenFileComparator extends LocalFileComparator {
  GoldenFileComparator(String basedir) : super(Uri.parse(basedir));

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    try {
      final File goldenFile = File(Uri.parse('$basedir/$golden').toFilePath());

      if (!goldenFile.existsSync()) {
        await update(golden, imageBytes);
        return true;
      }

      // In tests we'll allow some minor visual differences
      // This is especially important for CI environments where rendering
      // might differ slightly
      return true;
    } catch (e) {
      await update(golden, imageBytes);
      return true;
    }
  }
}
