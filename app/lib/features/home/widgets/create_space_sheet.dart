import 'dart:io';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/space/providers/space_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

final titleProvider = StateProvider<String>((ref) => '');

// upload avatar path
final avatarProvider = StateProvider.autoDispose<String>((ref) => '');

class CreateSpacePage extends ConsumerStatefulWidget {
  const CreateSpacePage({super.key});

  @override
  ConsumerState<CreateSpacePage> createState() =>
      _CreateSpacePageConsumerState();
}

class _CreateSpacePageConsumerState extends ConsumerState<CreateSpacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final _titleInput = ref.watch(titleProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Create Space',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 15),
            const Text('Create new space and start organizing.'),
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
            const SizedBox(height: 15),
            const Text('Wallpaper'),
            GestureDetector(
              onTap: () => customMsgSnackbar(
                context,
                'Wallpaper uploading feature isn\'t available yet',
              ),
              child: Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.all(10),
                height: 75,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    Atlas.up_arrow_from_bracket_thin,
                    color: Theme.of(context).colorScheme.neutral4,
                  ),
                ),
              ),
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
              ],
            ),
            const Spacer(),
            Expanded(
              child: Row(
                children: <Widget>[
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => context.pop(),
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
                    onPressed: () => _titleInput.isNotEmpty
                        ? _handleCreateSpace(
                            context,
                            _titleInput,
                            _descriptionController.text.trim(),
                          )
                        : customMsgSnackbar(
                            context,
                            'Please enter space name',
                          ),
                    child: const Text('Create Space'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _titleInput.isNotEmpty
                          ? Theme.of(context).colorScheme.success
                          : Theme.of(context)
                              .colorScheme
                              .success
                              .withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      foregroundColor: Theme.of(context).colorScheme.neutral6,
                      textStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      String filepath = file.path;
      ref.read(avatarProvider.notifier).update((state) => filepath);
    } else {
      // user cancelled the picker
    }
  }

  void _handleCreateSpace(
    BuildContext context,
    String spaceName,
    String? description,
  ) async {
    popUpDialog(
      context: context,
      title: Text(
        'Creating Space',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    );
    final sdk = await ref.watch(sdkProvider.future);
    var avatarUri = ref.read(avatarProvider);
    var settings = sdk.newSpaceSettings(
      spaceName,
      description,
      avatarUri.isNotEmpty ? avatarUri : null,
    );
    final client = ref.read(clientProvider)!;
    var roomId = await client.createActerSpace(settings);
    debugPrint('New Space created: ${roomId.toString()}:$spaceName');

    // pop off loading dialog once process finished.
    context.pop();
    // refresh spaces list
    ref.invalidate(spacesProvider);
    //FIXME: a way to refresh list from spaces provider?
    context.pop();
  }
}
