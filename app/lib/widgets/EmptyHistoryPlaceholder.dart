import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/TypeIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class EmptyHistoryPlaceholder extends StatelessWidget {
  const EmptyHistoryPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatRoomController>(
      id: 'typing indicator',
      builder: (ChatRoomController controller) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(flex: 1),
              SvgPicture.asset('assets/images/emptyPlaceholder.svg'),
              const SizedBox(height: 15),
              Text(
                '${AppLocalizations.of(context)!.noMessages} ...',
                style: ChatTheme01.emptyMsgTitle,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.startConvo,
                style: ChatTheme01.chatBodyStyle,
              ),
              const Spacer(),
              controller.typingUsers.isNotEmpty
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: TypeIndicator(
                        bubbleAlignment: BubbleRtlAlignment.right,
                        showIndicator: controller.typingUsers.isNotEmpty,
                        options: TypingIndicatorOptions(
                          animationSpeed: const Duration(milliseconds: 800),
                          typingUsers: controller.typingUsers,
                          typingMode: TypingIndicatorMode.text,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ],
          ),
        );
      },
    );
  }
}
