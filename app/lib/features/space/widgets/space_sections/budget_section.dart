import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/edit_plain_description_sheet.dart';
import 'package:acter/features/space/widgets/space_sections/section_header.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class BudgetSection extends ConsumerWidget {
  final String spaceId;

  const BudgetSection({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              aboutLabel(context),
              ListTile(
                  title: Text('Today’s balance'),
                  subtitle: Text('€236,967.25')),
              ListTile(
                  title: Text('Total raised'), subtitle: Text('€236,967.25')),
              ListTile(
                  title: Text('Total disbursed'), subtitle: Text('22,000')),
              ListTile(
                title: Text('Estimated annual budget'),
                subtitle: Text('€55,984.11'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget aboutLabel(BuildContext context) {
    return SectionHeader(
      title: 'Budget',
      isShowSeeAllButton: true,
      onTapSeeAll: () {
        final Uri url = Uri.parse('https://www.climate2025.org');
        launchUrl(url);
      },
    );
  }
}
