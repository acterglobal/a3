import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewPhysicalLocationWidget extends ConsumerWidget {
  final BuildContext context;
  final EventLocationInfo location;

  const ViewPhysicalLocationWidget({
    super.key,
    required this.context,
    required this.location,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationInfo(),
                const SizedBox(height: 10),
                _buildLocationNotes(),
              ],
            ),
          ),
        ),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return ListTile(
      leading: const Icon(Icons.map_outlined),
      title: Text(location.name().toString()),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            maxLines: 2,
            location.address() ?? '',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colorScheme.surfaceTint),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationNotes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${L10n.of(context).notes}:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              location.notes() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.surfaceTint,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                _copyToClipboard();
              },
              child: Text(L10n.of(context).copyOnly),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ActerPrimaryActionButton(
              onPressed: () {
                _openInMap();
              },
              child: Text(L10n.of(context).showOnMap),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    final name = location.name();
    final address = location.description()?.body() ?? '';
    final textToCopy = '${L10n.of(context).name}: $name\n${L10n.of(context).address}: $address';
    Clipboard.setData(ClipboardData(text: textToCopy));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context).copyToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openInMap() {
    final name = location.name();
    final address = location.description()?.body() ?? '';
    final url = 'https://www.google.com/maps/search/?api=1&query=$name,$address';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}
