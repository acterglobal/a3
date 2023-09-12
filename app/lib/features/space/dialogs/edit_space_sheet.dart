import 'dart:io';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

// interface data providers
final editTitleProvider = StateProvider.autoDispose<String>((ref) => '');
final editTopicProvider = StateProvider.autoDispose<String>((ref) => '');
// upload avatar path
final editAvatarProvider = StateProvider.autoDispose<String>((ref) => '');

class EditSpacePage extends ConsumerStatefulWidget {
  final String? spaceId;
  const EditSpacePage({super.key, required this.spaceId});

  @override
  ConsumerState<EditSpacePage> createState() => _EditSpacePageConsumerState();
}

class _EditSpacePageConsumerState extends ConsumerState<EditSpacePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editSpaceData();
  }

  // apply existing data to fields
  void _editSpaceData() async {
    final space = ref.read(spaceProvider(widget.spaceId!)).requireValue;
    final profileData = await ref.read(spaceProfileDataProvider(space).future);
    final titleNotifier = ref.read(editTitleProvider.notifier);
    final topicNotifier = ref.read(editTopicProvider.notifier);
    final avatarNotifier = ref.read(editAvatarProvider.notifier);

    titleNotifier.update((state) => profileData.displayName ?? '');
    topicNotifier.update((state) => space.topic() ?? '');

    if (profileData.hasAvatar()) {
      Directory appDocDirectory = await getApplicationDocumentsDirectory();
      Directory('${appDocDirectory.path}/dir')
          .create(recursive: true)
          .then((Directory directory) {});
      String filePath = '${appDocDirectory.path}/${widget.spaceId}.jpg';
      final imageFile = File(filePath);
      imageFile.writeAsBytes(profileData.avatar!.asTypedList());
      avatarNotifier.update((state) => imageFile.path);
    }

    _titleController.text = ref.read(editTitleProvider);
    _topicController.text = ref.read(editTopicProvider);
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(editTitleProvider);
    final avatarUpload = ref.watch(editAvatarProvider);
    final avatarNotifier = ref.watch(editAvatarProvider.notifier);
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
                        avatarUpload.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: GestureDetector(
                                  onTap: () {
                                    avatarNotifier.update((state) => '');
                                  },
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
              customMsgSnackbar(
                context,
                'Please enter space name',
              );
              return;
            }
            // check permissions before updating space
            bool havePermission = await permissionCheck();
            // We are doing as expected, but the lints triggers.
            // ignore: use_build_context_synchronously
            if (!context.mounted) {
              return;
            }
            if (!havePermission) {
              showAdaptiveDialog(
                context: context,
                builder: (context) => DefaultDialog(
                  title: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Atlas.block_prohibited,
                      size: 28,
                      color: Theme.of(context).colorScheme.onError,
                    ),
                  ),
                  subtitle: const Text('Cannot edit space with no permissions'),
                  actions: <Widget>[
                    DefaultButton(
                      onPressed: () => context.pop(),
                      title: 'Okay',
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.success,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              return;
            }
            final roomId = await _handleUpdateSpace(context);
            debugPrint('Space Updated: $roomId');
            // We are doing as expected, but the lints triggers.
            // ignore: use_build_context_synchronously
            if (!context.mounted) {
              return;
            }
            context.goNamed(
              Routes.space.name,
              pathParameters: {
                'spaceId': roomId.toString(),
              },
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
          child: const Text('Save changes'),
        ),
      ],
    );
  }

  Widget avatarBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final avatarUpload = ref.watch(editAvatarProvider);
    return GestureDetector(
      onTap: _handleAvatarUpload,
      child: Container(
        height: 75,
        width: 75,
        decoration: BoxDecoration(
          image: avatarUpload.isNotEmpty
              ? DecorationImage(
                  image: FileImage(File(avatarUpload)),
                  fit: BoxFit.cover,
                )
              : null,
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(5),
        ),
        child: avatarUpload.isEmpty
            ? Icon(
                Atlas.up_arrow_from_bracket_thin,
                color: Theme.of(context).colorScheme.neutral4,
              )
            : null,
      ),
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
    final space = await ref.read(spaceProvider(widget.spaceId!).future);
    final membership = await space.getMyMembership();
    return membership.canString('CanSetTopic');
  }

  // update space handler
  Future<RoomId> _handleUpdateSpace(BuildContext context) async {
    showAdaptiveDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => DefaultDialog(
        title: Text(
          'Updating Space',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        isLoader: true,
      ),
    );

    final space = await ref.read(spaceProvider(widget.spaceId!).future);
    // update space name
    String title = ref.read(editTitleProvider);
    try {
      final eventId = await space.setName(title);
      debugPrint('Space update event: $eventId');
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }

    // update space avatar
    String avatarUri = ref.read(editAvatarProvider);
    if (avatarUri.isNotEmpty) {
      final eventId = await space.uploadAvatar(avatarUri);
      debugPrint('Avatar update event: ${eventId.toString()}');
    } else {
      final eventId = await space.removeAvatar();
      debugPrint('Avatar removed event: ${eventId.toString()}');
    }

    //update space topic
    String topic = ref.read(editTopicProvider);
    final eventId = await space.setTopic(topic);
    debugPrint('topic update event: $eventId');

    return space.getRoomId();
  }
}
