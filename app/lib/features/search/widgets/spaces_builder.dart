import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/model/util.dart';
import 'package:acter/features/search/providers/spaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SpacesBuilder extends ConsumerWidget {
  final NavigateTo navigateTo;

  const SpacesBuilder({
    super.key,
    required this.navigateTo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundSpaces = ref.watch(spacesFoundProvider);
    return foundSpaces.when(
      loading: () => const Text('loading'),
      error: (e, st) => Text('error: $e'),
      data: (data) {
        final Widget body;
        if (data.isEmpty) {
          body = const Text('no matching spaces found');
        } else {
          final List<Widget> children = data
              .map(
                (e) => InkWell(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        e.icon,
                        const SizedBox(height: 3),
                        Text(e.name),
                      ],
                    ),
                  ),
                  onTap: () async => await navigateTo(
                    Routes.space,
                    pathParameters: {'spaceId': e.navigationTargetId},
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
              const Text('Spaces'),
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
