import 'dart:io';

import 'package:acter/common/dialogs/invite_to_room_dialog.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// saves selected users from search result
final _selectedUsersProvider =
    StateProvider.autoDispose<List<ffi.UserProfile>>((ref) => []);

/// Room title
final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
// upload avatar path
final _avatarProvider = StateProvider.autoDispose<String>((ref) => '');

class CreateChatPage extends ConsumerStatefulWidget {
  final String? initialSelectedSpaceId;
  final int? initialPage;
  const CreateChatPage({
    super.key,
    this.initialSelectedSpaceId,
    this.initialPage,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _CreateChatWidgetState();
}

class _CreateChatWidgetState extends ConsumerState<CreateChatPage> {
  late PageController controller;
  late int currIdx;
  late final List<Widget> pages;
  @override
  void initState() {
    super.initState();
    controller = PageController(initialPage: widget.initialPage ?? 0);
    currIdx = controller.initialPage;
    pages = [
      _CreateChatWidget(
        controller: controller,
        onCreateConvo: _handleCreateConvo,
      ),
      _CreateRoomFormWidget(
        controller: controller,
        initialSelectedSpaceId: widget.initialSelectedSpaceId,
        onCreateConvo: _handleCreateConvo,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return isLargeScreen(context)
        ? Container(
            width: size.width * 0.5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  currIdx = index;
                });
              },
              controller: controller,
              itemBuilder: ((context, index) => pages[currIdx]),
            ),
          )
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanDown: (_) => FocusScope.of(context).requestFocus(FocusNode()),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.neutral,
                borderRadius: BorderRadius.circular(12),
              ),
              child: PageView.builder(
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    currIdx = index;
                  });
                },
                controller: controller,
                itemBuilder: ((context, index) => pages[currIdx]),
              ),
            ),
          );
  }

  /// Create Room Method
  Future<ffi.Convo?> _handleCreateConvo(
    String convoName,
    String description,
  ) async {
    EasyLoading.show(status: 'Creating Chat');
    try {
      final sdk = await ref.read(sdkProvider.future);
      final config = sdk.newConvoSettingsBuilder();
      final selectedUsers = ref.watch(_selectedUsersProvider);
      // we check whether user has selected participants for DM/Group DM.
      if (selectedUsers.isNotEmpty) {
        if (selectedUsers.length > 1) {
          // we are creating group DM
          for (int i = 0; i < selectedUsers.length; i++) {
            final userId = selectedUsers[i].userId().toString();
            config.addInvitee(userId);
          }
        } else {
          // we are creating dm
          final userId = selectedUsers[0].userId().toString();

          config.addInvitee(userId);
        }
      } else {
        // we are creating default room
        config.setName(convoName);
      }
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
      final client = ref.read(clientProvider);
      if (client == null) throw UnimplementedError('Client is not available');
      final roomId = await client.createConvo(config.build());
      // add room to child of space (if given)
      if (parentId != null) {
        final space = await ref.read(spaceProvider(parentId).future);
        await space.addChildRoom(roomId.toString());
      }
      final convo = await client.convoWithRetry(roomId.toString(), 12);
      EasyLoading.dismiss();
      EasyLoading.showSuccess(
        'Chat Room Created with Room ID: ${convo.getRoomIdStr()}',
      );
      return convo;
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError(
        'Error creating chat $e',
        duration: const Duration(seconds: 2),
      );
      return null;
    }
  }
}

///
class _CreateChatWidget extends ConsumerStatefulWidget {
  final PageController controller;
  final Future<ffi.Convo?> Function(String, String) onCreateConvo;
  const _CreateChatWidget({
    required this.controller,
    required this.onCreateConvo,
  });

  @override
  ConsumerState<_CreateChatWidget> createState() =>
      _CreateChatWidgetConsumerState();
}

class _CreateChatWidgetConsumerState extends ConsumerState<_CreateChatWidget> {
  ScrollController scrollController = ScrollController();

