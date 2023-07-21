import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/widgets/type_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyHistoryPlaceholder extends StatelessWidget {
  const EmptyHistoryPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: const Alignment(0.0, 0.25),
              child: Text(
                AppLocalizations.of(context)!.startConvo,
              ),
            ),
          ),
        ],
      ),
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
            typingMode: TypingIndicatorMode.name,
          ),
        ),
      ),
    );
  }
}
