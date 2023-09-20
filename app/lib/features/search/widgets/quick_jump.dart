import 'dart:async';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter/features/search/widgets/quick_actions_builder.dart';
import 'package:acter/features/search/widgets/spaces_builder.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QuickJump extends ConsumerWidget {
  final Future<void> Function({Routes? route, bool push, String? target})
      navigateTo;
  final bool expand;

  const QuickJump({
    super.key,
    this.expand = false,
    required this.navigateTo,
  });

  List<Widget> primaryButtons(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);
    return [
      ButtonBar(
        alignment: MainAxisAlignment.spaceEvenly,
        children: List.from(
          [
            IconButton(
              iconSize: 48,
              icon: const Icon(
                Atlas.construction_tools_thin,
                size: 32,
              ),
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () {
                navigateTo(route: Routes.settings);
              },
            ),
            isActive(LabsFeature.pins)
                ? IconButton(
                    iconSize: 48,
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () {
                      navigateTo(route: Routes.pins);
                    },
                    icon: const Icon(Atlas.pin_thin, size: 32),
                  )
                : null,
            isActive(LabsFeature.events)
                ? IconButton(
                    iconSize: 48,
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () {
                      navigateTo(route: Routes.calendarEvents);
                    },
                    icon: const Icon(Atlas.calendar_dots_thin, size: 32),
                  )
                : null,
            isActive(LabsFeature.tasks)
                ? IconButton(
                    iconSize: 48,
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () {
                      navigateTo(route: Routes.tasks);
                    },
                    icon: SvgPicture.asset(
                      'assets/images/tasks.svg',
                      semanticsLabel: 'tasks',
                      height: 32,
                      width: 32,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                  )
                : null,
            IconButton(
              iconSize: 48,
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () {
                navigateTo(route: Routes.chat);
              },
              icon: const Icon(
                Atlas.chats_thin,
                size: 32,
              ),
            ),
            IconButton(
              iconSize: 48,
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () {
                navigateTo(route: Routes.activities);
              },
              icon: const Icon(Atlas.audio_wave_thin, size: 32),
            ),
          ].where((element) => element != null),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(searchValueProvider);

    List<Widget> body = [SpacesBuilder(navigateTo: navigateTo)];
    if (searchValue.isEmpty) {
      body.add(
        const Divider(indent: 24, endIndent: 24),
      );
      body.addAll(primaryButtons(context, ref));
      if (expand) {
        body.add(const Spacer());
      } else {
        body.add(
          const Divider(indent: 24, endIndent: 24),
        );
      }
      body.add(QuickActionsBuilder(navigateTo: navigateTo));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(),
              prefixIcon: Icon(
                Atlas.magnifying_glass_thin,
                color: Colors.white,
              ),
              labelText: 'jump to',
            ),
            onChanged: (String value) async {
              ref.read(searchValueProvider.notifier).state = value;
            },
          ),
          ...body,
        ],
        // ),
      ),
    );
  }
}
