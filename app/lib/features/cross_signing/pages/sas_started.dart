import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class SasStartedPage extends StatelessWidget {
  final bool isVerifier;
  final Function(BuildContext) onCancel;

  const SasStartedPage({
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
          const SizedBox(height: 30),
          const SizedBox(
            height: 100,
            width: 100,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 30),
          const Text('Please wait…'),
          const SizedBox(height: 30),
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
