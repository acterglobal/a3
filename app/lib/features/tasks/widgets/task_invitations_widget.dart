import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/toolkit/buttons/user_chip.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/router/routes.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';

class TaskInvitationsWidget extends ConsumerWidget {
  final Task task;

  const TaskInvitationsWidget({
    required this.task,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hasInvitations = ref.watch(taskHasInvitationsProvider(task)).valueOrNull ?? false;
    final invitedUsersAsync = ref.watch(taskInvitationsProvider(task)).valueOrNull ?? [];

    if (!hasInvitations) return const SizedBox.shrink();

    return ListTile(
      dense: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(PhosphorIconsLight.userCheck),
      ),
      title: Text(lang.invited, style: textTheme.bodySmall),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: _buildInvitedUsers(
          context,
          invitedUsersAsync,
          task.roomIdStr(),
          ref,
        ),
      ),
      trailing: InkWell(
        onTap: () => context.pushNamed(
          Routes.inviteIndividual.name,
          queryParameters: {
            'roomId': task.roomIdStr(),
          },
          extra: task,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvitedUsers(
    BuildContext context,
    List<String> invitedUsers,
    String roomId,
    WidgetRef ref,
  ) {
    // sort users so that current user appears first
    final currentUserId = ref.watch(myUserIdStrProvider);
    final sortedUsers = List<String>.from(invitedUsers);
    
    if (sortedUsers.contains(currentUserId)) {
      sortedUsers.remove(currentUserId);
      sortedUsers.insert(0, currentUserId);
    }
    
    return Wrap(
      direction: Axis.horizontal,
      spacing: 5,
      runSpacing: 5,
      children: sortedUsers.map((userId) {
        return UserChip(
          key: ValueKey(userId),
          memberId: userId,
          style: Theme.of(context).textTheme.bodyLarge,
          trailingBuilder: (context, {bool isMe = false, double fontSize = 12}) {
            return isMe ? Icon(PhosphorIconsLight.x, size: fontSize) : null;
          },
        );
      }).toList(),
    );
  }
} 