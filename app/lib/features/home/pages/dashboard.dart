import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/common/widgets/user_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/in_dashboard.dart';
import 'package:acter/features/home/widgets/my_events.dart';
import 'package:acter/features/home/widgets/my_spaces_section.dart';
import 'package:acter/features/home/widgets/my_tasks.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class Dashboard extends ConsumerWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(alwaysClientProvider);
    final spaces = ref.watch(spacesProvider);
    return InDashboard(
      child: SafeArea(
        child: Scaffold(
          appBar: _buildDashboardAppBar(context, client),
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: spaces.isEmpty
                  ? emptyState(context)
                  : Column(
                      children: [
                        searchWidget(context),
                        featuresNav(context),
                        const SizedBox(height: 20),
                        const MySpacesSection(limit: 5),
                        const SizedBox(height: 20),
                        const MyTasksSection(limit: 5),
                        const SizedBox(height: 28),
                        const MyEventsSection(limit: 5),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildDashboardAppBar(BuildContext context, Client client) {
    return AppBar(
      leading: !isDesktop
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: SvgPicture.asset('assets/icon/acter.svg'),
            )
          : const SizedBox.shrink(),
      centerTitle: true,
      title: isDesktop
          ? Text(L10n.of(context).myDashboard)
          : Text(L10n.of(context).acter),
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

  Widget searchWidget(BuildContext context) {
    return InkWell(
      onTap: () => context.goNamed(Routes.search.name),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Row(
          children: [
            const Icon(Icons.search),
            const SizedBox(width: 8),
            Text(L10n.of(context).search),
          ],
        ),
      ),
    );
  }

  Widget featuresNav(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            featuresNavItem(
              context: context,
              title: L10n.of(context).pins,
              iconData: Atlas.pin,
              color: Colors.orangeAccent,
              onTap: () => context.pushNamed(Routes.pins.name),
            ),
            const SizedBox(width: 20),
            featuresNavItem(
              context: context,
              title: L10n.of(context).events,
              iconData: Atlas.calendar_dots,
              color: Theme.of(context).colorScheme.primary,
              onTap: () => context.pushNamed(Routes.calendarEvents.name),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            featuresNavItem(
              context: context,
              title: L10n.of(context).tasks,
              iconData: Atlas.list,
              color: Colors.green,
              onTap: () => context.pushNamed(Routes.tasks.name),
            ),
            const SizedBox(width: 20),
            featuresNavItem(
              context: context,
              title: L10n.of(context).updates,
              iconData: Atlas.megaphone_thin,
              color: Colors.blueGrey,
              onTap: () => context.goNamed(Routes.updates.name),
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
                child: Icon(iconData, size: 16),
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
    return Center(
      heightFactor: 1.5,
      child: EmptyState(
        title: L10n.of(context).youAreNotAMemberOfAnySpaceYet,
        subtitle: L10n.of(context).createOrJoinSpaceDescription,
        image: 'assets/images/empty_home.svg',
        primaryButton: ActerPrimaryActionButton(
          onPressed: () => context.pushNamed(Routes.createSpace.name),
          child: Text(L10n.of(context).createNewSpace),
        ),
        secondaryButton: OutlinedButton(
          onPressed: () => context.pushNamed(Routes.searchPublicDirectory.name),
          child: Text(L10n.of(context).joinExistingSpace),
        ),
      ),
    );
  }
}
