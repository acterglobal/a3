import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/controllers/chat_list_controller.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, FfiBufferUint8, Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class InviteInfoCard extends StatefulWidget {
  final Client client;
  final Invitation invitation;
  final Color avatarColor;

  const InviteInfoCard({
    Key? key,
    required this.client,
    required this.invitation,
    required this.avatarColor,
  }) : super(key: key);

  @override
  State<InviteInfoCard> createState() => _InviteInfoCardState();
}

class _InviteInfoCardState extends State<InviteInfoCard> {
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
    String myId = widget.client.account().userId();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            // leading: CircleAvatar(backgroundColor: avatarColor),
            leading: CustomAvatar(
              uniqueKey: myId,
              avatar: avatar,
              displayName: displayName,
              radius: 20,
              isGroup: true,
              stringName: simplifyUserId(myId)!,
            ),
            title: _TitleWidget(invitation: widget.invitation),
            subtitle: _SubtitleWidget(invitation: widget.invitation),
          ),
          Divider(color: Theme.of(context).colorScheme.neutral6, indent: 15),
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
      child: ElevatedButton(
        onPressed: () async => await invitation.reject(),
        child: Text(AppLocalizations.of(context)!.decline),
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
      child: ElevatedButton(
        onPressed: () async {
          if (await invitation.accept() == true) {
            final listController = Get.find<ChatListController>();
            for (var room in listController.joinedRooms) {
              if (room.conversation.getRoomId() == invitation.roomId()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomPage(
                      client: client,
                      conversation: room.conversation,
                    ),
                  ),
                );
              }
            }
          }
        },
        child: Text(AppLocalizations.of(context)!.accept),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            Theme.of(context).colorScheme.success,
          ),
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
        children: <TextSpan>[
          TextSpan(
            text: invitation.roomName(),
          ),
        ],
      ),
    );
  }
}
