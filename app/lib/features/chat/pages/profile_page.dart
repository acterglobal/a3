import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/pages/link_settings_page.dart';
import 'package:acter/features/chat/pages/edit_group_page.dart';
import 'package:acter/features/chat/pages/group_link_page.dart';
import 'package:acter/features/chat/pages/requests_page.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter/features/chat/widgets/group_member_view.dart';
import 'package:acter/features/chat/widgets/invite_list_view.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class ProfilePage extends StatelessWidget {
  final Client client;
  final Conversation room;
  final String? roomName;
  final Future<FfiBufferUint8>? roomAvatar;
  final bool isGroup;
  final bool isAdmin;

  const ProfilePage({
    Key? key,
    required this.client,
    required this.room,
    required this.isGroup,
    required this.isAdmin,
    this.roomName,
    this.roomAvatar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ChatRoomController roomController = Get.find<ChatRoomController>();
    String chatDesc =
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam nec aliquam ex. Nam bibendum scelerisque placerat.';
    String roomId = room.getRoomId().toString();
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        actions: <Widget>[
          Visibility(
            visible: isAdmin,
            child: PopupMenuButton<int>(
              onSelected: (item) => handleItemClick(item, context),
              itemBuilder: (context) => [
                const PopupMenuItem<int>(
                  value: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Report'),
                      SizedBox(width: 50),
                      Icon(Atlas.triangle_exclamation)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupInfoScreen(
                      room: room,
                      name: roomName ?? AppLocalizations.of(context)!.noName,
                      description: chatDesc,
                    ),
                  ),
                );
              },
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 38, bottom: 12),
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CustomAvatar(
                        uniqueKey: roomId,
                        avatar: roomAvatar,
                        displayName: roomName,
                        radius: 20,
                        cacheHeight: 120,
                        cacheWidth: 120,
                        isGroup: true,
                        stringName: simplifyRoomId(roomId)!,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (roomName == null)
              const Text('Loading Name')
            else
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGroupInfoScreen(
                        room: room,
                        name: roomName ?? AppLocalizations.of(context)!.noName,
                        description: chatDesc,
                      ),
                    ),
                  );
                },
                child: Text(
                  roomName!,
                  overflow: TextOverflow.clip,
                ),
              ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupInfoScreen(
                      room: room,
                      name: roomName ?? AppLocalizations.of(context)!.noName,
                      description: chatDesc,
                    ),
                  ),
                );
              },
              child: Visibility(
                visible: isGroup,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Text(
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam nec aliquam ex. Nam bibendum scelerisque placerat.',
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !isGroup,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Text(
                  'Online',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildMuteButton(context),
                buildSearchButton(context),
                buildGalleryButton(context)
              ],
            ),
            Visibility(
              visible: isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Column(
                      children: [
                        buildRequestsAndInvites(context),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 2,
                          ),
                        ),
                        buildGroupLinkSwitch(context),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 2,
                          ),
                        ),
                        buildCreateRoomInviteButton(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: buildGroupLabel(),
              ),
            ),
            Visibility(
              visible: !isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: buildBlockButton(),
              ),
            ),
            Visibility(
              visible: isGroup,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                child: buildActiveMembersLabel(context, roomController),
              ),
            ),
            Visibility(
              visible: isGroup,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: buildMemberList(roomController),
              ),
            ),
            Visibility(
              visible: isGroup,
              child: buildLeaveButton(context),
            )
          ],
        ),
      ),
    );
  }

  Widget buildMuteButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showMuteBottomSheet(context);
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Atlas.bell_reminder, color: Colors.white),
              ),
              Text('Mute', style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search Clicked')),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Atlas.magnifying_glass, color: Colors.white),
              ),
              Text('Search', style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGalleryButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery tapped')),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Atlas.image_gallery, color: Colors.white),
              ),
              Text('Gallery', style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRequestsAndInvites(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestsPage(
              client: client,
              room: room,
            ),
          ),
        );
      },
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Atlas.user_plus, color: Colors.white),
          ),
          Text(
            'Requests & Invites',
            style: TextStyle(color: Colors.white),
          ),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('3', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  Widget buildGroupLinkSwitch(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupLinkView()),
        );
      },
      child: const Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Atlas.link, color: Colors.white),
          ),
          Text('Group Link', style: TextStyle(color: Colors.white)),
          Spacer(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Text('On', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget buildCreateRoomInviteButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showInviteBottomSheet(context);
      },
      child: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(bottom: 12, left: 16),
        child: const Text(
          'Create Room Invite',
          style: TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  void showInviteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return DraggableScrollableSheet(
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Invite a Friend to this room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.start,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        width: double.infinity,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Atlas.magnifying_glass,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            hintText: 'Search for friends',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Your invite link expires in 24 hours.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 5),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LinkSettingsPage(
                                    room: room,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Edit invite link',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: 10,
                        itemBuilder: (context, index) => const Padding(
                          padding: EdgeInsets.all(12),
                          child: InviteListView(
                            isAdded: false,
                            name: 'Abhishek',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildGroupLabel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Atlas.group_team, color: Colors.white),
                ),
                Text(
                  'Group in common',
                  style: TextStyle(color: Colors.white),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('3', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 2),
            ),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Atlas.link, color: Colors.white),
                ),
                Text(
                  'Share Username',
                  style: TextStyle(color: Colors.white),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: Text('@marthacraig'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBlockButton() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Atlas.danger),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Block this user',
                style: TextStyle(fontSize: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildActiveMembersLabel(
    BuildContext context,
    ChatRoomController roomController,
  ) {
    return Text(
      '${roomController.activeMembers.length} ${AppLocalizations.of(context)!.members}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget buildMemberList(ChatRoomController roomController) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        itemCount: roomController.activeMembers.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          String userId =
              roomController.activeMembers[index].userId().toString();
          return Padding(
            padding: const EdgeInsets.all(12),
            child: GetBuilder<ChatRoomController>(
              id: 'user-profile-$userId',
              builder: (ChatRoomController controller) {
                return (controller.getUserName(userId) == null)
                    ? const Center(child: CircularProgressIndicator())
                    : GroupMember(
                        userId: userId,
                        name: controller.getUserName(userId),
                        isAdmin: true,
                        avatar: controller.getUserAvatar(userId),
                      );
              },
            ),
          );
        },
      ),
    );
  }

  Widget buildLeaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        const snackBar = SnackBar(
          content: Text('Oops you pressed leave group'),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Text('Leave Group'),
            ),
          ),
        ),
      ),
    );
  }

  void handleItemClick(int item, BuildContext context) {
    if (item == 0) {
      showReportBottomSheet(context);
    }
  }

  void showReportBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.25,
            expand: false,
            builder: (
              BuildContext context,
              ScrollController scrollController,
            ) {
              return Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child:
                          Text('Spam', style: TextStyle(color: Colors.white)),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Violence',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Fake Account',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        'Copyrights',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child:
                          Text('Spam', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void showMuteBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            expand: false,
            builder: (BuildContext context, ScrollController scrollController) {
              return SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: const Text(
                            'Mute this chat for',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.33),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            '1 Hour',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.33),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            '8 Hours',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.33),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            '1 Day',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.33),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: const Text(
                            '1 Week',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.33),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              'Always',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6.33),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                width: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
