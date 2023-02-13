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
          child: Stack(
            children: [
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0.0, -0.25),
                  child: SvgPicture.asset('assets/images/emptyPlaceholder.svg'),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0.0, 0.15),
                  child: Text(
                    '${AppLocalizations.of(context)!.noMessages} ...',
                    style: ChatTheme01.emptyMsgTitle,
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0.0, 0.25),
                  child: Text(
                    AppLocalizations.of(context)!.startConvo,
                    style: ChatTheme01.chatBodyStyle,
                  ),
                ),
              ),
              if (controller.typingUsers.isNotEmpty)
                _TypeIndicatorWidget(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

class _TypeIndicatorWidget extends StatelessWidget {
  const _TypeIndicatorWidget({
    required this.controller,
  });

  final ChatRoomController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
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
      ),
    );
  }
}
