import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/features/public_room_search/widgets/maybe_direct_room_action_widget.dart';
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
import 'package:flutter_gen/gen_l10n/l10n.dart';

class QuickJump extends ConsumerStatefulWidget {
  final NavigateTo navigateTo;
  final bool expand;

  const QuickJump({
    super.key,
    this.expand = false,
    required this.navigateTo,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QuickJumpState();
}

class _QuickJumpState extends ConsumerState<QuickJump> {
  final searchTextController = TextEditingController();

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
              onPressed: () => widget.navigateTo(Routes.myProfile),
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
              onPressed: () => widget.navigateTo(Routes.settings),
            ),
            IconButton(
              key: QuickJumpKeys.pins,
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => widget.navigateTo(Routes.pins),
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Atlas.pin_thin, size: 24),
              ),
            ),
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => widget.navigateTo(Routes.calendarEvents),
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Atlas.calendar_dots_thin, size: 24),
              ),
            ),
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
                    onPressed: () => widget.navigateTo(Routes.tasks),

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
              onPressed: () => widget.navigateTo(Routes.chat),
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
              onPressed: () => widget.navigateTo(Routes.activities),
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
  Widget build(BuildContext context) {
    final searchValue = ref.watch(searchValueProvider);
    final h = MediaQuery.of(context).size.height;

    final hasSearchTerm = searchValue.isNotEmpty;

    List<Widget> body = [
      MaybeDirectRoomActionWidget(searchVal: searchValue),
      SpacesBuilder(navigateTo: widget.navigateTo),
      PinsBuilder(navigateTo: widget.navigateTo),
    ];
    if (!hasSearchTerm) {
      body.add(
        const Divider(indent: 24, endIndent: 24),
      );
      body.addAll(primaryButtons(context, ref));
      if (widget.expand) {
        body.add(const Spacer());
      } else {
        body.add(
          const Divider(indent: 24, endIndent: 24),
        );
      }
      body.add(QuickActionsBuilder(navigateTo: widget.navigateTo));
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
                  child: SearchBar(
                    controller: searchTextController,
                    leading: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Atlas.magnifying_glass),
                    ),
                    hintText: L10n.of(context).jumpTo,
                    trailing: hasSearchTerm
                        ? [
                            InkWell(
                              onTap: () {
                                searchTextController.clear();
                                ref.read(searchValueProvider.notifier).state =
                                    '';
                              },
                              child: const Icon(Icons.clear),
                            ),
                          ]
                        : null,
                    onChanged: (value) {
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
