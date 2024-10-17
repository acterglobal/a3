import 'package:flutter/rendering.dart';

import 'package:appflowy_acter_plugins/appflowy_acter_plugins.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';

enum LinkPreviewRegex { title, description, image }

class LinkPreviewData {
  factory LinkPreviewData.fromPreviewData(PreviewData data) => LinkPreviewData(
        title: data.title,
        description: data.description,
        imageUrl: data.image?.url,
      );

  factory LinkPreviewData.fromJson(Map<String, dynamic> json) =>
      LinkPreviewData(
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
      );

  const LinkPreviewData({this.title, this.description, this.imageUrl});

  final String? title;
  final String? description;
  final String? imageUrl;

  Map<String, dynamic> toJson() =>
      {'title': title, 'description': description, 'imageUrl': imageUrl};
}

/// Parse the url link to get the title, description, image
class LinkPreviewParser {
  LinkPreviewParser({required this.url, this.cache});

  final String url;
  final LinkPreviewDataCacheInterface? cache;

  LinkPreviewData? metadata;

  /// must call this method before using the other methods
  Future<void> start() async {
    try {
      metadata = await cache?.get(url);
      if (metadata != null) {
        // Refresh the cache on background
        return getPreviewData(url).then(
          (data) => cache?.set(url, LinkPreviewData.fromPreviewData(data)),
        );
      }
      metadata = LinkPreviewData.fromPreviewData(await getPreviewData(url));
      cache?.set(url, metadata!);
    } catch (e, s) {
      debugPrint('$e\n$s');
      metadata = null;
    }
  }

  String? getContent(LinkPreviewRegex regex) {
    if (metadata == null) {
      return null;
    }

    return switch (regex) {
      LinkPreviewRegex.title => metadata?.title,
      LinkPreviewRegex.description => metadata?.description,
      LinkPreviewRegex.image => metadata?.imageUrl,
    };
  }
}
