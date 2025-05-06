import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:acter/features/member/widgets/user_search_results.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteFriendsWidget extends ConsumerStatefulWidget {
  final String roomId;

  const InviteFriendsWidget({super.key, required this.roomId});

  @override
  ConsumerState<InviteFriendsWidget> createState() =>
      _InviteFriendsWidgetState();
}

class _InviteFriendsWidgetState extends ConsumerState<InviteFriendsWidget> {
  bool isCopyPressed = false;
  bool isQrPressed = false;

  @override
  Widget build(BuildContext context) {
    final searchValue = ref.watch(userSearchValueProvider);
    final hasSearch = searchValue != null && searchValue.isNotEmpty;

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeadlineText(context),
                    const SizedBox(height: 10),
                    _buildSearchBar(context),
                    const SizedBox(height: 10),
                    if (!hasSearch) ...[
                      _buildInviteExternallyText(context),
                      const SizedBox(height: 10),
                      _buildInviteExternallyButton(context),
                      const SizedBox(height: 10),
                    ],
                    if (hasSearch)
                      _buildSuggestedUsers(context, widget.roomId),
                  ],
                ),
              ),
              _buildActionButton(context, L10n.of(context)),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Center(
      child: Text(
        L10n.of(context).inviteFriends,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return ActerSearchWidget(
      hintText: L10n.of(context).searchExistingUsers,
      onChanged: (value) {
        final notifier = ref.read(userSearchValueProvider.notifier);
        notifier.update((state) => value);
      },
      onClear: () {
        final notifier = ref.read(userSearchValueProvider.notifier);
        notifier.state = null;
      },
    );
  }

  Widget _buildInviteExternallyText(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        L10n.of(context).inviteExternally,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildInviteExternallyButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          _buildStyledIconButton(
            context,
            Icons.copy,
            isCopyPressed,
            () => setState(() => isCopyPressed = !isCopyPressed),
          ),
          const SizedBox(width: 10),
          _buildStyledIconButton(
            context,
            Icons.qr_code,
            isQrPressed,
            () => setState(() => isQrPressed = !isQrPressed),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedUsers(BuildContext context, String roomId) {
    return Expanded(
      child: UserSearchResults(
        roomId: roomId,
        userItemBuilder: ({
          required bool isSuggestion,
          required UserProfile profile,
        }) {
          return UserBuilder(
            userId: profile.userId().toString(),
            roomId: roomId,
            userProfile: profile,
            includeSharedRooms: isSuggestion,
          );
        },
      ),
    );
  }

  Widget _buildStyledIconButton(
    BuildContext context,
    IconData icon,
    bool isPressed,
    VoidCallback onPressed,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color:
            isPressed
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceBright,
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        border: Border.all(width: 2, color: theme.scaffoldBackgroundColor),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: isPressed ? theme.colorScheme.onPrimary : null),
        iconSize: 30,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {},
          child: Text(lang.next, style: const TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () {}, child: Text(lang.skip)),
      ],
    );
  }
}
