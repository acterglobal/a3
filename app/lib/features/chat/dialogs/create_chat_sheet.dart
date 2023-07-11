import 'dart:io';

import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';

// interface data providers
final titleProvider = StateProvider<String>((ref) => '');
// upload avatar path
final avatarProvider = StateProvider.autoDispose<String>((ref) => '');

class CreateChatSheet extends ConsumerStatefulWidget {
  const CreateChatSheet({super.key});

  @override
  ConsumerState<CreateChatSheet> createState() =>
      _CreateChatSheetConsumerState();
}

class _CreateChatSheetConsumerState extends ConsumerState<CreateChatSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final _titleInput = ref.watch(titleProvider);
    final currentParentSpace = ref.watch(parentSpaceProvider);
    final _selectParentSpace = currentParentSpace != null;
    return SideSheet(
      header: 'Create Chat Room',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Create a new group chat',
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
                    Consumer(
                      builder: (context, ref, child) {
                        final _avatarUpload = ref.watch(avatarProvider);
                        return GestureDetector(
                          onTap: _handleAvatarUpload,
                          child: Container(
                            height: 75,
                            width: 75,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: _avatarUpload.isNotEmpty
                                ? Image.file(
                                    File(_avatarUpload),
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Atlas.up_arrow_from_bracket_thin,
                                    color:
                                        Theme.of(context).colorScheme.neutral4,
                                  ),
                          ),
                        );
                      },
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
                        child: Text('Group Name'),
                      ),
                      InputTextField(
                        hintText: 'Type Group Name',
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
                ListTile(
                  title: Text(
                    'No space selected',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectParentSpace
                      ? Consumer(
                          builder: (context, ref, child) =>
                              ref.watch(parentSpaceDetailsProvider).when(
                                    data: (space) => space != null
                                        ? SpaceChip(space: space)
                                        : Text(currentParentSpace),
                                    error: (e, s) => Text('error: $e'),
                                    loading: () => const Text('loading'),
                                  ),
                        )
                      : null,
                  onTap: () async {
                    final currentSpaceId = ref.read(parentSpaceProvider);
                    final newSelectedSpaceId = await selectSpaceDrawer(
                      context: context,
                      currentSpaceId: currentSpaceId,
                      title: const Text('Select space'),
                    );
                    ref.read(parentSpaceProvider.notifier).state =
                        newSelectedSpaceId;
                  },
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
          child: const Text('Cancel'),
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
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            if (_titleInput.isEmpty) {
              customMsgSnackbar(
                context,
                'Please enter group name',
              );
              return;
            }
          },
          child: const Text('Create Room'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _titleInput.isNotEmpty
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.success.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
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
      String filepath = file.path;
      ref.read(avatarProvider.notifier).update((state) => filepath);
    } else {
      // user cancelled the picker
    }
  }
}

//   Future<RoomId> _handleCreateChatRoom(
//     BuildContext context,
//     String spaceName,
//     String? description,
//   ) async {
//     popUpDialog(
//       context: context,
//       title: Text(
//         'Creating Chat room',
//         style: Theme.of(context).textTheme.titleSmall,
//       ),
//       isLoader: true,
//     );
//   }
// }
