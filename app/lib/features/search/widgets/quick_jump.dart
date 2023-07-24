import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/search/providers/spaces.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';

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
              icon: const Icon(Atlas.construction_tools_thin),
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
                      width: 32,
                      height: 32,
                      color: Theme.of(context).colorScheme.onSurface,
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

  Widget quickActions(BuildContext context, WidgetRef ref) {
    final features = ref.watch(featuresProvider);
    bool isActive(f) => features.isActive(f);
    final canPostNews =
        ref.watch(hasSpaceWithPermissionProvider('CanPostNews')).valueOrNull ??
            false;
    final canPostPin = isActive(LabsFeature.pins) &&
        (ref.watch(hasSpaceWithPermissionProvider('CanPostPin')).valueOrNull ??
            false);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 8,
      runSpacing: 10,
      children: List.from(
        [
          canPostNews
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(width: 2, color: Colors.amber),
                  ),
                  onPressed: () {
                    navigateTo(route: Routes.actionAddUpdate, push: true);
                    debugPrint('Update');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Update'),
                )
              : null,
          isActive(LabsFeature.tasks)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber,
                    side: const BorderSide(width: 2, color: Colors.amber),
                  ),
                  onPressed: () {
                    navigateTo(route: Routes.actionAddTask, push: true);
                    debugPrint('Add Task');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Task'),
                )
              : null,
          canPostPin
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(width: 2, color: Colors.purple),
                  ),
                  onPressed: () => context.pushNamed(Routes.actionAddPin.name),
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Pin'),
                )
              : null,
          isActive(LabsFeature.events)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(width: 2, color: Colors.purple),
                  ),
                  onPressed: () => context.pushNamed(Routes.createEvent.name),
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Event'),
                )
              : null,
          isActive(LabsFeature.polls)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade900,
                    side: BorderSide(width: 2, color: Colors.green.shade900),
                  ),
                  onPressed: () {
                    debugPrint('poll');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Poll'),
                )
              : null,
          isActive(LabsFeature.discussions)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(width: 2, color: Colors.white),
                  ),
                  onPressed: () {
                    debugPrint('Discussion');
                  },
                  icon: const Icon(Atlas.plus_circle_thin),
                  label: const Text('Discussion'),
                )
              : null,
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(width: 2, color: Colors.greenAccent),
            ),
            icon: const Icon(Atlas.bug_clipboard_thin),
            label: const Text('Report bug'),
            onPressed: () => navigateTo(route: Routes.bugReport, push: true),
          ),
        ].where((element) => element != null),
      ),
    );
  }

  Widget spaces(BuildContext context, WidgetRef ref) {
    return ref.watch(spacesFoundProvider).when(
          loading: () => const Text('loading'),
          error: (e, st) => Text('error: $e'),
          data: (data) {
            final Widget body;
            if (data.isEmpty) {
              body = const Text('no matching spaces found');
            } else {
              final List<Widget> children = data
                  .map(
                    (e) => TextButton(
                      child: Column(
                        children: [
                          e.icon,
                          Text(e.name),
                        ],
                      ),
                      onPressed: () {
                        navigateTo(target: e.navigationTarget);
                      },
                    ),
                  )
                  .toList();
              body = SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: children,
                ),
              );
            }
            return Column(
              children: [
                const Text('Spaces'),
                body,
              ],
            );
          },
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(searchValueProvider);

    List<Widget> body = [spaces(context, ref)];
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
      body.add(quickActions(context, ref));
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
          ...body
        ],
        // ),
      ),
    );
  }
}
