import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_list_controller.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _cntrl = Get.find<ChatRoomController>();
    return GetBuilder<ChatListController>(
      id: 'typing indicator',
      builder: (ChatListController controller) {
        return SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.20),
                SvgPicture.asset(
                  'assets/images/emptyPlaceholder.svg',
                ),
                const SizedBox(height: 10),
                Text(
                  '${AppLocalizations.of(context)!.noMessages} ...',
                  style: ChatTheme01.emptyMsgTitle,
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context)!.startConvo,
                  style: ChatTheme01.chatBodyStyle,
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.28),
                _cntrl.typingUsers.isNotEmpty
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: TypeIndicator(
                          bubbleAlignment: BubbleRtlAlignment.right,
                          showIndicator: _cntrl.typingUsers.isNotEmpty,
                          options: TypingIndicatorOptions(
                            animationSpeed: const Duration(milliseconds: 800),
                            typingUsers: _cntrl.typingUsers,
                            typingMode: TypingIndicatorMode.text,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        );
      },
    );
  }
}
