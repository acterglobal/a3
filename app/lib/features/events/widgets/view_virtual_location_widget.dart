import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewVirtualLocationWidget extends ConsumerWidget {
  final BuildContext context;
  final EventLocationInfo location;

  const ViewVirtualLocationWidget({
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
                if (location.notes() != null && location.notes()!.isNotEmpty)
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
      leading: const Icon(Icons.language),
      title: Text(location.name() ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            maxLines: 2,
            location.uri() ?? '',
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
              child: Text(L10n.of(context).copyLinkOnly),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ActerPrimaryActionButton(
              onPressed: () {
                _openInBrowser();
              },
              child: Text(L10n.of(context).openLink),
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    final url = location.uri().toString();
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(L10n.of(context).copyToClipboard),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openInBrowser() {
    final url = location.uri() ?? '';
    if (url.isNotEmpty) {
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      launchUrl(
        Uri.parse(formattedUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}
