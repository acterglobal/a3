import 'package:acter/common/themes/app_theme.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:acter/features/space/providers/space_providers.dart';
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Links',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              direction: Axis.horizontal,
              spacing: 10,
              runSpacing: 10,
              children: [
                ...pins.when(
                  data: (pins) => pins.map(
                    (pin) => OutlinedButton(
                      onPressed: () async {
                        final target = pin.url()!;
                        final Uri? url = Uri.tryParse(target);
                        if (url == null) {
                          debugPrint('Opening internally: $url');
                          // not a valid URL, try local routing
                          context.go(target);
                        } else {
                          debugPrint('Opening external URL: $url');
                          !await launchUrl(url);
                        }
                      },
                      style: ButtonStyle(
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.neutral4,
                              style: BorderStyle.solid,
                              strokeAlign: 5,
                            ),
                          ),
                        ),
                      ),
                      child: Text(
                        pin.title(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  error: (error, stack) =>
                      [Text('Loading pins failed: $error')],
                  loading: () => [const Text('Loading')],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
