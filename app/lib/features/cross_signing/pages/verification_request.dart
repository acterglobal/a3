import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class VerificationRequestPage extends StatelessWidget {
  final String sender;
  final bool passive;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onAccept;

  const VerificationRequestPage({
    super.key,
    required this.sender,
    required this.passive,
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
          Flexible(
            flex: isDesktop ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
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
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Text('$sender wants to verify your session'),
          ),
          const Spacer(flex: 1),
          const Flexible(
            flex: 3,
            child: Icon(Atlas.lock_keyhole),
          ),
          const Spacer(flex: 1),
          Flexible(
            flex: 1,
            child: buildBody(context),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    return ElevatedButton(
      child: const Text('Accept Request'),
      onPressed: () => onAccept(context),
    );
  }
}
