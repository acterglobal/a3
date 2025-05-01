import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/providers/public_space_info_provider.dart';
import 'package:acter/features/room/actions/join_room.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:acter_avatar/acter_avatar.dart';

class RecommendedSpacesPage extends ConsumerStatefulWidget {
  final VoidCallback? callNextPage;

  const RecommendedSpacesPage({super.key, required this.callNextPage});

  @override
  ConsumerState<RecommendedSpacesPage> createState() =>
      _RecommendedSpacesPageState();
}

class _RecommendedSpacesPageState extends ConsumerState<RecommendedSpacesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchFilterProvider.notifier)
        ..updateSearchTerm('acter.global')
        ..updateSearchServer('acter.global')
        ..updateFilters(FilterBy.spaces);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                _buildHeadlineText(context),
                const SizedBox(height: 20),
                _buildDescriptionText(context),
                const SizedBox(height: 30),
                _buildSpacesSection(context),
                const Spacer(),
                _buildActionButtons(context),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).recommendedSpaces,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).recommendedSpacesDesc,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSpacesSection(BuildContext context) {
    final searchState = ref.watch(publicSearchProvider);
    final spaces = searchState.records ?? [];

    if (ref.read(publicSearchProvider.notifier).isLoading()) {
      return const Center(child: CircularProgressIndicator());
    }

    if (spaces.isEmpty) {
      return Center(child: Text(L10n.of(context).noSpacesFound));
    }

    // Show the first space for now
    return _buildSpaceTile(context, spaces.first);
  }

  Widget _buildSpaceTile(BuildContext context, PublicSearchResultItem space) {
    final textTheme = Theme.of(context).textTheme;
    final spaceName = space.name() ?? '';
    final description = space.topic() ?? '';
    final avatarLoader = ref.watch(searchItemProfileData(space));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: avatarLoader.when(
          data: (avatar) => ActerAvatar(options: AvatarOptions(avatar)),
          error: (_, __) => _defaultAvatar(spaceName, space),
          loading: () => _defaultAvatar(spaceName, space),
        ),
        title: Text(spaceName, style: textTheme.bodyMedium),
        subtitle:
            description.isNotEmpty
                ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    description,
                    style: textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
                : null,
        isThreeLine: true,
      ),
    );
  }

  Widget _defaultAvatar(String name, PublicSearchResultItem space) {
    return ActerAvatar(
      options: AvatarOptions(
        AvatarInfo(uniqueId: space.roomIdStr(), displayName: name),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final lang = L10n.of(context);
    final spaces = ref.watch(publicSearchProvider).records ?? [];
    final space = spaces.isNotEmpty ? spaces.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: space != null ? () => _joinSpace(context, space) : null,
          child: Text(lang.joinAndContinue),
        ),
        const SizedBox(height: 10),
        OutlinedButton(onPressed: () => widget.callNextPage?.call(), child: Text(lang.skip)),
      ],
    );
  }

  Future<void> _joinSpace(
    BuildContext context,
    PublicSearchResultItem space,
  ) async {
    final lang = L10n.of(context);
    final roomId = space.roomIdStr();
    final spaceName = space.name() ?? '';

    try {
      await joinRoom(
        context: context,
        ref: ref,
        roomIdOrAlias: roomId,
        roomName: spaceName,
        serverNames: ['acter.global'],
      );

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${lang.joined} $spaceName')));
      }
      widget.callNextPage?.call();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(lang.spacesLoadingError)));
      }
    }
  }
}
