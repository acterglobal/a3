import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/search/widgets/chat_list_widget.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/widgets/event_list_widget.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:acter/features/search/model/keys.dart';
import 'package:acter/features/search/providers/quick_search_providers.dart';
import 'package:acter/features/spaces/providers/space_list_provider.dart';
import 'package:acter/features/spaces/widgets/space_list_widget.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter/features/tasks/widgets/task_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class QuickSearchPage extends ConsumerStatefulWidget {
  const QuickSearchPage({super.key});

  @override
  ConsumerState<QuickSearchPage> createState() => _QuickSearchPageState();
}

class _QuickSearchPageState extends ConsumerState<QuickSearchPage> {
  String get searchValue => ref.watch(quickSearchValueProvider);
  ValueNotifier<QuickSearchFilters> quickSearchFilters =
      ValueNotifier<QuickSearchFilters>(QuickSearchFilters.all);

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(centerTitle: false, title: Text(L10n.of(context).search));
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerSearchWidget(
          onChanged: (value) {
            final notifier = ref.read(quickSearchValueProvider.notifier);
            notifier.state = value;
          },
          onClear: () {
            final notifier = ref.read(quickSearchValueProvider.notifier);
            notifier.state = '';
          },
        ),
        ValueListenableBuilder(
          valueListenable: quickSearchFilters,
          builder: (context, showHeader, child) => filterChipsButtons(),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: quickSearchFilters,
            builder: (context, showHeader, child) => quickSearchSectionsUI(),
          ),
        ),
      ],
    );
  }

  Widget filterChipsButtons() {
    final lang = L10n.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Wrap(
          children: [
            FilterChip(
              selected: quickSearchFilters.value == QuickSearchFilters.all,
              label: Text(lang.all),
              onSelected:
                  (value) => quickSearchFilters.value = QuickSearchFilters.all,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: quickSearchFilters.value == QuickSearchFilters.spaces,
              label: Text(lang.spaces),
              onSelected:
                  (value) =>
                      quickSearchFilters.value = QuickSearchFilters.spaces,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: quickSearchFilters.value == QuickSearchFilters.chats,
              label: Text(lang.chats),
              onSelected:
                  (value) =>
                      quickSearchFilters.value = QuickSearchFilters.chats,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: quickSearchFilters.value == QuickSearchFilters.pins,
              label: Text(lang.pins),
              onSelected:
                  (value) => quickSearchFilters.value = QuickSearchFilters.pins,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: quickSearchFilters.value == QuickSearchFilters.events,
              label: Text(lang.events),
              onSelected:
                  (value) =>
                      quickSearchFilters.value = QuickSearchFilters.events,
            ),
            const SizedBox(width: 10),
            FilterChip(
              selected: quickSearchFilters.value == QuickSearchFilters.tasks,
              label: Text(lang.tasks),
              onSelected:
                  (value) =>
                      quickSearchFilters.value = QuickSearchFilters.tasks,
            ),
          ],
        ),
      ),
    );
  }

  Widget quickSearchSectionsUI() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (quickSearchFilters.value == QuickSearchFilters.all ||
              quickSearchFilters.value == QuickSearchFilters.spaces)
            SpaceListWidget(
              spaceListProvider: spaceListQuickSearchedProvider,
              limit: 3,
              showSectionHeader: true,
              onClickSectionHeader:
                  () => context.pushNamed(
                    Routes.spaces.name,
                    queryParameters: {'searchQuery': searchValue},
                  ),
            ),
          if (quickSearchFilters.value == QuickSearchFilters.all ||
              quickSearchFilters.value == QuickSearchFilters.chats)
            ChatListWidget(
              chatListProvider: chatListQuickSearchedProvider,
              limit: 3,
              showSectionHeader: true,
              onClickSectionHeader: () => context.goNamed(Routes.chat.name),
            ),
          if (quickSearchFilters.value == QuickSearchFilters.all ||
              quickSearchFilters.value == QuickSearchFilters.pins)
            PinListWidget(
              pinListProvider: pinListQuickSearchedProvider,
              limit: 3,
              searchValue: searchValue,
              showSectionHeader: true,
              onClickSectionHeader:
                  () => context.pushNamed(
                    Routes.pins.name,
                    queryParameters: {'searchQuery': searchValue},
                  ),
            ),
          if (quickSearchFilters.value == QuickSearchFilters.all ||
              quickSearchFilters.value == QuickSearchFilters.events)
            EventListWidget(
              limit: 3,
              listProvider: eventListQuickSearchedProvider,
              showSectionHeader: true,
              onClickSectionHeader:
                  () => context.pushNamed(
                    Routes.calendarEvents.name,
                    queryParameters: {'searchQuery': searchValue},
                  ),
            ),
          if (quickSearchFilters.value == QuickSearchFilters.all ||
              quickSearchFilters.value == QuickSearchFilters.tasks)
            TaskListWidget(
              limit: 3,
              taskListProvider: taskListQuickSearchedProvider,
              initiallyExpanded: false,
              showSectionHeader: true,
              onClickSectionHeader:
                  () => context.pushNamed(
                    Routes.tasks.name,
                    queryParameters: {'searchQuery': searchValue},
                  ),
            ),
        ],
      ),
    );
  }
}
