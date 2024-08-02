import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/providers/pins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::search::pins_builder');

class PinsBuilder extends ConsumerWidget {
  const PinsBuilder({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundPins = ref.watch(pinsFoundProvider);
    return foundPins.when(
      loading: () => Text(L10n.of(context).loading),
      error: (e, st) {
        _log.severe('Searching of pin list failed', e, st);
        return Text(L10n.of(context).error(e));
      },
      data: (data) {
        final Widget body;
        if (data.isEmpty) {
          body = Text(L10n.of(context).noMatchingPinsFound);
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
                  onTap: () async => context.pushNamed(
                    Routes.pin.name,
                    pathParameters: {'pinId': e.navigationTargetId},
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
              Text(L10n.of(context).pins),
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
