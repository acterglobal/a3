import 'dart:io';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/common/widgets/visibility/room_visibility_item.dart';
import 'package:acter/common/widgets/visibility/visibility_selector_drawer.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CreateSpacePage extends ConsumerStatefulWidget {
  final String? initialParentsSpaceId;

  const CreateSpacePage({super.key, this.initialParentsSpaceId});

  @override
  ConsumerState<CreateSpacePage> createState() =>
      _CreateSpacePageConsumerState();
}

class _CreateSpacePageConsumerState extends ConsumerState<CreateSpacePage> {
  final TextEditingController _spaceNameController = TextEditingController();
  final TextEditingController _spaceDescriptionController =
      TextEditingController();
  File? spaceAvatar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
      parentNotifier.state = widget.initialParentsSpaceId;

      //Set default visibility based on the parent space selection
      // PRIVATE : If no parent is selected
      // SPACE VISIBLE : If parent space is selected
      if (widget.initialParentsSpaceId != null) {
        ref
            .read(selectedVisibilityProvider.notifier)
            .update((state) => RoomVisibility.SpaceVisible);
      } else {
        ref
            .read(selectedVisibilityProvider.notifier)
            .update((state) => RoomVisibility.Private);
      }

      //LISTEN for changes on parent space selection
      ref.listenManual(selectedSpaceIdProvider, (previous, next) {
        if (next != null) {
          ref
              .read(selectedVisibilityProvider.notifier)
              .update((state) => RoomVisibility.SpaceVisible);
        } else {
          ref
              .read(selectedVisibilityProvider.notifier)
              .update((state) => RoomVisibility.Private);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppbar(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppbar() {
    final currentParentSpace = ref.watch(selectedSpaceIdProvider);
    final parentSelected = currentParentSpace != null;
    return AppBar(
      title: Text(
        parentSelected
            ? L10n.of(context).createSubspace
            : L10n.of(context).createSpace,
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _avatarBuilder(),
              const SizedBox(height: 20),
              _buildSpaceNameTextField(),
              const SizedBox(height: 20),
              _buildSpaceDescriptionTextField(),
              const SizedBox(height: 20),
              _buildParentSpace(),
              const SizedBox(height: 10),
              _buildVisibility(),
              const SizedBox(height: 20),
              _buildSpaceActionButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarBuilder() {
    return GestureDetector(
      onTap: _handleAvatarUpload,
      child: Center(
        child: Container(
          height: 100,
          width: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(5),
          ),
          child: spaceAvatar != null
              ? Image.file(
                  File(spaceAvatar!.path),
                  fit: BoxFit.cover,
                )
              : Icon(
                  Atlas.up_arrow_from_bracket_thin,
                  color: Theme.of(context).colorScheme.neutral4,
                ),
        ),
      ),
    );
  }

  void _handleAvatarUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: L10n.of(context).uploadAvatar,
      type: FileType.image,
    );
    if (result != null) {
      setState(() {
        spaceAvatar = File(result.files.single.path!);
      });
    } else {
      // user cancelled the picker
    }
  }

  Widget _buildSpaceNameTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(L10n.of(context).spaceName),
        const SizedBox(height: 5),
        InputTextField(
          hintText: L10n.of(context).typeName,
          key: CreateSpaceKeys.titleField,
          textInputType: TextInputType.multiline,
          controller: _spaceNameController,
        ),
        const SizedBox(height: 3),
        Text(
          L10n.of(context).egGlobalMovement,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.neutral4,
              ),
        ),
      ],
    );
  }

