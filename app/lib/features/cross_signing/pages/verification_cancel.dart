import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class VerificationCancelPage extends StatelessWidget {
  final String sender;
  final bool passive;
  final String? message;
  final Function(BuildContext) onDone;

  const VerificationCancelPage({
    super.key,
    required this.sender,
    required this.passive,
    this.message,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final title = passive ? 'Verify This Session' : 'Verify Other Session';
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
          Flexible(
            flex: isDesktop ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
                  ),
                  const SizedBox(width: 5),
                  Text(title),
                  const Spacer(),
                ],
              ),
            ),
          ),
          const Spacer(flex: 1),
          const Flexible(
            flex: 3,
            child: Icon(Atlas.lock_keyhole),
          ),
          Flexible(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(message ?? fallbackMsg),
            ),
          ),
          const Spacer(flex: 1),
          Flexible(
            flex: 1,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: ElevatedButton(
                child: const Text('Got it'),
                onPressed: () => onDone(context),
              ),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
