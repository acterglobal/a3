import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/invite_members/widgets/space_member_invite_card.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::invite::invite_space_members');

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
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(L10n.of(context).inviteSpaceMembersTitle),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      constraints: const BoxConstraints(maxWidth: 500),
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
          _buildDoneButton(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildParentSpaces() {
    final parentSpaceIds =
        ref.watch(parentIdsProvider(widget.roomId)).valueOrNull;

    if (parentSpaceIds == null && parentSpaceIds!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          parentSpaceIds.length > 1
              ? L10n.of(context).parentSpaces
              : L10n.of(context).parentSpace,
        ),
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
        Text(L10n.of(context).otherSpaces),
      ],
    );
  }

  Widget _buildOtherSpace() {
    final otherSpaces =
        ref.watch(otherSpacesForInviteMembersProvider(widget.roomId));
    return otherSpaces.when(
      data: _buildOtherSpaceData,
      error: (error, stack) => ListTile(
        title: Text(error.toString()),
      ),
      loading: () => _buildSkeletonizerLoading(),
    );
  }

  Widget _buildOtherSpaceData(List<Space> data) {
    return Expanded(
      child: ListView.builder(
        itemCount: data.length,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final roomId = data[index].getRoomIdStr();
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
      ),
    );
  }

  Widget _buildSkeletonizerLoading() {
    return Skeletonizer(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(title: Text(L10n.of(context).loading)),
          ListTile(title: Text(L10n.of(context).loading)),
          ListTile(title: Text(L10n.of(context).loading)),
          ListTile(title: Text(L10n.of(context).loading)),
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
    if (selectedSpaces.isEmpty) {
      EasyLoading.showToast(L10n.of(context).pleaseSelectSpace);
      return;
    }

    EasyLoading.show(
      status: L10n.of(context).invitingSpaceMembersLoading,
      dismissOnTap: false,
    );

    try {
      final currentSpace = ref.read(spaceProvider(widget.roomId)).valueOrNull;
      final invited =
          (ref.read(roomInvitedMembersProvider(widget.roomId)).valueOrNull ??
                  [])
              .map((e) => e.userId().toString())
              .toList();
      final joined =
          ref.read(membersIdsProvider(widget.roomId)).valueOrNull ?? [];
      var inviteCount = 0;
      for (final roomId in selectedSpaces) {
        final members =
            (await ref.watch(membersIdsProvider(roomId).future)).toList();
        for (final member in members) {
          final isInvited = invited.contains(member);
          final isJoined = joined.contains(member);
          if (currentSpace != null && !isInvited && !isJoined) {
            await currentSpace.inviteUser(member);
            inviteCount++;
          }
        }
      }
      setState(() => selectedSpaces.clear());
      if (!mounted) return;
      EasyLoading.showToast(L10n.of(context).membersInvited(inviteCount));
    } catch (e, st) {
      _log.severe('Invite Space Members Error', e, st);
      if (!mounted) return;
      EasyLoading.showToast(L10n.of(context).invitingSpaceMembersError(e));
    }
  }
}
