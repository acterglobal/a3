import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

final _log = Logger('a3::space::sub_spaces');

class SubSpaces extends ConsumerWidget {
  static const moreOptionKey = Key('sub-spaces-more-actions');
  static const createSubspaceKey = Key('sub-spaces-more-create-subspace');
  static const linkSubspaceKey = Key('sub-spaces-more-link-subspace');

  final String spaceId;

  const SubSpaces({super.key, required this.spaceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: _buildAppBarUI(context, ref),
      body: _buildSubSpacesUI(context, ref),
    );
  }

  AppBar _buildAppBarUI(BuildContext context, WidgetRef ref) {
    final spaceName =
        ref.watch(roomDisplayNameProvider(spaceId)).valueOrNull;
    final membership = ref.watch(roomMembershipProvider(spaceId));
    bool canLinkSpace =
        membership.valueOrNull?.canString('CanLinkSpaces') == true;
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).spaces),
          Text(
            '($spaceName)',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(PhosphorIcons.arrowsClockwise()),
          onPressed: () {
            ref.read(addDummySpaceCategoriesProvider(spaceId));
          },
        ),
        if (canLinkSpace) _buildMenuOptions(context),
      ],
    );
  }

  Widget _buildMenuOptions(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(PhosphorIcons.plusCircle()),
      iconSize: 28,
      color: Theme.of(context).colorScheme.surface,
      itemBuilder: (BuildContext context) => <PopupMenuEntry>[
        PopupMenuItem(
          key: SubSpaces.createSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.createSpace.name,
            queryParameters: {'parentSpaceId': spaceId},
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.plus()),
              const SizedBox(width: 6),
              Text(L10n.of(context).createSubspace),
            ],
          ),
        ),
        PopupMenuItem(
          key: SubSpaces.linkSubspaceKey,
          onTap: () => context.pushNamed(
            Routes.linkSubspace.name,
            pathParameters: {'spaceId': spaceId},
          ),
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.link()),
              const SizedBox(width: 6),
              Text(L10n.of(context).linkExistingSpace),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => context.pushNamed(
            Routes.linkRecommended.name,
            pathParameters: {'spaceId': spaceId},
          ),
          child: Row(
            children: [
              const Icon(Atlas.link_select, size: 18),
              const SizedBox(width: 8),
              Text(L10n.of(context).recommendedSpaces),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {},
          child: Row(
            children: [
              Icon(PhosphorIcons.dotsSixVertical()),
              const SizedBox(width: 6),
              Text(L10n.of(context).organized),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubSpacesUI(BuildContext context, WidgetRef ref) {
    final spaceCategories = ref.watch(spaceCategoriesProvider(spaceId));
    return spaceCategories.when(
      data: (categories) {
        List<Category> categoryList = categories.categories().toList();
        print('Categories ${categoryList.length}');
        return const Placeholder();
      },
      error: (e, s) {
        _log.severe('Failed to load the space categories', e, s);
        return Center(child: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => Center(child: Text(L10n.of(context).loading)),
    );
  }
}
