// ignore_for_file: prefer_const_constructors, require_trailing_commas

import 'package:effektio/common/store/separatedThemes.dart';
import 'package:effektio/common/widget/InviteListView.dart';
import 'package:effektio/common/widget/MembersList.dart';
import 'package:effektio/common/widget/customAvatar.dart';
import 'package:effektio/screens/ChatProfileScreen/EditGroupInfo.dart';
import 'package:effektio/screens/ChatProfileScreen/GroupLinkScreen.dart';
import 'package:effektio/screens/ChatProfileScreen/ReqAndInvites.dart';
import 'package:effektio/screens/ChatProfileScreen/RoomLinkSetting.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatProfileScreen extends StatefulWidget {
  final Conversation room;
  final String? user;
  final bool isGroup;
  final bool isAdmin;

  const ChatProfileScreen({
    Key? key,
    required this.room,
    required this.user,
    required this.isGroup,
    required this.isAdmin,
  }) : super(key: key);

  @override
  _ChatProfileScreenState createState() => _ChatProfileScreenState();
}

class _ChatProfileScreenState extends State<ChatProfileScreen> {
  String chatName = '';
  String chatDesc =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam nec aliquam ex. Nam bibendum scelerisque placerat.';

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
                      name: chatName,
                      description: chatDesc,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Text(
                    'Edit',
                    style: TextStyle(
                        color: AppCommonTheme.primaryColor, fontSize: 22.0),
                  ),
                ),
              ),
            ),
          ),
          Visibility(
            visible: !widget.isAdmin,
            child: PopupMenuButton<int>(
              color: AppCommonTheme.darkShade,
              onSelected: (item) => handleClick(item),
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
                      SizedBox(
                        width: 50,
                      ),
                      Icon(
                        Icons.report,
                        color: AppCommonTheme.primaryColor,
                      )
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
                padding: const EdgeInsets.only(top: 38.0, bottom: 12.0),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: CustomAvatar(
                      avatar: widget.room.avatar(),
                      displayName: widget.room.displayName(),
                      radius: 20,
                      isGroup: true,
                      stringName: '',
                    ),
                  ),
                ),
              ),
            ),
            FutureBuilder<String>(
              future: widget.room.displayName(),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (snapshot.hasData) {
                  chatName = snapshot.requireData;
                  return Text(
                    snapshot.requireData,
                    overflow: TextOverflow.clip,
                    style: ChatTheme01.chatProfileTitleStyle,
                  );
                } else {
                  return const Text('Loading Name');
                }
              },
            ),
            Visibility(
              visible: widget.isGroup,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 20.0),
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
                padding: EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 20.0),
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
                GestureDetector(
                  onTap: (() {
                    showMuteBottomSheet();
                  }),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: AppCommonTheme.darkShade,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Mute',
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Search Clicked'),
                      ),
                    );
                  }),
                  child: Card(
                    color: AppCommonTheme.darkShade,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Search',
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: (() {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Gallery tapped'),
                      ),
                    );
                  }),
                  child: Card(
                    color: AppCommonTheme.darkShade,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.photo_library_rounded,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Gallery',
                            style: TextStyle(color: Colors.white),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
            Visibility(
              visible: widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: AppCommonTheme.darkShade,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RequestScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                ),
                                child: Icon(
                                  Icons.person_add_alt_1_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Requests & Invites',
                                style: TextStyle(color: Colors.white),
                              ),
                              Spacer(),
                              Row(
                                children: const [
                                  Text(
                                    '3',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(
                            height: 2.0,
                            color: AppCommonTheme.dividerColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupLinkScreen(),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                child: Icon(
                                  Icons.link,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Group Link',
                                style: TextStyle(color: Colors.white),
                              ),
                              Spacer(),
                              Row(
                                children: const [
                                  Text(
                                    'On',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(
                            height: 2.0,
                            color: AppCommonTheme.dividerColor,
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showInviteBottomSheet();
                              },
                              child: Padding(
                                padding:
                                    EdgeInsets.only(bottom: 12.0, left: 16.0),
                                child: Text(
                                  'Create Room Invite',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: AppCommonTheme.darkShade,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16.0,
                                right: 16.0,
                              ),
                              child: Icon(
                                Icons.groups_outlined,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Group in common',
                              style: TextStyle(color: Colors.white),
                            ),
                            Spacer(),
                            Row(
                              children: const [
                                Text(
                                  '3',
                                  style: TextStyle(color: Colors.white),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                )
                              ],
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Divider(
                            height: 2.0,
                            color: AppCommonTheme.dividerColor,
                          ),
                        ),
                        Row(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Icon(
                                Icons.link,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Share Username',
                              style: TextStyle(color: Colors.white),
                            ),
                            Spacer(),
                            Row(
                              children: const [
                                Text(
                                  '@marthacraig',
                                  style: TextStyle(
                                    color: AppCommonTheme.primaryColor,
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                )
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: !widget.isGroup,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  color: AppCommonTheme.darkShade,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.dangerous_outlined,
                          color: AppCommonTheme.primaryColor,
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Text(
                            'Block this user',
                            style: TextStyle(
                              color: AppCommonTheme.primaryColor,
                              fontSize: 16.0,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.isGroup,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: FutureBuilder<FfiListMember>(
                      future: widget.room.activeMembers(),
                      builder: (
                        BuildContext context,
                        AsyncSnapshot<FfiListMember> snapshot,
                      ) {
                        if (snapshot.hasData) {
                          return Text(
                            '${snapshot.requireData.length.toString()} ${AppLocalizations.of(context)!.members}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } else {
                          return SizedBox(
                            height: 15,
                            width: 15,
                            child: CircularProgressIndicator(
                              color: AppCommonTheme.primaryColor,
                            ),
                          );
                        }
                      },
                    ),
                  )
                ],
              ),
            ),
            Visibility(
              visible: widget.isGroup,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 12.0),
                child: Card(
                  color: AppCommonTheme.darkShade,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: 10,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: MembersList(
                          name: 'Ronaldo',
                          isAdmin: true,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Visibility(
              visible: widget.isGroup,
              child: GestureDetector(
                onTap: () {
                  const snackBar = SnackBar(
                    content: Text('Oops you pressed leave group'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 12.0, right: 12.0, bottom: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: ChatTheme01.leaveBtnBg,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          'Leave Group',
                          style: TextStyle(
                            color: ChatTheme01.redText,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
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
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30.0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DraggableScrollableSheet(
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'Invite a Friend to this room',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.start,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Your invite link expires in 24 hours.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14.0,
                              ),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        RoomLinkSettingsScreen(
                                      room: widget.room,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Edit invite link',
                                style: TextStyle(
                                  color: AppCommonTheme.primaryColor,
                                  fontSize: 14.0,
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
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: InviteListView(
                                isAdded: false,
                                name: 'Abhishek',
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void handleClick(int item) {
    switch (item) {
      case 0:
        showReportBottomSheet();
        break;
    }
  }

  void showReportBottomSheet() {
    showModalBottomSheet(
        backgroundColor: AppCommonTheme.backgroundColor,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30.0),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.55,
                minChildSize: 0.25,
                expand: false,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    margin:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Spam',
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Violence',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Fake Account',
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Copyrights',
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Spam',
                                style: TextStyle(color: Colors.white),
                              ),
                              Icon(
                                Icons.keyboard_arrow_right,
                                color: Colors.white,
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        });
  }

  void showMuteBottomSheet() {
    showModalBottomSheet(
        backgroundColor: AppCommonTheme.backgroundColor,
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30.0),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
              return DraggableScrollableSheet(
                initialChildSize: 0.85,
                minChildSize: 0.5,
                expand: false,
                builder:
                    (BuildContext context, ScrollController scrollController) {
                  return Container(
                    margin:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'Mute this chat for',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  '1 Hour',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  '8 Hours',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  '1 Day',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
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
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  '1 Week',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppCommonTheme.dividerColor,
                                  width: 1.0,
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
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Always',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.33),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppCommonTheme.dividerColor,
                                  width: 1.0,
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
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        });
  }
}
