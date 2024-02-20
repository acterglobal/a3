import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/model/util.dart';
import 'package:acter/features/search/providers/pins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinsBuilder extends ConsumerWidget {
  final NavigateTo navigateTo;

  const PinsBuilder({
    super.key,
    required this.navigateTo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundPins = ref.watch(pinsFoundProvider);
    return foundPins.when(
      loading: () => const Text('loading'),
      error: (e, st) => Text('error: $e'),
      data: (data) {
        final Widget body;
        if (data.isEmpty) {
          body = const Text('no matching pins found');
        } else {
          final List<Widget> children = data
              .map(
                (e) => InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        e.icon,
                        const SizedBox(width: 5),
                        Text(e.name),
                      ],
                    ),
                  ),
                  onTap: () async => await navigateTo(
                    Routes.pin,
                    pathParameters: {'pinId': e.navigationTargetId},
                    push: true,
                  ),
                ),
              )
              .toList();
          body = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: children),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            children: [
              const Text('Pins'),
              const SizedBox(height: 15),
              body,
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
