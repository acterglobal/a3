import 'dart:io';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/router/utils.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final _log = Logger('a3::space::edit');

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
  Future<void> _editSpaceData() async {
    final space = ref.read(spaceProvider(widget.spaceId!)).requireValue;
    final profileData = await ref.read(spaceProfileDataProvider(space).future);
    final titleNotifier = ref.read(editTitleProvider.notifier);
    final topicNotifier = ref.read(editTopicProvider.notifier);
    final avatarNotifier = ref.read(editAvatarProvider.notifier);

    titleNotifier.update((state) => profileData.displayName ?? '');
    topicNotifier.update((state) => space.topic() ?? '');

    if (profileData.hasAvatar()) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      final dirPath = p.join(appDocDir.path, 'dir');
      await Directory(dirPath).create(recursive: true);
      String filePath = p.join(appDocDir.path, '${widget.spaceId}.jpg');
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
    ref.watch(editTopicProvider);
    return SliverScaffold(
      header: L10n.of(context).editSpace,
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(L10n.of(context).hereYouCanChangeTheSpaceDetails),
            const SizedBox(height: 15),
            Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Text(L10n.of(context).avatar),
                        ),
                        const SizedBox(width: 5),
                        avatarUpload.isNotEmpty
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 5),
                                child: GestureDetector(
                                  onTap: _clearAvatar,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .neutral4,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14),
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
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(L10n.of(context).spaceName),
                      ),
                      InputTextField(
                        hintText: L10n.of(context).typeName,
                        textInputType: TextInputType.multiline,
                        controller: _titleController,
                        onInputChanged: _handleTitleChange,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        L10n.of(context).egGlobalMovement,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(L10n.of(context).about),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _topicController,
                  hintText: L10n.of(context).description,
                  textInputType: TextInputType.multiline,
                  maxLines: 10,
                  onInputChanged: _handleTopicChange,
                ),
              ],
            ),
          ],
        ),
      ),
      confirmActionTitle: L10n.of(context).saveChanges,
      cancelActionTitle: L10n.of(context).cancel,
      confirmActionOnPressed: () async => await _handleConfirm(titleInput),
      cancelActionOnPressed: _handleCancel,
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
      dialogTitle: L10n.of(context).uploadAvatar,
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
    final space = await ref.read(spaceProvider(widget.spaceId!).future);
    // update space name
    String title = ref.read(editTitleProvider);
    try {
      final eventId = await space.setName(title);
      _log.info('Space update event: $eventId');
    } catch (e, s) {
      _log.severe('Update failed', e, s);
      rethrow;
    }

    // update space avatar
    String avatarUri = ref.read(editAvatarProvider);
    if (avatarUri.isNotEmpty) {
      final eventId = await space.uploadAvatar(avatarUri);
      _log.info('Avatar update event: ${eventId.toString()}');
    } else {
      final eventId = await space.removeAvatar();
      _log.info('Avatar removed event: ${eventId.toString()}');
    }

    //update space topic
    String topic = ref.read(editTopicProvider);
    final eventId = await space.setTopic(topic);
    _log.info('topic update event: $eventId');

    return space.getRoomId();
  }

  Future<void> _handleConfirm(String titleInput) async {
    if (titleInput.trim().isEmpty) return;
    // check permissions before updating space
    bool havePermission = await permissionCheck();
    if (!mounted) return;
    if (!havePermission && context.mounted) {
      EasyLoading.showError(
        L10n.of(context).cannotEditSpaceWithNoPermissions,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    if (!mounted) return;
    EasyLoading.show(status: L10n.of(context).updatingSpace);
    try {
      final roomId = await _handleUpdateSpace(context);
      _log.info('Space Updated: $roomId');
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      goToSpace(context, roomId.toString());
    } catch (e, st) {
      _log.severe('Failed to edit space', e, st);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).failedToEditSpace(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _handleCancel() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(Routes.main.name);
    }
  }

  void _clearAvatar() {
    final avatarNotifier = ref.read(editAvatarProvider.notifier);
    avatarNotifier.update((state) => '');
  }
}
