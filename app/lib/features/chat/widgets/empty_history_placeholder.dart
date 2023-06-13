import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/widgets/type_indicator.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyHistoryPlaceholder extends ConsumerWidget {
  const EmptyHistoryPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers =
        ref.watch(chatRoomProvider.select((e) => e.typingUsers));
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
          if (typingUsers.isNotEmpty)
            _TypeIndicatorWidget(typingUsers: typingUsers),
        ],
      ),
    );
  }
}

class _TypeIndicatorWidget extends StatelessWidget {
  const _TypeIndicatorWidget({
    required this.typingUsers,
  });

  final List<types.User> typingUsers;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: TypeIndicator(
          bubbleAlignment: BubbleRtlAlignment.right,
          showIndicator: typingUsers.isNotEmpty,
          options: TypingIndicatorOptions(
            animationSpeed: const Duration(milliseconds: 800),
            typingUsers: typingUsers,
            typingMode: TypingIndicatorMode.name,
          ),
        ),
      ),
    );
  }
}
