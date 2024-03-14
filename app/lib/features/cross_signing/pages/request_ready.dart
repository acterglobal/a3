import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class RequestReadyPage extends StatelessWidget {
  final bool isVerifier;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onAccept;

  const RequestReadyPage({
    super.key,
    required this.isVerifier,
    required this.onCancel,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final title = isVerifier ? 'Verify Other Session' : 'Verify This Session';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 1,
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
          const Flexible(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              child: Text(
                'Scan the code with your other device or switch and scan with this device',
              ),
            ),
          ),
          const Flexible(
            flex: 2,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(25),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
          // Flexible(
          //   flex: 1,
          //   child: TextButton(
          //     onPressed: () {},
          //     child: const Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Padding(
          //           padding: EdgeInsets.all(8),
          //           child: Icon(Atlas.camera),
          //         ),
          //         Text('Scan with this device'),
          //       ],
          //     ),
          //   ),
          // ),
          Flexible(
            flex: 1,
            child: Wrap(
              children: [
                ListTile(
                  title: const Text('Can’t scan'),
                  subtitle: const Text('Verify by comparing emoji instead'),
                  trailing: const Icon(Icons.keyboard_arrow_right_outlined),
                  onTap: () => onAccept(context),
                ),
              ],
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
