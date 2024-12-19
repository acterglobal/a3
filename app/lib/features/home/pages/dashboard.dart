import 'dart:io';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/features_nav_widget.dart';
import 'package:acter/features/home/widgets/important_activities_section.dart';
import 'package:acter/features/home/widgets/in_dashboard.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    return InDashboard(
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          floatingActionButtonLocation: Platform.isIOS
              ? FloatingActionButtonLocation.miniEndDocked
              : FloatingActionButtonLocation.miniEndFloat,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          appBar: _buildDashboardAppBar(context, client),
          floatingActionButton: manageQuickAddButton(context, ref),
          body: _buildDashboardBodyUI(context, ref),
        ),
      ),
    );
  }

  AppBar _buildDashboardAppBar(BuildContext context, Client client) {
    final lang = L10n.of(context);
    return AppBar(
      leading: !isDesktop
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset('assets/icon/acter.svg'),
            )
          : const SizedBox.shrink(),
      centerTitle: true,
      title: Text(isDesktop ? lang.myDashboard : lang.acter),
      actions: <Widget>[
        Visibility(
          // FIXME: Only show mobile / when bottom bar shown...
          visible: !client.isGuest(),
          replacement: InkWell(
            onTap: () => context.pushNamed(Routes.authLogin.name),
            child: ActerAvatar(
              options: AvatarOptions.DM(
                AvatarInfo(uniqueId: UniqueKey().toString()),
              ),
            ),
          ),
          child: InkWell(
            onTap: () => context.pushNamed(Routes.settings.name),
            child: const UserAvatarWidget(size: 20),
          ),
        ),
      ],
    );
  }

  SlotLayout manageQuickAddButton(BuildContext context, WidgetRef ref) {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        Breakpoints.small: SlotLayout.from(
          key: const Key('quick-add'),
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: (context) => quickAddActionUI(context, ref),
        ),
        Breakpoints.medium: SlotLayout.from(
          key: const Key('quick-add'),
          inAnimation: AdaptiveScaffold.bottomToTop,
          outAnimation: AdaptiveScaffold.topToBottom,
          builder: (context) => quickAddActionUI(context, ref),
        ),
      },
    );
  }

  FloatingActionButton quickAddActionUI(BuildContext context, WidgetRef ref) {
    final showQuickActions = ref.watch(quickActionVisibilityProvider);
    return FloatingActionButton.small(
      onPressed: () {
        ref.read(quickActionVisibilityProvider.notifier).state =
            !showQuickActions;
      },
      backgroundColor: Theme.of(context).primaryColor,
      child: Icon(showQuickActions ? Icons.close : Icons.add),
    );
  }

  Widget _buildDashboardBodyUI(BuildContext context, WidgetRef ref) {
    final hasSpaces = ref.watch(hasSpacesProvider);
    return SingleChildScrollView(
      child: hasSpaces
          ? Column(
              children: [
                FeaturesNavWidget(),
                ImportantActivitiesSection(),
                const SizedBox(height: 12),
                MyEventsSection(eventFilters: EventFilters.ongoing),
                MyTasksSection(limit: 5),
                MyEventsSection(
                  limit: 3,
                  eventFilters: EventFilters.upcoming,
                ),
                MySpacesSection(limit: 5),
              ],
            )
          : emptyState(context),
    );
  }

  Widget emptyState(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      heightFactor: 1.5,
      child: EmptyState(
        title: lang.youAreNotAMemberOfAnySpaceYet,
        subtitle: lang.createOrJoinSpaceDescription,
        image: 'assets/images/empty_home.svg',
        primaryButton: ActerPrimaryActionButton(
          onPressed: () => context.pushNamed(Routes.createSpace.name),
          child: Text(lang.createNewSpace),
        ),
        secondaryButton: OutlinedButton(
          onPressed: () => context.pushNamed(Routes.searchPublicDirectory.name),
          child: Text(lang.joinExistingSpace),
        ),
      ),
    );
  }
}
