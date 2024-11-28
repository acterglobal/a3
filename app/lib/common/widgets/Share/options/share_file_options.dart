import 'dart:io';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ShareFileOptions extends StatelessWidget {
  final File file;
  final String? sectionTitle;
  final bool isShowOpenOption;
  final bool isShowSaveOption;
  final bool isShowShareOption;

  const ShareFileOptions({
    super.key,
    required this.file,
    this.sectionTitle,
    this.isShowOpenOption = true,
    this.isShowSaveOption = true,
    this.isShowShareOption = true,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          sectionTitle ?? lang.more,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            shareFileOptionItemUI(
              name: lang.openFile,
              iconData: PhosphorIcons.fileArrowUp(),
              onTap: () {},
            ),
            shareFileOptionItemUI(
              name: lang.save,
              iconData: PhosphorIcons.download(),
              onTap: () {},
            ),
            shareFileOptionItemUI(
              name: lang.share,
              iconData: PhosphorIcons.share(),
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget shareFileOptionItemUI({
    required String name,
    required IconData iconData,
    GestureTapCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
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
