import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/icons/tasks_icon.dart';
import 'package:acter/features/public_room_search/widgets/maybe_direct_room_action_widget.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/search/providers/search.dart';
import 'package:acter/features/search/widgets/pins_builder.dart';
import 'package:acter/features/search/widgets/quick_actions_builder.dart';
import 'package:acter/features/search/widgets/spaces_builder.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class QuickJump extends ConsumerStatefulWidget {
  final bool expand;
  final bool popBeforeRoute;

  const QuickJump({
    super.key,
    this.expand = false,
    this.popBeforeRoute = false,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _QuickJumpState();
}

class _QuickJumpState extends ConsumerState<QuickJump> {
  List<Widget> primaryButtons(BuildContext context, WidgetRef ref) {
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
              onPressed: () => routeTo(Routes.myProfile),
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
              onPressed: () => routeTo(Routes.settings),
            ),
            IconButton(
              key: QuickJumpKeys.pins,
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => routeTo(Routes.pins),
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
              onPressed: () => routeTo(Routes.calendarEvents),
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Atlas.calendar_dots_thin, size: 24),
              ),
            ),
            IconButton(
              key: QuickJumpKeys.tasks,
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => routeTo(Routes.tasks),

              // this is slightly differently sized and padded to look the same as the others
              icon: const TasksIcon(),
            ),
            IconButton(
              style: IconButton.styleFrom(
                side: BorderSide(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.12),
                ),
              ),
              onPressed: () => routeTo(Routes.chat),
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
              onPressed: () => routeTo(Routes.activities),
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(Atlas.audio_wave_thin, size: 24),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  void routeTo(Routes route) {
    if (widget.popBeforeRoute) {
      Navigator.pop(context);
    }
    context.pushNamed(route.name);
  }

  @override
  Widget build(BuildContext context) {
    final searchValue = ref.watch(searchValueProvider);
    final h = MediaQuery.of(context).size.height;

    final hasSearchTerm = searchValue.isNotEmpty;

    List<Widget> body = [
      MaybeDirectRoomActionWidget(searchVal: searchValue),
      SpacesBuilder(popBeforeRoute: widget.popBeforeRoute),
      PinsBuilder(popBeforeRoute: widget.popBeforeRoute),
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
      body.add(
        QuickActionsBuilder(
          popBeforeRoute: widget.popBeforeRoute,
        ),
      );
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
                ActerSearchWidget(
                  initialText: searchValue,
                  hintText: L10n.of(context).jumpTo,
                  onChanged: (String value) {
                    ref.read(searchValueProvider.notifier).state = value;
                  },
                  onClear: () {
                    ref.read(searchValueProvider.notifier).state = '';
                  },
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
