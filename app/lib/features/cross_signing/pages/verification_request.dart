import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class VerificationRequestPage extends StatelessWidget {
  final String sender;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onAccept;

  const VerificationRequestPage({
    super.key,
    required this.sender,
    required this.onCancel,
    required this.onAccept,
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
          const SizedBox(height: 30),
          Text('$sender wants to verify your session'),
          const SizedBox(height: 30),
          const Icon(Atlas.lock_keyhole),
          const SizedBox(height: 30),
          ElevatedButton(
            child: const Text('Accept Request'),
            onPressed: () => onAccept(context),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    // has close button
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const Text('Verification Request'),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => onCancel(context),
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
