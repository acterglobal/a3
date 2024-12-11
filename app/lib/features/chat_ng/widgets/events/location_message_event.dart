import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show MsgContent;
import 'package:flutter/material.dart';

class LocationMessageEvent extends StatelessWidget {
  final MsgContent content;
  const LocationMessageEvent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final body = content.body();
    final geoUri = content.geoUri();
    return Container(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(body),
          Text(geoUri ?? ''),
        ],
      ),
    );
  }
}
