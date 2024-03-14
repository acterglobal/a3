import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class SasCancelledPage extends StatelessWidget {
  final String sender;
  final bool isVerifier;
  final String? message;
  final Function(BuildContext) onDone;

  const SasCancelledPage({
    super.key,
    required this.sender,
    required this.isVerifier,
    this.message,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    const fallbackMsg =
        'One of the following may be compromised:\n\n   - Your homeserver\n   - The homeserver the user you’re verifying is connected to\n   - Yours, or the other users’ internet connection\n   - Yours, or the other users’ device';
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
          const Icon(Atlas.lock_keyhole),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(message ?? fallbackMsg),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: ElevatedButton(
              child: const Text('Got it'),
              onPressed: () => onDone(context),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    // has no close button
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const SizedBox(width: 5),
        Text(isVerifier ? 'Verify Other Session' : 'Verify This Session'),
      ],
    );
  }
}
