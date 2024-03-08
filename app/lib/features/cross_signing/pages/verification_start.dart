import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class VerificationStartPage extends StatelessWidget {
  final bool passive;
  final Function(BuildContext) onCancel;

  const VerificationStartPage({
    super.key,
    required this.passive,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final title = passive ? 'Verify This Session' : 'Verify Other Session';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            flex: 1,
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
          const Flexible(
            flex: 3,
            child: Center(
              child: SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          const Flexible(
            flex: 1,
            child: Center(
              child: Text('Please wait…'),
            ),
          ),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
