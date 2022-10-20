import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/screens/HomeScreens/chat/EditGroupInfo.dart';
import 'package:effektio/screens/HomeScreens/chat/GroupLinkScreen.dart';
import 'package:effektio/screens/HomeScreens/chat/ReqAndInvites.dart';
import 'package:effektio/screens/HomeScreens/chat/RoomLinkSetting.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio/widgets/GroupMember.dart';
import 'package:effektio/widgets/InviteListView.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatProfileScreen extends StatefulWidget {
  final Conversation room;
  final bool isGroup;
  final bool isAdmin;

  const ChatProfileScreen({
    Key? key,
    required this.room,
    required this.isGroup,
    required this.isAdmin,
  }) : super(key: key);

  @override
  _ChatProfileScreenState createState() => _ChatProfileScreenState();
}

class _ChatProfileScreenState extends State<ChatProfileScreen> {
  Future<FfiBufferUint8>? avatar;
  String? chatName;
  String chatDesc =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam nec aliquam ex. Nam bibendum scelerisque placerat.';

  @override
  void initState() {
    super.initState();

    widget.room.getProfile().then((roomProfile) {
      if (mounted) {
        setState(() {
          if (roomProfile.hasAvatar()) {
            avatar = roomProfile.getAvatar();
          }
          chatName = roomProfile.getDisplayName();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: AppCommonTheme.backgroundColor,
        actions: <Widget>[
          Visibility(
            visible: widget.isAdmin,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditGroupInfoScreen(
                      room: widget.room,
                      name: chatName ?? AppLocalizations.of(context)!.noName,
                      description: chatDesc,
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Center(
                  child: Text(
                    'Edit',
                    style: TextStyle(
                      color: AppCommonTheme.primaryColor,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: !widget.isAdmin,
            child: PopupMenuButton<int>(
              color: AppCommonTheme.darkShade,
              onSelected: (item) => handleItemClick(item),
              itemBuilder: (context) => [
                PopupMenuItem<int>(
                  value: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Report',
                        style: TextStyle(color: AppCommonTheme.primaryColor),
                      ),
                      SizedBox(width: 50),
                      Icon(Icons.report, color: AppCommonTheme.primaryColor)
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 38, bottom: 12),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CustomAvatar(
                      avatar: avatar,
                      displayName: chatName,
                      radius: 20,
                      isGroup: true,
                      stringName: parseRoomId(widget.room.getRoomId())!,
                    ),
                  ),
                ),
              ),
            ),
            if (chatName == null)
              const Text('Loading Name')
            else
              Text(
                chatName!,
                overflow: TextOverflow.clip,
                style: ChatTheme01.chatProfileTitleStyle,
              ),
            Visibility(
              visible: widget.isGroup,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam nec aliquam ex. Nam bibendum scelerisque placerat.',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Visibility(
              visible: !widget.isGroup,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Text(
                  'Online',
                  style: TextStyle(color: AppCommonTheme.primaryColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildMuteButton(),
                buildSearchButton(),
                buildGalleryButton()
              ],
            ),
            Visibility(
              visible: widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Card(
                  color: AppCommonTheme.darkShade,
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
                        buildRequestsAndInvites(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 2,
                            color: AppCommonTheme.dividerColor,
                          ),
                        ),
                        buildGroupLinkSwitch(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            height: 2,
                            color: AppCommonTheme.dividerColor,
                          ),
                        ),
                        buildCreateRoomInviteButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: buildGroupLabel(),
              ),
            ),
            Visibility(
              visible: !widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: buildBlockButton(),
              ),
            ),
            Visibility(
              visible: widget.isGroup,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(16),
                child: buildActiveMembersLabel(),
              ),
            ),
            Visibility(
              visible: widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: buildMemberList(),
              ),
            ),
            Visibility(
              visible: widget.isGroup,
              child: buildLeaveButton(),
            )
          ],
        ),
      ),
    );
  }

