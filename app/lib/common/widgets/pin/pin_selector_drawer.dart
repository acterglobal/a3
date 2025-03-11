import 'package:acter/features/pins/pages/pins_list_page.dart';
import 'package:flutter/material.dart';

const Key selectPinDrawerKey = Key('select-pin-drawer');

Future<String?> selectPinDrawer({
  required BuildContext context,
  String? spaceId,
}) async {
  final pinId = await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    builder:
        (context) => PinsListPage(
          spaceId: spaceId,
          onSelectPinItem: (pinId) => Navigator.pop(context, pinId),
        ),
  );
  return pinId == '' ? null : pinId;
}
