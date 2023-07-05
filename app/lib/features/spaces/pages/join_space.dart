import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/spaces/widgets/public_spaces_selector.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:go_router/go_router.dart';

class JoinSpacePage extends ConsumerWidget {
  const JoinSpacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: <Color>[
              Theme.of(context).colorScheme.background,
              Theme.of(context).colorScheme.neutral,
            ],
          ),
        ),
        child: PublicSpaceSelector(
          autofocus: true,
          onSelected: (searchResult, searchServerName, space) =>
              onSelectedKnown(
                  context, ref, searchResult, searchServerName, space,),
        ),
      ),
    );
  }

  void onSelectedKnown(
    BuildContext context,
    WidgetRef ref,
    PublicSearchResultItem spaceSearchResult,
    String? searchServer,
    SpaceItem? spaceInfo,
  ) async {
    if (spaceInfo != null) {
      // we know the space, user just wants to enter it
      context.goNamed(
        Routes.space.name,
        pathParameters: {'spaceId': spaceInfo.roomId},
      );
      return;
    }

    // we don't know the space yet, the user wants to join.
    final joinRule = spaceSearchResult.joinRuleStr();
    if (joinRule != 'Public') {
      customMsgSnackbar(
        context,
        'Join Rule "$joinRule" not supported yet. Sorry',
      );
      return;
    }

    popUpDialog(
      context: context,
      title: Text(
        'Joining Space "${spaceSearchResult.name()} (${spaceSearchResult.roomIdStr()})"',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    );
    final sdk = ref.read(sdkProvider);
    final client = ref.read(clientProvider)!;
    try {
      final newSpace = await client.joinSpace(
        spaceSearchResult.roomIdStr(),
        searchServer,
      );
      Navigator.of(context, rootNavigator: true).pop();
      context.goNamed(Routes.space.name, pathParameters: {
        'spaceId': newSpace.getRoomIdStr(),
      },);
    } catch (err) {
      Navigator.of(context, rootNavigator: true).pop();

      popUpDialog(
        context: context,
        title: Text(
          'Joining Space "${spaceSearchResult.name()} (${spaceSearchResult.roomIdStr()}) failed: $err"',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        isLoader: false,
      );
    }
  }
}
