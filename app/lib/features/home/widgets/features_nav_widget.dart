import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class FeaturesNavWidget extends StatelessWidget {
  const FeaturesNavWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            children: [
              featuresNavItem(
                context: context,
                title: lang.pins,
                iconData: Atlas.pin,
                color: pinFeatureColor,
                onTap: () => context.pushNamed(Routes.pins.name),
              ),
              const SizedBox(width: 20),
              featuresNavItem(
                context: context,
                title: lang.events,
                iconData: Atlas.calendar_dots,
                color: eventFeatureColor,
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
                color: taskFeatureColor,
                onTap: () => context.pushNamed(Routes.tasks.name),
              ),
              const SizedBox(width: 20),
              featuresNavItem(
                context: context,
                title: lang.boosts,
                iconData: Atlas.megaphone_thin,
                color: boastFeatureColor,
                onTap: () => context.pushNamed(Routes.updateList.name),
              ),
            ],
          ),
        ],
      ),
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
}
