import 'dart:io';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final titleProvider = StateProvider<String>((ref) => '');
final parentSpaceProvider = StateProvider<String?>((ref) => null);
final parentSpaceDetailsProvder =
    FutureProvider.autoDispose<SpaceItem?>((ref) async {
  final parentSpaceId = ref.watch(parentSpaceProvider);
  if (parentSpaceId == null) {
    return null;
  }

  final spaces = await ref.watch(briefSpaceItemsProviderWithMembership.future);
  return spaces.firstWhere((element) => element.roomId == parentSpaceId);
});

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
    Future(() {
      ref.read(parentSpaceProvider.notifier).state =
          widget.initialParentsSpaceId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final _titleInput = ref.watch(titleProvider);
    final currentParentSpace = ref.watch(parentSpaceProvider);
    final _selectParentSpace = currentParentSpace != null;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              _selectParentSpace ? 'Create Subspace' : 'Create Space',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 15),
            Text(
              _selectParentSpace
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
                ListTile(
                  title: Text(
                    _selectParentSpace
                        ? 'Parent space'
                        : 'No parent space selected',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: _selectParentSpace
                      ? Consumer(
                          builder: (context, ref, child) =>
                              ref.watch(parentSpaceDetailsProvder).when(
                                    data: (space) => space != null
                                        ? SpaceChip(space: space)
                                        : Text(currentParentSpace),
                                    error: (e, s) => Text('error: $e'),
                                    loading: () => const Text('loading'),
                                  ),
                        )
                      : null,
                  onTap: () {
                    openParentSpaceDrawer(context);
                  },
                )
              ],
            ),
            const Spacer(),
            Expanded(
              child: Row(
                children: <Widget>[
                  const Spacer(),
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
                      final roomId = await _handleCreateSpace(
                        context,
                        _titleInput,
                        _descriptionController.text.trim(),
                      );
                      context.goNamed(
                        Routes.space.name,
                        pathParameters: {
                          'spaceId': roomId.toString(),
                        },
                      );
                    },
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

  void openParentSpaceDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final spaces = ref.watch(briefSpaceItemsProviderWithMembership);
          final currentSpace = ref.watch(parentSpaceProvider);
          return SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Select Parent space'),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Atlas.minus_circle_thin),
                        onPressed: () {
                          ref.read(parentSpaceProvider.notifier).state = null;
                          Navigator.pop(context);
                        },
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: spaces.when(
                      data: (spaces) => spaces.isEmpty
                          ? const Text('no spaces found')
                          : ListView.builder(
                              padding: const EdgeInsets.all(8),
                              itemCount: spaces.length,
                              itemBuilder: (context, index) {
                                final item = spaces[index];
                                final membership = item.membership!;
                                final profile = item.spaceProfileData;
                                final roomId = item.roomId;
                                final canLink =
                                    membership.canString('CanLinkSpaces');
                                return ListTile(
                                  enabled: canLink,
                                  leading: ActerAvatar(
                                    mode: DisplayMode.Space,
                                    displayName: profile.displayName,
                                    uniqueId: roomId,
                                    avatar: profile.getAvatarImage(),
                                    size: 24,
                                  ),
                                  title: Text(profile.displayName ?? roomId),
                                  trailing: currentSpace == roomId
                                      ? const Icon(Icons.check_circle_outline)
                                      : null,
                                  onTap: canLink
                                      ? () {
                                          ref
                                              .read(
                                                parentSpaceProvider.notifier,
                                              )
                                              .state = roomId;
                                          Navigator.pop(context);
                                        }
                                      : null,
                                );
                              },
                            ),
                      error: (e, s) => Center(
                        child: Text('error loading spaces: $e'),
                      ),
                      loading: () => const Center(
                        child: Text('loading'),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
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

  Future<RoomId> _handleCreateSpace(
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
    final parentRoomId = ref.watch(parentSpaceProvider);
    var avatarUri = ref.read(avatarProvider);
    var settings = sdk.newSpaceSettings(
      spaceName,
      description,
      avatarUri.isNotEmpty ? avatarUri : null,
      parentRoomId,
    );
    final client = ref.read(clientProvider)!;
    final roomId = await client.createActerSpace(settings);
    if (parentRoomId != null) {
      final space = await ref.read(spaceProvider(parentRoomId).future);
      await space.addChildSpace(roomId.toString());
    }
    Navigator.of(context, rootNavigator: true).pop();
    return roomId;
  }
}
