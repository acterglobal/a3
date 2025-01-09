import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class FileShareOptions extends StatelessWidget {
  final String? sectionTitle;
  final GestureTapCallback? onTapOpen;
  final GestureTapCallback? onTapSave;
  final GestureTapCallback? onTapShare;

  const FileShareOptions({
    super.key,
    this.sectionTitle,
    this.onTapOpen,
    this.onTapSave,
    this.onTapShare,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sectionTitle != null) ...[
          Row(
            children: [
              Divider(indent: 0),
              Text(
                sectionTitle!,
                textAlign: TextAlign.start,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              Expanded(child: Divider(indent: 20)),
            ],
          ),
          SizedBox(height: 12),
        ],
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (onTapOpen != null)
                shareToItemUI(
                  name: lang.openFile,
                  iconData: PhosphorIcons.fileArrowUp(),
                  onTap: onTapOpen,
                ),
              if (onTapSave != null)
                shareToItemUI(
                  name: lang.save,
                  iconData: PhosphorIcons.downloadSimple(),
                  onTap: onTapSave,
                ),
              if (onTapShare != null)
                shareToItemUI(
                  name: lang.share,
                  iconData: PhosphorIcons.shareNetwork(),
                  onTap: onTapShare,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget shareToItemUI({
    required String name,
    required IconData iconData,
    GestureTapCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData),
            SizedBox(height: 6),
            Text(name),
          ],
        ),
      ),
    );
  }
}
