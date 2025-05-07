import 'dart:io';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/input_text_field_without_border.dart';
import 'package:acter/features/files/actions/pick_avatar.dart';
import 'package:acter/features/onboarding/actions/create_new_space_onboarding_actions.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:acter/features/onboarding/widgets/invite_friends_widget.dart';
import 'package:acter/features/space/actions/set_acter_feature.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:acter/features/spaces/model/space_feature_state.dart';
import 'package:acter/features/spaces/providers/space_creation_providers.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:acter/common/providers/common_providers.dart';

final _log = Logger('a3::spaces::create_new_space');

class CreateNewSpaceWidget extends ConsumerStatefulWidget {
  final CallNextPage callNextPage;
  const CreateNewSpaceWidget({super.key, required this.callNextPage});

  @override
  ConsumerState<CreateNewSpaceWidget> createState() =>
      _CreateNewSpaceWidgetState();
}

class _CreateNewSpaceWidgetState extends ConsumerState<CreateNewSpaceWidget> {
  final TextEditingController _spaceNameController = TextEditingController();
  File? spaceAvatar;

  bool _fillExampleData = true;
  bool _activateFeatures = true;

  @override
  void initState() {
    super.initState();
    _initializeSpaceName();
  }

  Future<void> _initializeSpaceName() async {
    final displayName = await ref.read(accountDisplayNameProvider.future);
    if (mounted) {
      setState(() {
        _spaceNameController.text = L10n.of(context).spaceUserName(displayName ?? '');
      });
    }
  }

  @override
  void dispose() {
    _spaceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildHeadlineText(context),
                      const SizedBox(height: 30),
                      _avatarBuilder(),
                      const SizedBox(height: 40),
                      _buildSpaceNameTextField(),
                      const SizedBox(height: 10),
                      _buildChekbox(context),
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
    final theme = Theme.of(context);
    return Text(
      L10n.of(context).createNewSpace,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _avatarBuilder() {
    return GestureDetector(
      onTap: _handleAvatarUpload,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  spaceAvatar != null
                      ? Image.file(File(spaceAvatar!.path), fit: BoxFit.cover)
                      : Icon(Icons.people_outline, size: 50),
            ),
            Positioned(
              right: -10,
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceBright,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                  border: Border.all(
                    width: 2,
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceNameTextField() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(lang.spaceDisplayName),
        const SizedBox(height: 5),
        InputTextFieldWithoutBorder(
          key: CreateSpaceKeys.titleField,
          hintText: lang.spaceName,
          textInputType: TextInputType.text,
          controller: _spaceNameController,
        ),
      ],
    );
  }

  Widget _buildChekbox(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Checkbox(
              value: _activateFeatures,
              onChanged: (bool? newValue) {
                setState(() {
                  _activateFeatures = newValue ?? false;
                });
              },
              visualDensity: VisualDensity.compact,
            ),
            Text(
              lang.activateRecommendedFeatures,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _fillExampleData,
              onChanged: (bool? newValue) {
                setState(() {
                  _fillExampleData = newValue ?? false;
                });
              },
              visualDensity: VisualDensity.compact,
            ),
            Text(
              lang.fillWithExampleData,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, L10n lang) {
    return ActerPrimaryActionButton(
      onPressed: () async {
        final spaceId = await createOnboardingSpace(context, ref, _spaceNameController.text.trim(), spaceAvatar);

        if (spaceId != null) {
          if (_fillExampleData) {
            ref.watch(spaceCreateOnboardingDataFuturePoll(spaceId)).valueOrNull != true;
            if (context.mounted) {
              showInviteFriendsView(context, spaceId);
            }
          }
          if (!_activateFeatures) {
            _deactivateFeatures();
          }
        }
      },
      child: Text(lang.next, style: const TextStyle(fontSize: 16)),
    );
  }

  Future<void> _handleAvatarUpload() async {
    FilePickerResult? result = await pickAvatar(context: context);
    if (result != null) {
      final filePath = result.files.single.path;
      if (filePath == null) {
        _log.severe('FilePickerResult had an empty path', result);
        return;
      }
      setState(() => spaceAvatar = File(filePath));
    } else {
      // user cancelled the picker
    }
  }

  Future<void> showInviteFriendsView(BuildContext context, String spaceId) async {
    Navigator.of(context).pop();
    showModalBottomSheet(
      showDragHandle: true,
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) {
        return InviteFriendsWidget(roomId: spaceId, callNextPage: widget.callNextPage);
      },
    );
  }

   void _deactivateFeatures() {
    ref.read(featureActivationStateProvider.notifier).update((state) {
      final newState = Map<SpaceFeature, FeatureActivationState>.from(state);
      for (final feature in [
        SpaceFeature.boosts,
        SpaceFeature.stories,
        SpaceFeature.pins,
        SpaceFeature.events,
        SpaceFeature.tasks,
      ]) {
        newState[feature] = newState[feature]!.copyWith(isActivated: false);
      }
      return newState;
    });
  }
}
