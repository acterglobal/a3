import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart' show Client;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class InviteInfoWidget extends StatelessWidget {
  final Client client;
  final Color avatarColor;
  final String inviter;
  final String groupId;
  final String groupName;

  const InviteInfoWidget({
    Key? key,
    required this.client,
    required this.avatarColor,
    required this.inviter,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppCommonTheme.darkShade,
      margin: const EdgeInsets.symmetric(vertical: 1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: CircleAvatar(backgroundColor: avatarColor),
            title: _buildTitle(),
            subtitle: _buildSubtitle(context),
          ),
          const Divider(color: AppCommonTheme.dividerColor, indent: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAcceptButton(context, client),
              _buildRejectButton(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      inviter,
      style: AppCommonTheme.appBarTitleStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
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
            text: groupName,
            style: AppCommonTheme.appBarTitleStyle.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, Client client) {
    final _chatListController = Get.find<ChatListController>();
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.46,
      child: elevatedButton(
        AppLocalizations.of(context)!.accept,
        AppCommonTheme.greenButtonColor,
        () async {
          await client.acceptInvitation(groupId).then((value) {
            if (value) {
              for (var room in _chatListController.joinedRooms) {
                if (room.conversation.getRoomId() == groupId) {
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
          });
        },
        AppCommonTheme.appBarTitleStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRejectButton(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.46,
      child: elevatedButton(
        AppLocalizations.of(context)!.decline,
        AppCommonTheme.primaryColor,
        () async => await client.rejectInvitation(groupId),
        AppCommonTheme.appBarTitleStyle.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
