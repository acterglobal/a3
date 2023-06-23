import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show Invitation;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InvitationCard extends ConsumerWidget {
  final Invitation invitation;
  final Color avatarColor;

  const InvitationCard({
    Key? key,
    required this.invitation,
    required this.avatarColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationProfile = ref.watch(invitationProfileProvider(invitation));
    return invitationProfile.when(
      data: (data) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: ActerAvatar(
                  mode: DisplayMode.User,
                  uniqueId: data.roomId,
                  displayName: data.displayName,
                  size: 20,
                ),
                title: Text(invitation.sender().toString()),
                subtitle: RichText(
                  text: TextSpan(
                    text: AppLocalizations.of(context)!.invitationText2,
                    children: <TextSpan>[
                      TextSpan(text: data.roomName),
                    ],
                  ),
                ),
              ),
              Divider(
                color: Theme.of(context).colorScheme.neutral6,
                indent: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // Reject Invitation Button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.46,
                    child: ElevatedButton(
                      onPressed: () async => await invitation.reject(),
                      child: Text(AppLocalizations.of(context)!.decline),
                    ),
                  ),
                  // Accept Invitation Button
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.46,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (await invitation.accept() == true) {
                          final joinedRooms = ref.watch(joinedRoomListProvider);
                          for (var room in joinedRooms) {
                            if (room.conversation.getRoomId() ==
                                invitation.roomId()) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomPage(
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
                  ),
                ],
              ),
            ],
          ),
        );
      },
      error: (error, stackTrace) => const Text('Error loading invitation'),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
