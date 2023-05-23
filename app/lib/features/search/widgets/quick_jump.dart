import 'package:acter/features/settings/providers/labs_features.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

final searchValueProvider = StateProvider<String>((ref) => '');

class QuickJump extends ConsumerWidget {
  final void Function({Routes? route, bool push, String? target}) navigateTo;
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
            isActive(LabsFeature.tasks)
                ? IconButton(
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () => {
                      //navigateTo(route: Routes.tasks);
                    },
                    icon: SvgPicture.asset(
                      'assets/images/tasks.svg',
                      semanticsLabel: 'tasks',
                      width: 48,
                      height: 48,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                : null,
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Atlas.back_vr_thin, size: 48),
            ),
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Atlas.cabin_thin, size: 48),
            ),
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Atlas.dart_thin, size: 48),
            )
          ].where((element) => element != null),
        ),
      ),
      ButtonBar(
        alignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            style: IconButton.styleFrom(
              side: BorderSide(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Atlas.ear_muffs_thin, size: 48),
          ),
          IconButton(
            style: IconButton.styleFrom(
              side: BorderSide(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Atlas.face_mask_thin, size: 48),
          ),
          IconButton(
            style: IconButton.styleFrom(
              side: BorderSide(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Atlas.game_plan_thin, size: 48),
          ),
          IconButton(
            style: IconButton.styleFrom(
              side: BorderSide(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
              ),
            ),
            onPressed: () {},
            icon: const Icon(Atlas.hair_dryer_thin, size: 48),
          )
        ],
      ),
    ];
  }

  Widget quickActions(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(featuresProvider);
    bool isActive(f) => provider.isActive(f);
    return ButtonBar(
      alignment: MainAxisAlignment.center,
      children: List.from(
        [
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
          isActive(LabsFeature.events)
              ? OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.purple,
                    side: const BorderSide(width: 2, color: Colors.purple),
                  ),
                  onPressed: () {
                    debugPrint('Add Event');
                  },
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
        ].where((element) => element != null),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(searchValueProvider);

    List<Widget> body = [];

    if (searchValue.isNotEmpty) {
      // FIXME: add actual search results... at least spaces maybe?
      body.add(const SizedBox(height: 250));
    } else {
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
