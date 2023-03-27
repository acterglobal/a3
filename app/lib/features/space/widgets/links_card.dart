import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/controllers/spaces_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:core';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

final pinnedLinksProvider =
    FutureProvider.family<List<ActerPin>, String>((ref, spaceId) async {
  final space = ref.watch(spaceProvider(spaceId)).requireValue;
  return (await space.pinnedLinks()).toList();
});

class LinksCard extends ConsumerWidget {
  final String spaceId;
  const LinksCard({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pins = ref.watch(pinnedLinksProvider(spaceId));

    return Card(
      elevation: 0,
      child: Column(
        children: [
          const ListTile(title: Text('Links')),
          ...pins.when(
            data: (pins) => pins.map(
              (pin) => OutlinedButton(
                onPressed: () async {
                  final target = pin.url()!;
                  final Uri? url = Uri.tryParse(target);
                  if (url == null) {
                    print('Opening internally: $url');
                    // not a valid URL, try local routing
                    context.go(target);
                  } else {
                    print('Opening external URL: $url');
                    !await launchUrl(url);
                  }
                },
                child: Text(pin.title()),
              ),
            ),
            error: (error, stack) => [Text('Loading pins failed: $error')],
            loading: () => [const Text('Loading')],
          )
        ],
      ),
    );
  }
}