  Widget buildMuteButton() {
    return GestureDetector(
      onTap: () {
        showMuteBottomSheet();
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppCommonTheme.darkShade,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              Text('Mute', style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSearchButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Search Clicked')),
        );
      },
      child: Card(
        color: AppCommonTheme.darkShade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.search, color: Colors.white),
              ),
              Text('Search', style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildGalleryButton() {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gallery tapped')),
        );
      },
      child: Card(
        color: AppCommonTheme.darkShade,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Column(
            children: const [
              Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.photo_library_rounded, color: Colors.white),
              ),
              Text('Gallery', style: TextStyle(color: Colors.white))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRequestsAndInvites() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RequestScreen()),
        );
      },
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
          ),
          const Text(
            'Requests & Invites',
            style: TextStyle(color: Colors.white),
          ),
          const Spacer(),
          Row(
            children: const [
              Text('3', style: TextStyle(color: Colors.white)),
              Icon(Icons.arrow_forward_ios, color: Colors.white)
            ],
          )
        ],
      ),
    );
  }

  Widget buildGroupLinkSwitch() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupLinkScreen()),
        );
      },
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Icon(Icons.link, color: Colors.white),
          ),
          const Text('Group Link', style: TextStyle(color: Colors.white)),
          const Spacer(),
          Row(
            children: const [
              Text('On', style: TextStyle(color: Colors.white)),
              Icon(Icons.arrow_forward_ios, color: Colors.white)
            ],
          )
        ],
      ),
    );
  }

  Widget buildCreateRoomInviteButton() {
    return GestureDetector(
      onTap: () {
        showInviteBottomSheet();
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

  void showInviteBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppCommonTheme.backgroundColor,
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
                          color: AppCommonTheme.darkShade,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: TextField(
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
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
                                  builder: (context) => RoomLinkSettingsScreen(
                                    room: widget.room,
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Edit invite link',
                              style: TextStyle(
                                color: AppCommonTheme.primaryColor,
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
      color: AppCommonTheme.darkShade,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.groups_outlined, color: Colors.white),
                ),
                const Text(
                  'Group in common',
                  style: TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Row(
                  children: const [
                    Text('3', style: TextStyle(color: Colors.white)),
                    Icon(Icons.arrow_forward_ios, color: Colors.white)
                  ],
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 2, color: AppCommonTheme.dividerColor),
            ),
            Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.link, color: Colors.white),
                ),
                const Text(
                  'Share Username',
                  style: TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Row(
                  children: const [
                    Text(
                      '@marthacraig',
                      style: TextStyle(color: AppCommonTheme.primaryColor),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white)
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBlockButton() {
    return Card(
      color: AppCommonTheme.darkShade,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.dangerous_outlined, color: AppCommonTheme.primaryColor),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Block this user',
                style: TextStyle(
                  color: AppCommonTheme.primaryColor,
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildActiveMembersLabel() {
    return FutureBuilder<FfiListMember>(
      future: widget.room.activeMembers(),
      builder: (BuildContext context, AsyncSnapshot<FfiListMember> snapshot) {
        if (snapshot.hasData) {
          return Text(
            '${snapshot.requireData.length} ${AppLocalizations.of(context)!.members}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
          );
        }
        return const SizedBox(
          height: 15,
          width: 15,
          child: CircularProgressIndicator(color: AppCommonTheme.primaryColor),
        );
      },
    );
  }

  Widget buildMemberList() {
    return Card(
      color: AppCommonTheme.darkShade,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.builder(
        itemCount: 10,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: GroupMember(name: 'Ronaldo', isAdmin: true),
          );
        },
      ),
    );
  }

  Widget buildLeaveButton() {
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
            color: ChatTheme01.leaveBtnBg,
          ),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Center(
              child: Text(
                'Leave Group',
                style: TextStyle(color: ChatTheme01.redText, fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void handleItemClick(int item) {
    if (item == 0) {
      showReportBottomSheet();
    }
  }

  void showReportBottomSheet() {
    showModalBottomSheet(
      backgroundColor: AppCommonTheme.backgroundColor,
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
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Spam', style: TextStyle(color: Colors.white)),
                          Icon(Icons.keyboard_arrow_right, color: Colors.white)
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppCommonTheme.dividerColor,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Violence',
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(Icons.keyboard_arrow_right, color: Colors.white)
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppCommonTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Fake Account',
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(Icons.keyboard_arrow_right, color: Colors.white)
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppCommonTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            'Copyrights',
                            style: TextStyle(color: Colors.white),
                          ),
                          Icon(Icons.keyboard_arrow_right, color: Colors.white)
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6.33),
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppCommonTheme.dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Spam', style: TextStyle(color: Colors.white)),
                          Icon(Icons.keyboard_arrow_right, color: Colors.white)
                        ],
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

  void showMuteBottomSheet() {
    showModalBottomSheet(
      backgroundColor: AppCommonTheme.backgroundColor,
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
                                color: AppCommonTheme.dividerColor,
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
                                color: AppCommonTheme.dividerColor,
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
                                color: AppCommonTheme.dividerColor,
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
                                color: AppCommonTheme.dividerColor,
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
                                color: AppCommonTheme.dividerColor,
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
                                color: AppCommonTheme.dividerColor,
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