  Widget _buildSpaceDescriptionTextField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(L10n.of(context).about),
        const SizedBox(height: 5),
        InputTextField(
          controller: _spaceDescriptionController,
          hintText: L10n.of(context).description,
          textInputType: TextInputType.multiline,
          maxLines: 10,
        ),
      ],
    );
  }

  Widget _buildParentSpace() {
    return SelectSpaceFormField(
      canCheck: 'CanLinkSpaces',
      mandatory: false,
      title: L10n.of(context).parentSpace,
      selectTitle: L10n.of(context).selectParentSpace,
    );
  }

  Widget _buildVisibility() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).visibilityTitle,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          L10n.of(context).visibilitySubtitle,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.neutral4,
              ),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            final spaceVisibility = ref.read(selectedVisibilityProvider);
            final selected = await selectVisibilityDrawer(
              context: context,
              selectedVisibilityEnum: spaceVisibility,
              isLimitedVisibilityShow:
                  ref.read(selectedSpaceIdProvider) != null,
            );
            if (selected != null) {
              ref
                  .read(selectedVisibilityProvider.notifier)
                  .update((state) => selected);
            }
          },
          child: selectedVisibility(),
        ),
      ],
    );
  }

  Widget selectedVisibility() {
    final selectedVisibility = ref.watch(selectedVisibilityProvider);
    switch (selectedVisibility) {
      case RoomVisibility.Public:
        return RoomVisibilityItem(
          iconData: Icons.language,
          title: L10n.of(context).public,
          subtitle: L10n.of(context).publicVisibilitySubtitle,
          isShowRadio: false,
        );
      case RoomVisibility.Private:
        return RoomVisibilityItem(
          iconData: Icons.lock,
          title: L10n.of(context).private,
          subtitle: L10n.of(context).privateVisibilitySubtitle,
          isShowRadio: false,
        );
      case RoomVisibility.SpaceVisible:
        return RoomVisibilityItem(
          iconData: Atlas.users,
          title: L10n.of(context).limited,
          subtitle: L10n.of(context).limitedVisibilitySubtitle,
          isShowRadio: false,
        );
      default:
        return RoomVisibilityItem(
          iconData: Icons.lock,
          title: L10n.of(context).private,
          subtitle: L10n.of(context).privateVisibilitySubtitle,
          isShowRadio: false,
        );
    }
  }

  Widget _buildSpaceActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => context.pop(),
          child: Text(L10n.of(context).cancel),
        ),
        const SizedBox(width: 20),
        ActerPrimaryActionButton(
          onPressed: _handleCreateSpace,
          child: Text(L10n.of(context).createSpace),
        ),
      ],
    );
  }

  Future<void> _handleCreateSpace() async {
    EasyLoading.show(status: L10n.of(context).creatingSpace);
    try {
      final sdk = await ref.read(sdkProvider.future);
      final config = sdk.api.newSpaceSettingsBuilder();
      config.setName(_spaceNameController.text.trim());
      if (_spaceDescriptionController.text.isNotEmpty) {
        config.setTopic(_spaceDescriptionController.text.trim());
      }
      if (spaceAvatar != null && spaceAvatar!.path.isNotEmpty) {
        // space creation will upload it
        config.setAvatarUri(spaceAvatar!.path);
      }
      final parentRoomId = ref.read(selectedSpaceIdProvider);
      if (parentRoomId != null) {
        config.setParent(parentRoomId);
      }
      final roomVisibility = ref.read(selectedVisibilityProvider);
      if (roomVisibility != null) {
        config.setVisibility(roomVisibility.name);
      }
      final client = ref.read(alwaysClientProvider);
      final roomId = await client.createActerSpace(config.build());
      if (parentRoomId != null) {
        final space = await ref.read(spaceProvider(parentRoomId).future);
        await space.addChildRoom(roomId.toString());
        // spaceRelations come from the server and must be manually invalidated
        ref.invalidate(spaceRelationsOverviewProvider(parentRoomId));
      }

      EasyLoading.dismiss();
      if (!mounted) return;
      context.replaceNamed(
        Routes.spaceInvite.name,
        pathParameters: {'spaceId': roomId.toString()},
      );
    } catch (err) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).creatingSpaceFailed(err),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
