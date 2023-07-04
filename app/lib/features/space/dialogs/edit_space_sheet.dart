import 'dart:io';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/home/providers/navigation.dart' as nav;
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final editTitleProvider = StateProvider.autoDispose<String>((ref) => '');
final editTopicProvider = StateProvider.autoDispose<String>((ref) => '');
// upload avatar path
final editAvatarProvider = StateProvider.autoDispose<String>((ref) => '');

class EditSpacePage extends ConsumerStatefulWidget {
  final Space space;
  const EditSpacePage({super.key, required this.space});

  @override
  ConsumerState<EditSpacePage> createState() => _EditSpacePageConsumerState();
}

class _EditSpacePageConsumerState extends ConsumerState<EditSpacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();
  late Map<String, bool> permissions;

  @override
  void initState() {
    super.initState();
    editSpaceData();
  }

  // apply existing data to fields
  void editSpaceData() async {
    final profileData =
        await ref.read(spaceProfileDataProvider(widget.space).future);

    ref
        .read(editTitleProvider.notifier)
        .update((state) => profileData.displayName ?? '');
    ref
        .read(editTopicProvider.notifier)
        .update((state) => widget.space.topic() ?? '');

    if (profileData.hasAvatar()) {
      final spaceId = widget.space.getRoomId().toString();
      File imageFile = await File('$spaceId.jpg')
          .writeAsBytes(profileData.avatar!.asTypedList());
      ref.read(editAvatarProvider.notifier).update((state) => imageFile.path);
    }

    _titleController.text = ref.read(editTitleProvider);
    _topicController.text = ref.read(editTopicProvider);
  }

  @override
  Widget build(BuildContext context) {
    final _titleInput = ref.watch(editTitleProvider);
    return SideSheet(
      header: 'Edit Space',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Here you can change the space details',
            ),
            const SizedBox(height: 15),
            Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(bottom: 5),
                          child: Text('Avatar'),
                        ),
                        const SizedBox(width: 5),
                        ref.watch(editAvatarProvider).isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: GestureDetector(
                                  onTap: () => ref
                                      .read(editAvatarProvider.notifier)
                                      .update((state) => ''),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .neutral4,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    Consumer(
                      builder: (context, ref, child) {
                        final _avatarUpload = ref.watch(editAvatarProvider);
                        return GestureDetector(
                          onTap: _handleAvatarUpload,
                          child: Container(
                            height: 75,
                            width: 75,
                            decoration: BoxDecoration(
                              image: _avatarUpload.isNotEmpty
                                  ? DecorationImage(
                                      image: FileImage(File(_avatarUpload)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: _avatarUpload.isEmpty
                                ? Icon(
                                    Atlas.up_arrow_from_bracket_thin,
                                    color:
                                        Theme.of(context).colorScheme.neutral4,
                                  )
                                : null,
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
                  controller: _topicController,
                  hintText: 'Description',
                  textInputType: TextInputType.multiline,
                  maxLines: 10,
                  onInputChanged: _handleTopicChange,
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
                'Please enter space name',
              );
              return;
            }
            // check permissions before updating space
            bool havePermission = await permissionCheck();
            if (!havePermission) {
              popUpDialog(
                context: context,
                title: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    Atlas.block_prohibited,
                    size: 28,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                subtitle: const Text('Cannot edit space with no permissions'),
                btn2Text: 'Okay',
                onPressedBtn2: () => context.pop(),
                btn2Color: Theme.of(context).colorScheme.success,
              );
              return;
            }
            final roomId = await _handleUpdateSpace(context);
            debugPrint('Space Updated: $roomId');
            // refresh spaces and side bar
            ref.invalidate(spacesProvider);
            ref.invalidate(nav.spaceItemsProvider);
            ref.invalidate(spaceProvider);

            context.goNamed(
              Routes.space.name,
              pathParameters: {
                'spaceId': roomId.toString(),
              },
            );
          },
          child: const Text('Save changes'),
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
    ref.read(editTitleProvider.notifier).update((state) => value!);
  }

  void _handleTopicChange(String? value) {
    ref.read(editTopicProvider.notifier).update((state) => value!);
  }

  void _handleAvatarUpload() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Upload Avatar',
      type: FileType.image,
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      String filepath = file.path;
      ref.read(editAvatarProvider.notifier).update((state) => filepath);
    } else {
      // user cancelled the picker
    }
  }

  // permission check
  Future<bool> permissionCheck() async {
    var member = await widget.space.getMyMembership();
    bool p1 = member.canString('CanSetTopic');
    bool p2 = member.canString('CanUpdateAvatar');
    // all or none case
    return p1 && p2;
  }

  // update space handler
  Future<RoomId> _handleUpdateSpace(BuildContext context) async {
    popUpDialog(
      context: context,
      title: Text(
        'Updating Space',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    );

    // update space name
    String title = ref.read(editTitleProvider);
    try {
      var eventId = await widget.space.setName(title);
      debugPrint('Space update event: $eventId');
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }

    // update space avatar
    String avatarUri = ref.read(editAvatarProvider);
    if (avatarUri.isNotEmpty) {
      var eventId = await widget.space.uploadAvatar(avatarUri);
      debugPrint('Avatar update event: ${eventId.toString()}');
    } else {
      var eventId = await widget.space.removeAvatar();
      debugPrint('Avatar removed event: ${eventId.toString()}');
    }

    //update space topic
    String topic = ref.read(editTopicProvider);
    var eventId = await widget.space.setTopic(topic);
    debugPrint('topic update event: $eventId');

    return widget.space.getRoomId();
  }
}
