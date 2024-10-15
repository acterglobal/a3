import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/search/providers/pins.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::search::pins_builder');

class PinsBuilder extends ConsumerWidget {
  final bool popBeforeRoute;

  const PinsBuilder({
    super.key,
    required this.popBeforeRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final pinsLoader = ref.watch(pinsFoundProvider);
    return pinsLoader.when(
      loading: () => Text(lang.loading),
      error: (e, s) {
        _log.severe('Failed to search pins', e, s);
        return Text(lang.searchingFailed(e));
      },
      data: (pins) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Text(lang.pins),
            const SizedBox(height: 15),
            if (pins.isEmpty)
              Text(lang.noMatchingPinsFound)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: pins.map((pin) {
                    return InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            pin.icon,
                            const SizedBox(width: 5),
                            Text(pin.name),
                          ],
                        ),
                      ),
                      onTap: () {
                        if (popBeforeRoute) Navigator.pop(context);
                        context.pushNamed(
                          Routes.pin.name,
                          pathParameters: {'pinId': pin.navigationTargetId},
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
    );
  }
}
