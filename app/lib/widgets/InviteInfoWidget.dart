import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/CustomAvatar.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart'
    show Client, FfiBufferUint8, Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class InviteInfoWidget extends StatefulWidget {
  final Client client;
  final Invitation invitation;
  final Color avatarColor;

  const InviteInfoWidget({
    Key? key,
    required this.client,
    required this.invitation,
    required this.avatarColor,
  }) : super(key: key);

  @override
  State<InviteInfoWidget> createState() => _InviteInfoWidgetState();
}

class _InviteInfoWidgetState extends State<InviteInfoWidget> {
  Future<FfiBufferUint8>? avatar;
  String? displayName;

  @override
  void initState() {
    super.initState();

    widget.invitation.getSenderProfile().then((value) {
      if (mounted) {
        setState(() {
          if (value.hasAvatar()) {
            avatar = value.getAvatar();
          }
          displayName = value.getDisplayName();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String userId = widget.client.userId().toString();
    return Card(
      color: AppCommonTheme.darkShade,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            // leading: CircleAvatar(backgroundColor: avatarColor),
            leading: CustomAvatar(
              uniqueKey: userId,
              avatar: avatar,
              displayName: displayName,
              radius: 20,
              isGroup: true,
              stringName: simplifyUserId(userId)!,
            ),
            title: _TitleWidget(invitation: widget.invitation),
            subtitle: _SubtitleWidget(invitation: widget.invitation),
          ),
          const Divider(color: AppCommonTheme.dividerColor, indent: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AcceptBtn(client: widget.client, invitation: widget.invitation),
              _RejectBtn(client: widget.client, invitation: widget.invitation),
            ],
          ),
        ],
      ),
    );
  }
}

class _RejectBtn extends StatelessWidget {
  const _RejectBtn({
    required this.client,
    required this.invitation,
  });

  final Client client;
  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.46,
      child: elevatedButton(
        AppLocalizations.of(context)!.decline,
        AppCommonTheme.primaryColor,
        () async => await invitation.reject(),
        AppCommonTheme.appBarTitleStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AcceptBtn extends StatelessWidget {
  const _AcceptBtn({required this.client, required this.invitation});
  final Client client;
  final Invitation invitation;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.46,
      child: elevatedButton(
        AppLocalizations.of(context)!.accept,
        AppCommonTheme.greenButtonColor,
        () async {
          if (await invitation.accept() == true) {
            final listController = Get.find<ChatListController>();
            for (var room in listController.joinedRooms) {
              if (room.conversation.getRoomId() == invitation.roomId()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      client: client,
                      room: room.conversation,
                    ),
                  ),
                );
              }
            }
          }
        },
        AppCommonTheme.appBarTitleStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TitleWidget extends StatelessWidget {
  const _TitleWidget({required this.invitation});

  final Invitation invitation;

  @override
  Widget build(BuildContext context) {
    return Text(
      invitation.sender(),
      style: AppCommonTheme.appBarTitleStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _SubtitleWidget extends StatelessWidget {
  const _SubtitleWidget({required this.invitation});

  final Invitation invitation;
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: AppLocalizations.of(context)!.invitationText2,
        style: AppCommonTheme.appBarTitleStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppCommonTheme.dividerColor,
        ),
        children: <TextSpan>[
          TextSpan(
            text: invitation.roomName(),
            style: AppCommonTheme.appBarTitleStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
