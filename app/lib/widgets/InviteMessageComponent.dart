import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

class InviteMessageComponent extends StatelessWidget {
  const InviteMessageComponent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCommonTheme.backgroundColorLight,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          const Text(
            'NELLY HAS INVITED YOU TO JOIN',
            style: ChatTheme01.chatTitleStyle,
          ),
          const SizedBox(
            height: 15,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  const Text('Code News', style: ChatTheme01.chatBodyStyle),
                  const SizedBox(
                    height: 3,
                  ),
                  const Text('6 Members', style: ChatTheme01.latestChatStyle),
                  const Divider(
                    color: Colors.grey,
                    thickness: 2.0,
                  ),
                  SizedBox(
                    width: 194,
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
