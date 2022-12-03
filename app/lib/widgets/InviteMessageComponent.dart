import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';

class InviteMessageComponent extends StatelessWidget {
  final String room;
  final CustomMessage message;
  final bool isMe;
  const InviteMessageComponent({
    Key? key,
    required this.room,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
        color: AppCommonTheme.backgroundColorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isMe
                ? 'YOU HAVE INVITED TO JOIN'
                : '${message.author.firstName!.toUpperCase()} HAS INVITED YOU TO JOIN',
            style: ChatTheme01.chatTitleStyle,
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const CircleAvatar(
                backgroundColor: Colors.green,
              ),
              const SizedBox(
                width: 8,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room, style: ChatTheme01.chatBodyStyle),
                  const SizedBox(
                    height: 3,
                  ),
                  const Text('6 Members', style: ChatTheme01.latestChatStyle),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Container(
                      width: size.width * 0.5,
                      height: 0.8,
                      color: AppCommonTheme.dividerColor,
                    ),
                  ),
                  SizedBox(
                    width: size.width * 0.5,
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text(
                        'Join',
                        style: ChatTheme01.chatTitleStyle,
                      ),
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.green),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
