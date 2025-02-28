import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/invite_members/widgets/space_member_invite_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::invite::space_members');

class InviteSpaceMembers extends ConsumerStatefulWidget {
  final String roomId;

  const InviteSpaceMembers({super.key, required this.roomId});

  @override
  ConsumerState<InviteSpaceMembers> createState() =>
      _InviteSpaceMembersConsumerState();
}

class _InviteSpaceMembersConsumerState
    extends ConsumerState<InviteSpaceMembers> {
  List<String> selectedSpaces = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(L10n.of(context).inviteSpaceMembersTitle),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      L10n.of(context).inviteSpaceMembersSubtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    _buildParentSpaces(),
                    const SizedBox(height: 20),
                    _buildOtherSpace(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            _buildDoneButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildParentSpaces() {
    final parentSpaceIds =
        ref.watch(parentIdsProvider(widget.roomId)).valueOrNull;
    if (parentSpaceIds == null || parentSpaceIds.isEmpty) {
      return const SizedBox.shrink();
    }
    final lang = L10n.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(parentSpaceIds.length > 1 ? lang.parentSpaces : lang.parentSpace),
        for (final roomId in parentSpaceIds)
          SpaceMemberInviteCard(
            roomId: roomId,
            isSelected: selectedSpaces.contains(roomId),
            onChanged: (value) {
              setState(() {
                if (selectedSpaces.contains(roomId)) {
                  selectedSpaces.remove(roomId);
                } else {
                  selectedSpaces.add(roomId);
                }
              });
            },
          ),
        const SizedBox(height: 16),
        Text(lang.otherSpaces),
      ],
    );
  }

  Widget _buildOtherSpace() {
    final spacesLoader = ref.watch(
      otherSpacesForInviteMembersProvider(widget.roomId),
    );
    return spacesLoader.when(
      data: _buildOtherSpaceData,
      error: (e, s) {
        _log.severe('Failed to load other spaces', e, s);
        return ListTile(title: Text(L10n.of(context).loadingFailed(e)));
      },
      loading: () => _buildSkeletonizerLoading(),
    );
  }

  Widget _buildOtherSpaceData(List<Space> spaces) {
    return ListView.builder(
      itemCount: spaces.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final roomId = spaces[index].getRoomIdStr();
        return SpaceMemberInviteCard(
          roomId: roomId,
          isSelected: selectedSpaces.contains(roomId),
          onChanged: (value) {
            if (selectedSpaces.contains(roomId)) {
              selectedSpaces.remove(roomId);
            } else {
              selectedSpaces.add(roomId);
            }
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildSkeletonizerLoading() {
    final lang = L10n.of(context);
    return Skeletonizer(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(lang.loading)),
          ListTile(title: Text(lang.loading)),
          ListTile(title: Text(lang.loading)),
          ListTile(title: Text(lang.loading)),
        ],
      ),
    );
  }

  Widget _buildDoneButton() {
    return ActerPrimaryActionButton(
      onPressed: _inviteMembers,
      child: Text(L10n.of(context).invite),
    );
  }

  Future<void> _inviteMembers() async {
    final lang = L10n.of(context);
    if (selectedSpaces.isEmpty) {
      EasyLoading.showToast(lang.pleaseSelectSpace);
      return;
    }

    EasyLoading.show(status: lang.invitingSpaceMembersLoading);
    try {
      final room = ref.read(maybeRoomProvider(widget.roomId)).valueOrNull;
      if (room == null) {
        _log.severe('Room failed to be found');
        if (!mounted) {
          EasyLoading.dismiss();
          return;
        }
        EasyLoading.showError(
          lang.invitingSpaceMembersError('Missing room'),
          duration: const Duration(seconds: 3),
        );
        return;
      }
      final invitedMemebers = await ref.read(
        roomInvitedMembersProvider(widget.roomId).future,
      );
      final invited =
          invitedMemebers.map((e) => e.userId().toString()).toList();
      final joined = await ref.read(membersIdsProvider(widget.roomId).future);
      var total = 0;
      var inviteCount = 0;
      for (final roomId in selectedSpaces) {
        final members =
            (await ref.read(membersIdsProvider(roomId).future)).toList();
        total += members.length;

        for (final member in members) {
          final isInvited = invited.contains(member);
          final isJoined = joined.contains(member);
          if (!isInvited && !isJoined) {
            EasyLoading.showProgress(
              inviteCount / total,
              status: lang.invitingSpaceMembersProgress(inviteCount, total),
            );
            await room.inviteUser(member);
            inviteCount++;
          } else {
            total -= 1; // we substract from the total.
          }
        }
      }
      setState(() => selectedSpaces.clear());
      if (!mounted) return;
      EasyLoading.showToast(lang.membersInvited(inviteCount));
    } catch (e, s) {
      _log.severe('Invite Space Members Error', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.invitingSpaceMembersError(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
