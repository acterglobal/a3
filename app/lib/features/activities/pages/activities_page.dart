import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/activities/providers/activities_providers.dart';
import 'package:acter/features/activities/widgets/invitation_section/invitation_section_widget.dart';
import 'package:acter/features/activities/widgets/security_and_privacy_section/security_and_privacy_section_widget.dart';
import 'package:acter/features/activities/widgets/space_activities_section/space_activities_section_widget.dart';
import 'package:acter/features/activities/widgets/sync_section/sync_state_section_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivitiesPage extends ConsumerWidget {
  const ActivitiesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<Widget> sectionWidgetList = [];

    // Syncing State Section
    final syncStateWidget = buildSyncingStateSectionWidget(context, ref);
    if (syncStateWidget != null) sectionWidgetList.add(syncStateWidget);

    // Invitation Section
    if (InvitationSectionWidget.shouldBeShown(ref)) {
      sectionWidgetList.add(const InvitationSectionWidget());
    }

    // Security and Privacy Section
    final securityWidget = buildSecurityAndPrivacySectionWidget(context, ref);
    if (securityWidget != null) {
      sectionWidgetList.add(securityWidget);
    }
    // Space Activities Section
    final spaceActivitiesWidget = buildSpaceActivitiesSectionWidget(
      context,
      ref,
    );
    if (spaceActivitiesWidget != null) {
      sectionWidgetList.add(spaceActivitiesWidget);
    }

    return Scaffold(
      appBar: buildActivityAppBar(context),
      body: buildActivityBody(context, ref, sectionWidgetList),
    );
  }

  AppBar buildActivityAppBar(BuildContext context) {
    final lang = L10n.of(context);
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(lang.activities),
    );
  }

  Widget buildActivityBody(
    BuildContext context,
    WidgetRef ref,
    List<Widget> sectionWidgetList,
  ) {
    final lang = L10n.of(context);
    final isActivityEmpty = sectionWidgetList.isEmpty;
    if (isActivityEmpty) return buildEmptyStateWidget(context);

    final hasMoreActivities = ref.watch(hasMoreActivitiesProvider);
    final isLoadingMore = ref.watch(isLoadingMoreActivitiesProvider);
    final loadMoreActivities = ref.watch(loadMoreActivitiesProvider);

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo is ScrollUpdateNotification) {
          final pixels = scrollInfo.metrics.pixels;
          final maxExtent = scrollInfo.metrics.maxScrollExtent;
          
          // Avoid division by zero and ensure we have scrollable content
          if (maxExtent <= 0) return false;
          
          final progress = pixels / maxExtent;
          
          // Check if conditions are met to load more activities
          final isNearBottom = progress >= 0.9;
          final canLoadMore = hasMoreActivities && !isLoadingMore;
          
          if (isNearBottom && canLoadMore) {
            // Trigger loading more activities
            loadMoreActivities();
          }
        }
        return false;
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sectionWidgetList,
            // Show loading indicator at the bottom when loading more activities
            if (isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        lang.loadingMoreActivities,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyStateWidget(BuildContext context) {
    final lang = L10n.of(context);
    return Center(
      heightFactor: 1.5,
      child: EmptyState(
        title: lang.noActivityTitle,
        subtitle: lang.noActivitySubtitle,
        image: 'assets/images/empty_activity.svg',
      ),
    );
  }
}
