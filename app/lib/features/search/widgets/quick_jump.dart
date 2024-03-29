import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/search/model/util.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter/features/search/widgets/pins_builder.dart';
import 'package:acter/features/search/widgets/quick_actions_builder.dart';
import 'package:acter/features/search/widgets/spaces_builder.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QuickJump extends ConsumerWidget {
  final NavigateTo navigateTo;
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
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: List.from(
          [
            IconButton(
              key: QuickJumpKeys.profile,
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Atlas.account_thin,
                  size: 24,
                ),
              ),
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => navigateTo(Routes.myProfile),
            ),
            IconButton(
              key: QuickJumpKeys.settings,
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Atlas.construction_tools_thin,
                  size: 24,
                ),
              ),
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => navigateTo(Routes.settings),
            ),
            isActive(LabsFeature.pins)
                ? IconButton(
                    key: QuickJumpKeys.pins,
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () => navigateTo(Routes.pins),
                    icon: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Atlas.pin_thin, size: 24),
                    ),
                  )
                : null,
            isActive(LabsFeature.events)
                ? IconButton(
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () => navigateTo(Routes.calendarEvents),
                    icon: const Padding(
                      padding: EdgeInsets.all(5),
                      child: Icon(Atlas.calendar_dots_thin, size: 24),
                    ),
                  )
                : null,
            isActive(LabsFeature.tasks)
                ? IconButton(
                    key: QuickJumpKeys.tasks,
                    style: IconButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.12),
                      ),
                    ),
                    onPressed: () => navigateTo(Routes.tasks),

                    // this is slightly differently sized and padded to look the same as the others
                    icon: const TasksIcon(),
                  )
                : null,
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => navigateTo(Routes.chat),
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  Atlas.chats_thin,
                  size: 24,
                ),
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => navigateTo(Routes.activities),
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Atlas.audio_wave_thin, size: 24),
              ),
            ),
          ].where((element) => element != null),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(searchValueProvider);
    final h = MediaQuery.of(context).size.height;

    List<Widget> body = [
      SpacesBuilder(navigateTo: navigateTo),
      PinsBuilder(navigateTo: navigateTo),
    ];
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: h * 0.9,
            constraints: BoxConstraints(maxHeight: h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 15,
                  ),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Atlas.magnifying_glass_thin,
                        color: Theme.of(context).colorScheme.neutral6,
                        size: 18,
                      ),
                      hintText: 'jump to',
                    ),
                    onChanged: (String value) async {
                      ref.read(searchValueProvider.notifier).state = value;
                    },
                  ),
                ),
                ...body,
              ],
              // ),
            ),
          ),
        ),
      ),
    );
  }
}
