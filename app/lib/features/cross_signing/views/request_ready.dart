import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text(
              'Scan the code with your other device or switch and scan with this device',
            ),
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
          // TextButton(
          //   onPressed: () {},
          //   child: const Row(
          //     mainAxisAlignment: MainAxisAlignment.center,
          //     children: [
          //       Padding(
          //         padding: EdgeInsets.all(8),
          //         child: Icon(Atlas.camera),
          //       ),
          //       Text('Scan with this device'),
          //     ],
          //   ),
          // ),
          // const Spacer(),
          Wrap(
            children: [
              ListTile(
                title: const Text('Can’t scan'),
                subtitle: const Text('Verify by comparing emoji instead'),
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
    // has close button
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const SizedBox(width: 5),
        Text(isVerifier ? 'Verify Other Session' : 'Verify This Session'),
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
