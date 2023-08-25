import 'dart:io';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// interface data providers
final _titleProvider = StateProvider<String>((ref) => '');
// upload avatar path
final _avatarProvider = StateProvider.autoDispose<String>((ref) => '');

class CreateChatSheet extends ConsumerStatefulWidget {
  final String? initialSelectedSpaceId;

  const CreateChatSheet({super.key, this.initialSelectedSpaceId});

  @override
  ConsumerState<CreateChatSheet> createState() =>
      _CreateChatSheetConsumerState();
}

class _CreateChatSheetConsumerState extends ConsumerState<CreateChatSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  // to determine whether the sheet is opened in space chat / chat
  // when true will restrict to create room in the space when sheet is opened
  bool isSpaceRoom = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedSpaceId != null) {
      isSpaceRoom = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        final notifier = ref.read(selectedSpaceIdProvider.notifier);
        notifier.state = widget.initialSelectedSpaceId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    final avatarUpload = ref.watch(_avatarProvider);
    final currentParentSpace = ref.read(selectedSpaceIdProvider);
    return SideSheet(
      header: 'Create Chat',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text('Avatar'),
                    ),
                    GestureDetector(
                      onTap: _handleAvatarUpload,
                      child: Container(
                        height: 75,
                        width: 75,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: avatarUpload.isNotEmpty
                            ? Image.file(
                                File(avatarUpload),
                                fit: BoxFit.cover,
                              )
                            : Icon(
                                Atlas.up_arrow_from_bracket_thin,
                                color: Theme.of(context).colorScheme.neutral4,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('Chat Name'),
                      ),
                      InputTextField(
                        hintText: 'Type Chat Name',
                        textInputType: TextInputType.multiline,
                        controller: _titleController,
                        onInputChanged: _handleTitleChange,
                      ),
                      const SizedBox(height: 3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('About'),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _descriptionController,
                  hintText: 'Description',
                  textInputType: TextInputType.multiline,
                  maxLines: 10,
                ),
                const SelectSpaceFormField(
                  canCheck: 'CanLinkSpaces',
                  mandatory: true,
                  title: 'Parent space',
                  emptyText: 'optional parent space',
                  selectTitle: 'Select parent space',
                )
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.neutral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.success,
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            if (titleInput.isEmpty) {
              customMsgSnackbar(context, 'Please enter conversation name');
              return;
            }
            if (isSpaceRoom && currentParentSpace == null) {
              return;
            }
            popUpDialog(
              context: context,
              title: Text(
                'Creating Chat room',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              isLoader: true,
            );
            await _handleCreateConvo(
              context,
              titleInput,
              _descriptionController.text.trim(),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: titleInput.isNotEmpty
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.success.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Create Chat'),
        ),
      ],
    );
  }

  void _handleTitleChange(String? value) {
    ref.read(_titleProvider.notifier).update((state) => value!);
  }

  void _handleAvatarUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Upload Avatar',
      type: FileType.image,
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String filepath = file.path;
      ref.read(_avatarProvider.notifier).update((state) => filepath);
    } else {
      // user cancelled the picker
    }
  }

  Future<void> _handleCreateConvo(
    BuildContext context,
    String convoName,
    String description,
  ) async {
    try {
      final sdk = await ref.read(sdkProvider.future);
      final config = sdk.newConvoSettingsBuilder();
      config.setName(convoName);
      if (description.isNotEmpty) {
        config.setTopic(description);
      }
      final avatarUri = ref.read(_avatarProvider);
      if (avatarUri.isNotEmpty) {
        config.setAvatarUri(avatarUri); // convo creation will upload it
      }
      final parentId = ref.read(selectedSpaceIdProvider);
      if (parentId != null) {
        config.setParent(parentId);
      }
      final client = ref.read(clientProvider)!;
      final roomId = await client.createConvo(config.build());
      // add room to child of space (if given)
      if (parentId != null) {
        final space = await ref.read(spaceProvider(parentId).future);
        await space.addChildSpace(roomId.toString());
      }
      final convo = await client.convo(roomId.toString());
      // We are doing as expected, but the lint still triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      context.goNamed(
        Routes.chatroom.name,
        pathParameters: {'roomId': roomId.toString()},
        extra: convo,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }
      context.pop();
      customMsgSnackbar(context, 'Some error occured $e');
    }
  }
}
