import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SasStartedView extends StatelessWidget {
  final bool isVerifier;
  final Function(BuildContext) onCancel;

  const SasStartedView({
    super.key,
    required this.isVerifier,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(
            height: 100,
            width: 100,
            child: CircularProgressIndicator(),
          ),
          const Spacer(),
          Text(L10n.of(context).pleaseWait),
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