  // scrolls to upward in list upon user tapping.
  void _onUp() {
    scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedUsers = ref.watch(_selectedUsersProvider).toList();
    final foundUsers = ref.watch(searchResultProvider);
    final searchCtrl = ref.watch(searchController);
    String tileTitle = _makeTitle(ref);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      child: ListView(
        controller: scrollController,
        shrinkWrap: true,
        children: <Widget>[
          Row(
            children: <Widget>[
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.chevron_left),
              ),
              const Spacer(),
              Text(
                'New Chat',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: searchCtrl,
            style: Theme.of(context).textTheme.labelMedium,
            decoration: InputDecoration(
              isCollapsed: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.secondaryContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              hintText: 'Search Username to start a DM',
              hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ),
              contentPadding: const EdgeInsets.all(18),
              hintMaxLines: 1,
            ),
            onChanged: (String val) =>
                ref.read(searchValueProvider.notifier).update((state) => val),
          ),
          const SizedBox(height: 15),
          Visibility(
            visible: selectedUsers.isNotEmpty,
            replacement: const SizedBox.shrink(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                direction: Axis.horizontal,
                spacing: 5.0,
                runSpacing: 5.0,
                children: List.generate(
                  selectedUsers.length,
                  (index) => Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final avatarProv =
                            ref.watch(userAvatarProvider(selectedUsers[index]));
                        final displayName = ref
                            .watch(displayNameProvider(selectedUsers[index]));
                        final userId = selectedUsers[index].userId().toString();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ActerAvatar(
                              uniqueId: userId,
                              mode: DisplayMode.User,
                              displayName: displayName.valueOrNull ?? userId,
                              avatar: avatarProv.valueOrNull,
                              size: avatarProv.valueOrNull != null ? 14 : 28,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              displayName.valueOrNull ?? userId,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(width: 10),
                            InkWell(
                              onTap: () => ref
                                  .read(_selectedUsersProvider.notifier)
                                  .update(
                                    (state) => [
                                      for (int j = 0; j < state.length; j++)
                                        if (j != index) state[j],
                                    ],
                                  ),
                              child: Icon(
                                Icons.close_outlined,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            onTap: selectedUsers.isEmpty
                ? () => widget.controller.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.ease,
                    )
                : () async {
                    if (selectedUsers.length > 1) {
                      final convo = await widget.onCreateConvo('', '');
                      if (context.mounted && convo != null) {
                        Navigator.of(context).pop();
                        context.pushNamed(
                          Routes.chatroom.name,
                          pathParameters: {'roomId': convo.getRoomIdStr()},
                        );
                      }
                    } else {
                      String? id = checkUserDMExists(
                        selectedUsers[0].userId().toString(),
                        ref,
                      );
                      if (id != null) {
                        Navigator.of(context).pop();
                        context.pushNamed(
                          Routes.chatroom.name,
                          pathParameters: {'roomId': id},
                        );
                      } else {
                        final convo = await widget.onCreateConvo('', '');
                        if (context.mounted && convo != null) {
                          Navigator.of(context).pop();
                          context.pushNamed(
                            Routes.chatroom.name,
                            pathParameters: {'roomId': convo.getRoomIdStr()},
                          );
                        }
                      }
                    }
                  },
            contentPadding: const EdgeInsets.only(left: 0),
            leading: selectedUsers.isEmpty
                ? ActerAvatar(
                    uniqueId: '#',
                    mode: DisplayMode.Space,
                    size: 48,
                  )
                : selectedUsers.length > 1
                    ? CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.neutral4,
                        radius: 28,
                        child: Icon(
                          Atlas.team_group,
                          color: Theme.of(context).colorScheme.neutral,
                        ),
                      )
                    : ActerAvatar(
                        uniqueId: selectedUsers[0].userId().toString(),
                        mode: DisplayMode.User,
                        displayName: ref
                            .watch(displayNameProvider(selectedUsers[0]))
                            .valueOrNull,
                        avatar: ref
                            .watch(userAvatarProvider(selectedUsers[0]))
                            .valueOrNull,
                        size: ref
                                    .watch(
                                      userAvatarProvider(selectedUsers[0]),
                                    )
                                    .valueOrNull !=
                                null
                            ? 20
                            : 40,
                      ),
            title: Text(
              tileTitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: const Icon(Icons.chevron_right_outlined, size: 24),
          ),
          const SizedBox(height: 15),
          Visibility(
            visible: searchCtrl.text.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found Users',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                foundUsers.when(
                  data: (data) => data.isEmpty
                      ? Center(
                          heightFactor: 10,
                          child: Text(
                            'No Users found with specified search term',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: data.length,
                          itemBuilder: (context, index) => _UserWidget(
                            profile: data[index],
                            onUp: _onUp,
                          ),
                        ),
                  error: (e, st) => Text('Error loading users $e'),
                  loading: () => const Center(
                    heightFactor: 5,
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _makeTitle(WidgetRef ref) {
    final selectedUsers = ref.watch(_selectedUsersProvider).toList();
    if (selectedUsers.isEmpty) {
      return 'Create Group Chat';
    } else if (selectedUsers.length > 1) {
      return 'Start Group DM';
    } else {
      if (checkUserDMExists(selectedUsers[0].userId().toString(), ref) !=
          null) {
        return 'Go to DM';
      } else {
        return 'Start DM';
      }
    }
  }

// checks whether user DM already exists or needs created
  String? checkUserDMExists(String userId, WidgetRef ref) {
    final client = ref.watch(clientProvider);
    if (client == null) throw 'Client not available';
    final id = client.dmWithUser(userId).text();
    if (id != null) return id;
    return null;
  }
}

class _CreateRoomFormWidget extends ConsumerStatefulWidget {
  final String? initialSelectedSpaceId;
  final PageController controller;
  final Future<ffi.Convo?> Function(String, String) onCreateConvo;
  const _CreateRoomFormWidget({
    required this.controller,
    required this.onCreateConvo,
    this.initialSelectedSpaceId,
  });

  @override
  ConsumerState<_CreateRoomFormWidget> createState() =>
      _CreateRoomFormWidgetConsumerState();
}

class _CreateRoomFormWidgetConsumerState
    extends ConsumerState<_CreateRoomFormWidget> {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Visibility(
                visible: widget.controller.initialPage == 0,
                child: InkWell(
                  onTap: () => widget.controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  ),
                  child: const Icon(Icons.chevron_left),
                ),
              ),
              const Spacer(),
              Text(
                'Create Group Chat',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text('Name'),
                    ),
                    InputTextField(
                      hintText: 'What to call this chat?',
                      textInputType: TextInputType.multiline,
                      controller: _titleController,
                      onInputChanged: _handleTitleChange,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: Text('About'),
          ),
          InputTextField(
            controller: _descriptionController,
            hintText: 'Description',
            textInputType: TextInputType.multiline,
            maxLines: 10,
          ),
          const SizedBox(height: 15),
          const SelectSpaceFormField(
            canCheck: 'CanLinkSpaces',
            mandatory: true,
            title: 'Parent space',
            emptyText: 'optional parent space',
            selectTitle: 'Select parent space',
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              DefaultButton(
                onPressed: () => Navigator.of(context).pop(),
                title: 'Cancel',
                isOutlined: true,
              ),
              const SizedBox(width: 10),
              DefaultButton(
                onPressed: titleInput.trim().isEmpty
                    ? null
                    : () async {
                        if (isSpaceRoom && currentParentSpace == null) {
                          EasyLoading.showError(
                            'Parent Space must be selected',
                            duration: const Duration(seconds: 2),
                          );
                          return;
                        }
                        final convo = await widget.onCreateConvo(
                          titleInput,
                          _descriptionController.text.trim(),
                        );
                        if (context.mounted && convo != null) {
                          Navigator.pop(context);
                          context.pushNamed(
                            Routes.chatroom.name,
                            pathParameters: {'roomId': convo.getRoomIdStr()},
                          );
                        }
                      },
                title: 'Create',
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.success,
                  disabledBackgroundColor:
                      Theme.of(context).colorScheme.success.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
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
}

// Searched User tile UI widget
class _UserWidget extends ConsumerWidget {
  final ffi.UserProfile profile;
  final void Function() onUp;
  const _UserWidget({required this.profile, required this.onUp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarProv = ref.watch(userAvatarProvider(profile));
    final displayName = ref.watch(displayNameProvider(profile));
    final userId = profile.userId().toString();
    return ListTile(
      onTap: () {
        final users = ref.read(_selectedUsersProvider);
        if (!users.contains(profile)) {
          ref
              .read(_selectedUsersProvider.notifier)
              .update((state) => [...state, profile]);
        }
        onUp();
      },
      title: displayName.when(
        data: (data) => Text(
          data ?? userId,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        error: (err, stackTrace) => Text('Error: $err'),
        loading: () => const Text('Loading display name'),
      ),
      subtitle: displayName.when(
        data: (data) {
          return (data == null)
              ? null
              : Text(
                  userId,
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                        color: Theme.of(context).colorScheme.neutral5,
                      ),
                );
        },
        error: (err, stackTrace) => Text('Error: $err'),
        loading: () => const Text('Loading display name'),
      ),
      leading: ActerAvatar(
        uniqueId: userId,
        mode: DisplayMode.User,
        uniqueName: displayName.valueOrNull,
        displayName: displayName.valueOrNull,
        avatar: avatarProv.valueOrNull,
        size: avatarProv.valueOrNull != null ? 18 : 36,
      ),
    );
  }
}
