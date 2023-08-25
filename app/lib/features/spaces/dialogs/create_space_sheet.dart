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
final titleProvider = StateProvider<String>((ref) => '');
// upload avatar path
final avatarProvider = StateProvider.autoDispose<String>((ref) => '');

class CreateSpacePage extends ConsumerStatefulWidget {
  final String? initialParentsSpaceId;
  const CreateSpacePage({super.key, this.initialParentsSpaceId});

  @override
  ConsumerState<CreateSpacePage> createState() =>
      _CreateSpacePageConsumerState();
}

class _CreateSpacePageConsumerState extends ConsumerState<CreateSpacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
      parentNotifier.state = widget.initialParentsSpaceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(titleProvider);
    final currentParentSpace = ref.watch(selectedSpaceIdProvider);
    final parentSelected = currentParentSpace != null;
    return SideSheet(
      header: parentSelected ? 'Create Subspace' : 'Create Space',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              parentSelected
                  ? 'Create a new subspace'
                  : 'Create new space and start organizing.',
            ),
            const SizedBox(height: 15),
            Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text('Avatar'),
                    ),
                    Consumer(builder: avatarBuilder),
                  ],
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('Space Name'),
                      ),
                      InputTextField(
                        hintText: 'Type Name',
                        textInputType: TextInputType.multiline,
                        controller: _titleController,
                        onInputChanged: _handleTitleChange,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'eg. Global Movement',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                              color: Theme.of(context).colorScheme.neutral4,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // const SizedBox(height: 15),
            // const Text('Wallpaper'),
            // GestureDetector(
            //   onTap: () => customMsgSnackbar(
            //     context,
            //     'Wallpaper uploading feature isn\'t available yet',
            //   ),
            //   child: Container(
            //     margin: const EdgeInsets.only(top: 15),
            //     padding: const EdgeInsets.all(10),
            //     height: 75,
            //     decoration: BoxDecoration(
            //       color: Theme.of(context).colorScheme.primaryContainer,
            //       borderRadius: BorderRadius.circular(12),
            //     ),
            //     child: Align(
            //       alignment: Alignment.centerLeft,
            //       child: Icon(
            //         Atlas.up_arrow_from_bracket_thin,
            //         color: Theme.of(context).colorScheme.neutral4,
            //       ),
            //     ),
            //   ),
            // ),
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
                  mandatory: false,
                  title: 'Parent space',
                  selectTitle: 'Select parent space',
                ),
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
              customMsgSnackbar(context, 'Please enter space name');
              return;
            }
            await _handleCreateSpace(
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
          child: const Text('Create Space'),
        ),
      ],
    );
  }

  Widget avatarBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final avatarUpload = ref.watch(avatarProvider);
    return GestureDetector(
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
    );
  }

  void _handleTitleChange(String? value) {
    ref.read(titleProvider.notifier).update((state) => value!);
  }

  void _handleAvatarUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Upload Avatar',
      type: FileType.image,
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      ref.read(avatarProvider.notifier).update((state) => file.path);
    } else {
      // user cancelled the picker
    }
  }

  Future<void> _handleCreateSpace(
    BuildContext context,
    String spaceName,
    String description,
  ) async {
    popUpDialog(
      context: context,
      title: Text(
        'Creating Space',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    );
    try {
      final sdk = await ref.read(sdkProvider.future);
      final config = sdk.newSpaceSettingsBuilder();
      config.setName(spaceName);
      if (description.isNotEmpty) {
        config.setTopic(description);
      }
      final localUri = ref.read(avatarProvider);
      if (localUri.isNotEmpty) {
        config.setAvatarUri(localUri); // space creation will upload it
      }
      final parentRoomId = ref.read(selectedSpaceIdProvider);
      if (parentRoomId != null) {
        config.setParent(parentRoomId);
      }
      final client = ref.read(clientProvider)!;
      final roomId = await client.createActerSpace(config.build());
      if (parentRoomId != null) {
        final space = await ref.read(spaceProvider(parentRoomId).future);
        await space.addChildSpace(roomId.toString());
      }

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();
      context.goNamed(
        Routes.space.name,
        pathParameters: {
          'spaceId': roomId.toString(),
        },
      );
    } catch (err) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();

      popUpDialog(
        context: context,
        title: Text(
          'Creating Space failed: \n $err"',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        isLoader: false,
        btnText: 'Close',
        onPressedBtn: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      );
    }
  }
}
