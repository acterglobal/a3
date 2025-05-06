import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/features/onboarding/actions/recommended_space_actions.dart';
import 'package:acter/features/public_room_search/models/public_search_filters.dart';
import 'package:acter/features/public_room_search/providers/public_search_providers.dart';
import 'package:acter/features/public_room_search/providers/public_space_info_provider.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class RecommendedSpacesPage extends ConsumerStatefulWidget {
  final VoidCallback callNextPage;

  const RecommendedSpacesPage({super.key, required this.callNextPage});

  @override
  ConsumerState<RecommendedSpacesPage> createState() =>
      _RecommendedSpacesPageState();
}

class _RecommendedSpacesPageState extends ConsumerState<RecommendedSpacesPage> {
  List<String> selectedSpaces = [];

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

  void _toggleSpaceSelection(PublicSearchResultItem space) {
    setState(() {
      final spaceId = space.roomIdStr();
      if (selectedSpaces.contains(spaceId)) {
        selectedSpaces.remove(spaceId);
      } else {
        selectedSpaces.add(spaceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSpacesSection(context),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  _buildActionButtons(context),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
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
    final lang = L10n.of(context);
    final searchState = ref.watch(publicSearchProvider);
    final spaces = searchState.records ?? [];

    if (ref.read(publicSearchProvider.notifier).isLoading()) {
      return _buildSkeletonSpaceTile(context, lang);
    }

    if (spaces.isEmpty) {
      return Center(child: Text(lang.noSpacesFound));
    }

    return Column(
      children: spaces.map((space) => _buildSpaceTile(context, space)).toList(),
    );
  }

  Widget _buildSpaceTile(BuildContext context, PublicSearchResultItem space) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final spaceName = space.name() ?? '';
    final description = space.topic() ?? '';
    final avatarLoader = ref.watch(searchItemProfileData(space));
    final isSelected = selectedSpaces.contains(space.roomIdStr());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleSpaceSelection(space),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
          leading: avatarLoader.when(
            data: (avatar) => ActerAvatar(options: AvatarOptions(avatar)),
            error: (_, __) => _defaultAvatar(spaceName, space),
            loading: () => _defaultAvatar(spaceName, space),
          ),
          trailing: Padding(
            padding: const EdgeInsets.only(left: 0),
            child: ActerPrimaryActionButton(
              onPressed: () => joinRecommendedSpace(context, space, widget.callNextPage, ref),
              child: Text(L10n.of(context).join),
            ),
          ),
          title: Text(spaceName, style: textTheme.bodyMedium),
          subtitle: description.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    description,
                    style: textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          isThreeLine: true,
        ),
      ),
    );
  }

  Widget _buildSkeletonSpaceTile(BuildContext context, L10n lang) {
    return Skeletonizer(
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(PhosphorIcons.house()),
          ),
          title: Text(lang.spaceSkeletonName),
          subtitle: Text(lang.spaceSkeletonDescription),
          isThreeLine: true,
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ActerPrimaryActionButton(
          onPressed: () {
            if (selectedSpaces.isNotEmpty) {
              // Join all selected spaces
              for (final spaceId in selectedSpaces) {
                final space = spaces.firstWhere((s) => s.roomIdStr() == spaceId);
                joinRecommendedSpace(context, space, widget.callNextPage, ref);
              }
            } else {
              widget.callNextPage.call();
            }
          },
          child: Text(selectedSpaces.isNotEmpty 
            ? lang.joinSelectedSpace(selectedSpaces.length)
            : lang.joinAndContinue),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => widget.callNextPage.call(),
          child: Text(lang.skip),
        ),
      ],
    );
  }
}
