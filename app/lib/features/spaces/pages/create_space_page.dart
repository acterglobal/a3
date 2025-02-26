import 'dart:io';

import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/common/widgets/visibility/room_visibility_item.dart';
import 'package:acter/common/widgets/visibility/visibility_selector_drawer.dart';
import 'package:acter/features/files/actions/pick_avatar.dart';
import 'package:acter/features/room/model/room_visibility.dart';
import 'package:acter/features/spaces/actions/create_space.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::spaces::create_space');

// user selected visibility provider
final _selectedVisibilityProvider =
    StateProvider.autoDispose<RoomVisibility?>((ref) => null);

class CreateSpacePage extends ConsumerStatefulWidget {
  static const permissionsKey = Key('create-space-permissions-key');

  final String? initialParentsSpaceId;

  const CreateSpacePage({
    super.key,
    this.initialParentsSpaceId,
  });

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
      final visibleNotifier = ref.read(_selectedVisibilityProvider.notifier);
      visibleNotifier.update(
        (state) => widget.initialParentsSpaceId != null
            ? RoomVisibility.SpaceVisible
            : RoomVisibility.Private,
      );
      //LISTEN for changes on parent space selection
      ref.listenManual(selectedSpaceIdProvider, (previous, next) {
        final visibleNotifier = ref.read(_selectedVisibilityProvider.notifier);
        visibleNotifier.update(
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
    final lang = L10n.of(context);
    final currentParentSpace = ref.watch(selectedSpaceIdProvider);
    final parentSelected = currentParentSpace != null;
    return AppBar(
      title: Text(parentSelected ? lang.createSubspace : lang.createSpace),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
          child: spaceAvatar.map(
                (file) => Image.file(
                  File(file.path),
                  fit: BoxFit.cover,
                ),
              ) ??
              const Icon(Atlas.up_arrow_from_bracket_thin),
        ),
      ),
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

  Widget _buildSpaceNameTextField() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(lang.spaceName),
        const SizedBox(height: 5),
        InputTextField(
          hintText: lang.typeName,
          key: CreateSpaceKeys.titleField,
          textInputType: TextInputType.multiline,
          controller: _spaceNameController,
        ),
        const SizedBox(height: 3),
        Text(
          lang.egGlobalMovement,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildDefaultChatField() {
    return InkWell(
      onTap: () {
        setState(() => createDefaultChat = !createDefaultChat);
      },
      child: Row(
        children: [
          Switch(
            value: createDefaultChat,
            onChanged: (newValue) {
              setState(() => createDefaultChat = newValue);
            },
          ),
          Text(L10n.of(context).createDefaultChat),
        ],
      ),
    );
  }

  Widget _buildSpaceDescriptionTextField() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(lang.about),
        const SizedBox(height: 5),
        InputTextField(
          controller: _spaceDescriptionController,
          hintText: lang.description,
          textInputType: TextInputType.multiline,
          maxLines: 10,
        ),
      ],
    );
  }

  Widget _buildParentSpace() {
    final lang = L10n.of(context);
    return SelectSpaceFormField(
      canCheck: (m) => m?.canString('CanLinkSpaces') == true,
      mandatory: false,
      title: lang.parentSpace,
      selectTitle: lang.selectParentSpace,
      emptyText: lang.optionalParentSpace,
    );
  }

  Widget _buildVisibility() {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.visibilityTitle,
          style: textTheme.bodyMedium,
        ),
        Text(
          lang.visibilitySubtitle,
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        InkWell(
          key: CreateSpacePage.permissionsKey,
          onTap: () async {
            final spaceVisibility = ref.read(_selectedVisibilityProvider);
            final selectedSpace = ref.read(selectedSpaceIdProvider);
            final selected = await selectVisibilityDrawer(
              context: context,
              selectedVisibilityEnum: spaceVisibility,
              isLimitedVisibilityShow: selectedSpace != null,
            );
            if (selected != null) {
              final notifier = ref.read(_selectedVisibilityProvider.notifier);
              notifier.update((state) => selected);
            }
          },
          child: selectedVisibility(),
        ),
      ],
    );
  }

  Widget selectedVisibility() {
    final lang = L10n.of(context);
    return switch (ref.watch(_selectedVisibilityProvider)) {
      RoomVisibility.Public => RoomVisibilityItem(
          iconData: Icons.language,
          title: lang.public,
          subtitle: lang.publicVisibilitySubtitle,
          isShowRadio: false,
        ),
      RoomVisibility.Private => RoomVisibilityItem(
          iconData: Icons.lock,
          title: lang.private,
          subtitle: lang.privateVisibilitySubtitle,
          isShowRadio: false,
        ),
      RoomVisibility.SpaceVisible => RoomVisibilityItem(
          iconData: Atlas.users,
          title: lang.limited,
          subtitle: lang.limitedVisibilitySubtitle,
          isShowRadio: false,
        ),
      _ => RoomVisibilityItem(
          iconData: Icons.lock,
          title: lang.private,
          subtitle: lang.privateVisibilitySubtitle,
          isShowRadio: false,
        ),
    };
  }

  Widget _buildSpaceActionButtons() {
    final lang = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.cancel),
        ),
        const SizedBox(width: 20),
        ActerPrimaryActionButton(
          key: CreateSpaceKeys.submitBtn,
          onPressed: _handleCreateSpace,
          child: Text(lang.createSpace),
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
