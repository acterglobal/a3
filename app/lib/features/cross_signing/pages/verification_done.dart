import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class VerificationDonePage extends StatelessWidget {
  final bool passive;
  final String sender;
  final Function(BuildContext) onDone;

  const VerificationDonePage({
    super.key,
    required this.sender,
    required this.passive,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text('Verified!'),
                ],
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                passive
                    ? 'Your new session is now verified. It has access to your encrypted messages, and other users will see it as trusted.'
                    : 'You’ve successfully verified $sender!',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Flexible(
            flex: 2,
            child: Center(
              child: Icon(Atlas.lock_keyhole),
            ),
          ),
          Flexible(
            flex: 1,
            child: Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.40,
                child: ElevatedButton(
                  child: const Text('Got it'),
                  onPressed: () => onDone(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
