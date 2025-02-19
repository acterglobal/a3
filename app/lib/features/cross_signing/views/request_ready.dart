import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class RequestReadyView extends StatelessWidget {
  final bool isVerifier;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onAccept;

  const RequestReadyView({
    super.key,
    required this.isVerifier,
    required this.onCancel,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: buildTitleBar(context),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Text(lang.verificationScanSelfNotice),
          ),
          const Spacer(),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(25),
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const Spacer(),
          Wrap(
            children: [
              ListTile(
                title: Text(lang.verificationScanEmojiTitle),
                subtitle: Text(lang.verificationScanSelfEmojiSubtitle),
                trailing: const Icon(Icons.keyboard_arrow_right_outlined),
                onTap: () => onAccept(context),
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    final lang = L10n.of(context);
    // has close button
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const SizedBox(width: 5),
        Text(isVerifier ? lang.verifyOtherSession : lang.verifyThisSession),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => onCancel(context),
          ),
        ),
      ],
    );
  }
}
