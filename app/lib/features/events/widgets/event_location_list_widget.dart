import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/member/widgets/member_list_entry.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EventLocationListWidget extends ConsumerWidget {
  final String roomId;
  final List<String> locations;

  const EventLocationListWidget({
    super.key,
    required this.roomId,
    required this.locations,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lang.eventLocations,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 35,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final location in locations)
                  MemberListEntry(
                    memberId: location,
                    roomId: roomId,
                    isShowActions: false,
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: ActerPrimaryActionButton(
                  onPressed: () {},
                  child: Text(lang.save),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: Text(lang.cancel),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
