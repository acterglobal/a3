import 'dart:io';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/common/widgets/visibility/room_visibility_item.dart';
import 'package:acter/common/widgets/visibility/visibility_selector_drawer.dart';
import 'package:acter/features/spaces/actions/create_space.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

// user selected visibility provider
final _selectedVisibilityProvider =
    StateProvider.autoDispose<RoomVisibility?>((ref) => null);

class CreateSpacePage extends ConsumerStatefulWidget {
  static const permissionsKey = Key('create-space-permissions-key');
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
  bool createDefaultChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
      parentNotifier.state = widget.initialParentsSpaceId;
      setState(() {
        // create default chats for highest level spaces, off by default
        // for subspaces.
        createDefaultChat = widget.initialParentsSpaceId == null;
      });

      //Set default visibility based on the parent space selection
      // PRIVATE : If no parent is selected
      // SPACE VISIBLE : If parent space is selected
      ref.read(_selectedVisibilityProvider.notifier).update(
            (state) => widget.initialParentsSpaceId != null
                ? RoomVisibility.SpaceVisible
                : RoomVisibility.Private,
          );
      //LISTEN for changes on parent space selection
      ref.listenManual(selectedSpaceIdProvider, (previous, next) {
        ref.read(_selectedVisibilityProvider.notifier).update(
              (state) => next != null
                  ? RoomVisibility.SpaceVisible
                  : RoomVisibility.Private,
            );
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
              const SizedBox(height: 10),
              _buildDefaultChatField(),
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
              : const Icon(Atlas.up_arrow_from_bracket_thin),
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
          style: Theme.of(context).textTheme.labelSmall!,
        ),
      ],
    );
  }

  Widget _buildDefaultChatField() {
    return InkWell(
      onTap: () {
        setState(() {
          createDefaultChat = !createDefaultChat;
        });
      },
      child: Row(
        children: [
          Switch(
            value: createDefaultChat,
            onChanged: (newValue) => setState(() {
              createDefaultChat = newValue;
            }),
          ),
          Text(L10n.of(context).createDefaultChat),
        ],
      ),
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
          style: Theme.of(context).textTheme.bodySmall!,
        ),
        const SizedBox(height: 10),
        InkWell(
          key: CreateSpacePage.permissionsKey,
          onTap: () async {
            final spaceVisibility = ref.read(_selectedVisibilityProvider);
            final selected = await selectVisibilityDrawer(
              context: context,
              selectedVisibilityEnum: spaceVisibility,
              isLimitedVisibilityShow:
                  ref.read(selectedSpaceIdProvider) != null,
            );
            if (selected != null) {
              ref
                  .read(_selectedVisibilityProvider.notifier)
                  .update((state) => selected);
            }
          },
          child: selectedVisibility(),
        ),
      ],
    );
  }

  Widget selectedVisibility() {
    final selectedVisibility = ref.watch(_selectedVisibilityProvider);
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
          key: CreateSpaceKeys.submitBtn,
          onPressed: _handleCreateSpace,
          child: Text(L10n.of(context).createSpace),
        ),
      ],
    );
  }

  Future<void> _handleCreateSpace() async {
    final newRoomId = await createSpace(
      context,
      ref,
      name: _spaceNameController.text.trim(),
      description: _spaceDescriptionController.text.trim(),
      spaceAvatar: spaceAvatar,
      createDefaultChat: createDefaultChat,
      parentRoomId: ref.read(selectedSpaceIdProvider),
      roomVisibility: ref.read(_selectedVisibilityProvider),
    );
    if (!mounted) return;
    if (newRoomId != null) {
      context.replaceNamed(
        Routes.spaceInvite.name,
        pathParameters: {'spaceId': newRoomId},
      );
    }
  }
}
