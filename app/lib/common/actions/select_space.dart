import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/widgets/spaces/space_selector_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const Key selectSpaceDrawerKey = Key('space-widgets-select-space-drawer');

Future<String?> selectSpace({
  required BuildContext context,
  required WidgetRef ref,
  required String canCheck,
}) async {
  final newSelectedSpaceId = await selectSpaceDrawer(
    context: context,
    currentSpaceId: ref.read(selectedSpaceIdProvider),
    canCheck: canCheck,
    title: Text(L10n.of(context).selectSpace),
  );
  ref.read(selectedSpaceIdProvider.notifier).state = newSelectedSpaceId;
  return newSelectedSpaceId;
}