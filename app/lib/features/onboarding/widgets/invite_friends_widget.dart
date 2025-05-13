import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:acter/features/member/widgets/user_search_results.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InviteFriendsWidget extends ConsumerStatefulWidget {
  final String roomId;
  final CallNextPage callNextPage;

  const InviteFriendsWidget({
    super.key,
    required this.roomId,
    required this.callNextPage,
  });

  @override
  ConsumerState<InviteFriendsWidget> createState() =>
      _InviteFriendsWidgetState();
}

class _InviteFriendsWidgetState extends ConsumerState<InviteFriendsWidget> {
  bool isCopyPressed = false;
  bool isQrPressed = false;

  @override
  Widget build(BuildContext context) {

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

  Widget _buildActionButton(BuildContext context, L10n lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {
            Navigator.pop(context);
            widget.callNextPage.call();
          },
          child: Text(lang.done, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
