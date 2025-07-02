import 'dart:convert';

import 'package:acter/common/toolkit/html_editor/html_editor.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:super_clipboard/super_clipboard.dart';

/*
 * This file contains code derived from AppFlowy
 * Original source: https://github.com/AppFlowy-IO/AppFlowy
 * Licensed under AGPL-3.0
 * 
 * Modifications made: Derivative work/similar implementation of the custom clipboard service
 * Date of derivation: 27 June 2025
 */
const inAppJsonFormat = CustomValueFormat<String>(
  applicationId: 'io.appflowy.InAppJsonType',
  onDecode: _defaultDecode,
  onEncode: _defaultEncode,
);

class HtmlEditorClipboardServiceData {
  const HtmlEditorClipboardServiceData({this.richText, this.inAppJson});

  /// The [richText] is the formatted string.
  ///
  /// It should be used for pasting the formatted content from the clipboard.
  /// For example, copy the content in the browser, and paste it in the editor.
  final String? richText;

  /// The [inAppJson] is the json string of the editor nodes.
  ///
  /// It should be used for pasting the content in-app.
  /// For example, pasting the content from document A to document B.
  final String? inAppJson;
}

class HtmlEditorClipboardService {
  Future<void> setFormattedText(String text) async {
    final item = DataWriterItem();

    if (text.isNotEmpty) {
      final doc = defaultHtmlCodec.decode(text);
      if (doc.root.children.isNotEmpty) {
        final html = documentToHTML(doc);

        item.add(Formats.htmlText(html));
        // we don't plain text in-app but clipboard needs fallback as it fails on Android
        item.add(Formats.plainText(text));
        await SystemClipboard.instance?.write([item]);
      }
    }
  }

  Future<void> setPlainText(String text) async {
    final item = DataWriterItem();

    if (text.isNotEmpty) {
      item.add(Formats.plainText(text));
    }

    await SystemClipboard.instance?.write([item]);
  }

  Future<void> setInAppJson(String inAppJson) async {
    final item = DataWriterItem();

    if (inAppJson.isNotEmpty) {
      item.add(inAppJsonFormat(inAppJson));
    }

    await SystemClipboard.instance?.write([item]);
  }

  Future<HtmlEditorClipboardServiceData> getFormattedText() async {
    final reader = await SystemClipboard.instance?.read();

    if (reader == null) {
      return const HtmlEditorClipboardServiceData();
    }

    final html = await reader.readValue(Formats.htmlText);
    return HtmlEditorClipboardServiceData(richText: html);
  }

  Future<HtmlEditorClipboardServiceData> getInAppJson() async {
    final reader = await SystemClipboard.instance?.read();

    if (reader == null) {
      return const HtmlEditorClipboardServiceData();
    }

    final inAppJson = await reader.readValue(inAppJsonFormat);
    return HtmlEditorClipboardServiceData(inAppJson: inAppJson);
  }
}

/// The default decode function for the clipboard service.
Future<String?> _defaultDecode(Object value, String platformType) async {
  if (value is PlatformDataProvider) {
    final data = await value.getData(platformType);
    if (data is List<int>) {
      return utf8.decode(data, allowMalformed: true);
    }
    if (data is String) {
      return Uri.decodeFull(data);
    }
  }
  return null;
}

/// The default encode function for the clipboard service.
Future<Object> _defaultEncode(String value, String platformType) async {
  return utf8.encode(value);
}
