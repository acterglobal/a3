import 'dart:math';

import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/space_name_widget.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::space::members_page');

class SpaceMembersPage extends ConsumerStatefulWidget {
  final String spaceIdOrAlias;

  const SpaceMembersPage({super.key, required this.spaceIdOrAlias});

  @override
  ConsumerState<SpaceMembersPage> createState() => _SpaceMembersPageState();
}

class _SpaceMembersPageState extends ConsumerState<SpaceMembersPage> {
  String get searchValue => ref.watch(searchValueProvider);

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    final membersLoader = ref.watch(
      membersIdWithSearchProvider((
        roomId: widget.spaceIdOrAlias,
        searchValue: searchValue,
      ),),
    );
    final membership =
        ref.watch(roomMembershipProvider(widget.spaceIdOrAlias)).valueOrNull;
    final invited =
        ref
            .watch(spaceInvitedMembersProvider(widget.spaceIdOrAlias))
            .valueOrNull ??
        [];
    final showInviteBtn = membership?.canString('CanInvite') == true;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          centerTitle: false,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L10n.of(context).members, textAlign: TextAlign.left),
              SpaceNameWidget(spaceId: widget.spaceIdOrAlias),
            ],
          ),
          actions: [
            showInviteBtn && invited.length <= 100
                ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                  ),
                  onPressed:
                      () => context.pushNamed(
                        Routes.spaceInvite.name,
                        pathParameters: {'spaceId': widget.spaceIdOrAlias},
                      ),
                  child: Text(lang.invite),
                )
                : const SizedBox.shrink(),
          ],
        ),
        SliverToBoxAdapter(
          child: ActerSearchWidget(
            onChanged: (value) {
              final notifier = ref.read(searchValueProvider.notifier);
              notifier.state = value;
            },
            onClear: () {
              final notifier = ref.read(searchValueProvider.notifier);
              notifier.state = '';
            },
          ),
        ),
        membersLoader.when(
          data: (members) {
            final widthCount =
                (MediaQuery.of(context).size.width ~/ 300).toInt();
            const int minCount = 4;
            if (members.isEmpty) {
              return SliverToBoxAdapter(
                child: Center(child: Text(lang.noMembersFound)),
              );
            }
            return SliverGrid.builder(
              itemCount: members.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: max(1, min(widthCount, minCount)),
                childAspectRatio: 5.0,
              ),
              itemBuilder:
                  (context, index) => MemberListEntry(
                    memberId: members[index],
                    roomId: widget.spaceIdOrAlias,
                  ),
            );
          },
          skipLoadingOnReload: false,
          error: (e, s) {
            _log.severe('Failed to load space members', e, s);
            return SliverToBoxAdapter(
              child: Center(child: Text(lang.loadingFailed(e))),
            );
          },
          loading:
              () =>
                  SliverToBoxAdapter(child: Center(child: Text(lang.loading))),
        ),
      ],
    );
  }
}
