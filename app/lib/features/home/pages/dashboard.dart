import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/in_dashboard.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter/features/main/providers/main_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final hasSpaces = ref.watch(hasSpacesProvider);
    final showQuickActions = ref.watch(quickActionVisibilityProvider);
    return InDashboard(
      child: SafeArea(
        bottom: false,
        child: Scaffold(
          floatingActionButtonLocation:
              FloatingActionButtonLocation.miniEndFloat,
          floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          appBar: _buildDashboardAppBar(context, client),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () {
              if (showQuickActions) {
                ref.read(quickActionVisibilityProvider.notifier).state = false;
              } else {
                ref.read(quickActionVisibilityProvider.notifier).state = true;
              }
            },
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(showQuickActions ? Icons.close : Icons.add),
          ),
          body: Padding(
            padding: const EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: hasSpaces
                  ? Column(
                      children: [
                        featuresNav(context),
                        const SizedBox(height: 20),
                        const MyEventsSection(
                          eventFilters: EventFilters.ongoing,
                        ),
                        const SizedBox(height: 12),
                        const MyTasksSection(limit: 5),
                        const SizedBox(height: 20),
                        const MyEventsSection(
                          limit: 3,
                          eventFilters: EventFilters.upcoming,
                        ),
                        const MySpacesSection(limit: 5),
                      ],
                    )
                  : emptyState(context),
            ),
          ),
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

  Widget featuresNav(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            featuresNavItem(
              context: context,
              title: lang.pins,
              iconData: Atlas.pin,
              color: const Color(0xff7c4a4a),
              onTap: () => context.pushNamed(Routes.pins.name),
            ),
            const SizedBox(width: 20),
            featuresNavItem(
              context: context,
              title: lang.events,
              iconData: Atlas.calendar_dots,
              color: const Color(0xff206a9a),
              onTap: () => context.pushNamed(Routes.calendarEvents.name),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            featuresNavItem(
              context: context,
              title: lang.tasks,
              iconData: Atlas.list,
              color: const Color(0xff406c6e),
              onTap: () => context.pushNamed(Routes.tasks.name),
            ),
            const SizedBox(width: 20),
            featuresNavItem(
              context: context,
              title: lang.boosts,
              iconData: Atlas.megaphone_thin,
              color: Colors.blueGrey,
              onTap: () => context.pushNamed(Routes.updateList.name),
            ),
          ],
        ),
      ],
    );
  }

  Widget featuresNavItem({
    required BuildContext context,
    required String title,
    required IconData iconData,
    required Color color,
    required Function()? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.all(Radius.circular(100)),
                ),
                child: Icon(
                  iconData,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
        ),
      ),
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
