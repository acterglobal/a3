import 'dart:io';

import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/chat/actions/create_chat.dart';
import 'package:acter/features/chat/providers/create_chat_providers.dart';
import 'package:acter/features/files/actions/pick_avatar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/member/providers/invite_providers.dart';
import 'package:acter/features/member/widgets/user_builder.dart';
import 'package:acter/features/member/widgets/user_search_results.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' as ffi;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat::create_chat');

/// Room title
final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
// upload avatar path
final _avatarProvider = StateProvider.autoDispose<String>((ref) => '');

class CreateChatPage extends ConsumerStatefulWidget {
  static const chatTitleKey = Key('create-chat-title');
  static const submiteKey = Key('create-chat-submit');

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
    return context.isLargeScreen
        ? Container(
            width: size.width * 0.5,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: PageView.builder(
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => currIdx = index);
                },
                controller: controller,
                itemBuilder: ((context, index) => pages[currIdx]),
              ),
            ),
          );
  }

  /// Create Room Method
  Future<ffi.Convo?> _handleCreateConvo(
    String? convoName,
    String? description,
    List<String> selectedUsers,
  ) async {
    final roomCreated = L10n.of(context).chatRoomCreated;
    final roomIdStr = await createChat(
      context,
      ref,
      name: convoName,
      selectedUsers: selectedUsers,
      parentId: ref.read(selectedSpaceIdProvider),
      description: description,
      avatarUri: ref.read(_avatarProvider),
    );
    if (roomIdStr != null) {
      try {
        final convo = await (await ref.read(alwaysClientProvider.future))
            .convoWithRetry(roomIdStr, 120);
        EasyLoading.showToast(roomCreated);
        return convo;
      } catch (e, s) {
        _log.severe('Room $roomIdStr created but fetching failed', e, s);
      }
    }
    return null;
  }
}

///
class _CreateChatWidget extends ConsumerStatefulWidget {
  final PageController controller;
  final Future<ffi.Convo?> Function(String?, String?, List<String>)
      onCreateConvo;

  const _CreateChatWidget({
    required this.controller,
    required this.onCreateConvo,
  });

  @override
  ConsumerState<_CreateChatWidget> createState() =>
      _CreateChatWidgetConsumerState();
}

class _CreateChatWidgetConsumerState extends ConsumerState<_CreateChatWidget> {
  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.newChat),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 15),
          ActerSearchWidget(
            initialText: ref.read(userSearchValueProvider),
            hintText: lang.searchUsernameToStartDM,
            onChanged: (value) {
              ref
                  .read(userSearchValueProvider.notifier)
                  .update((state) => value);
            },
            onClear: () {
              ref.read(userSearchValueProvider.notifier).state = null;
            },
          ),
          const SizedBox(height: 15),
          renderSelectedUsers(context),
          renderPrimaryAction(context),
          const SizedBox(height: 15),
          Expanded(
            child: renderFoundUsers(context),
          ),
        ],
      ),
    );
  }

  String _makeTitle(WidgetRef ref) {
    final lang = L10n.of(context);
    final selectedUsers = ref.watch(createChatSelectedUsersProvider);
    if (selectedUsers.isEmpty) {
      return lang.createGroupChat;
    } else if (selectedUsers.length > 1) {
      return lang.startGroupDM;
    } else {
      final otherUserId = selectedUsers[0].userId().toString();
      final client = ref.watch(alwaysClientProvider).valueOrNull;
      if (checkUserDMExists(otherUserId, client) != null) {
        return lang.goToDM;
      } else {
        return lang.startDM;
      }
    }
  }

  // checks whether user DM already exists or needs created
  String? checkUserDMExists(String userId, ffi.Client? client) {
    return client?.dmWithUser(userId).text();
  }

  Widget renderSelectedUsers(BuildContext context) {
    final selectedUsers = ref.watch(createChatSelectedUsersProvider).toList();
    if (selectedUsers.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        direction: Axis.horizontal,
        spacing: 5.0,
        runSpacing: 5.0,
        children: List.generate(selectedUsers.length, (index) {
          final profile = selectedUsers[index];
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: colorScheme.onSurface),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final avatarProv = ref.watch(userAvatarProvider(profile));
                final displayName = profile.displayName();
                final userId = profile.userId().toString();
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ActerAvatar(
                      options: AvatarOptions.DM(
                        AvatarInfo(
                          uniqueId: userId,
                          displayName: displayName ?? userId,
                          avatar: avatarProv.valueOrNull,
                        ),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      displayName ?? userId,
                      style: textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => onUserRemove(index),
                      child: Icon(
                        Icons.close_outlined,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget renderPrimaryAction(BuildContext context) {
    final selectedUsers = ref.watch(createChatSelectedUsersProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        onTap: selectedUsers.isEmpty
            ? () => widget.controller.animateToPage(
                  1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                )
            : () => onPrimaryAction(selectedUsers),
        contentPadding: EdgeInsets.zero,
        leading: selectedUsers.isEmpty
            ? ActerAvatar(
                options: const AvatarOptions(
                  AvatarInfo(
                    uniqueId: '#',
                    tooltip: TooltipStyle.None,
                  ),
                  size: 48,
                ),
              )
            : selectedUsers.length > 1
                ? CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    radius: 28,
                    child: const Icon(Atlas.team_group),
                  )
                : renderSingleAvatar(selectedUsers[0]),
        title: Text(
          _makeTitle(ref),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: const Icon(
          Icons.chevron_right_outlined,
          size: 24,
        ),
      ),
    );
  }

  Widget renderSingleAvatar(ffi.UserProfile profile) {
    final avatar = ref.watch(userAvatarProvider(profile)).valueOrNull;
    return ActerAvatar(
      options: AvatarOptions.DM(
        AvatarInfo(
          uniqueId: profile.userId().toString(),
          displayName: profile.displayName(),
          avatar: avatar,
        ),
        size: 20,
      ),
    );
  }

  Widget renderFoundUsers(BuildContext context) {
    return UserSearchResults(
      userItemBuilder: ({required isSuggestion, required profile}) {
        return UserBuilder(
          userId: profile.userId().toString(),
          userProfile: profile,
          onTap: () {
            final users = ref.read(createChatSelectedUsersProvider);
            if (!users.contains(profile)) {
              final notifier =
                  ref.read(createChatSelectedUsersProvider.notifier);
              notifier.update((state) => [...state, profile]);
            }
          },
          includeSharedRooms: isSuggestion,
          includeUserJoinState: false,
        );
      },
    );
  }

  void onUserRemove(int index) {
    ref.read(createChatSelectedUsersProvider.notifier).update((state) {
      final result = List<ffi.UserProfile>.from(state);
      result.removeAt(index);
      return result;
    });
  }

  Future<void> onPrimaryAction(List<ffi.UserProfile> selectedUsers) async {
    if (selectedUsers.isEmpty) return;
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.creatingChat);
    try {
      if (selectedUsers.length > 1) {
        final userIds =
            selectedUsers.map((u) => u.userId().toString()).toList();
        final convo = await widget.onCreateConvo(null, null, userIds);
        EasyLoading.dismiss();
        if (!mounted) return;
        Navigator.pop(context);
        if (convo == null) return;
        context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {'roomId': convo.getRoomIdStr()},
        );
        return;
      }

      final otherUserId = selectedUsers[0].userId().toString();
      final client = ref.read(alwaysClientProvider).valueOrNull;
      String? roomId = checkUserDMExists(otherUserId, client);
      if (roomId != null) {
        EasyLoading.dismiss();
        Navigator.pop(context);
        context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {'roomId': roomId},
        );
        return;
      }

      final convo = await widget.onCreateConvo(null, null, [otherUserId]);
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.pop(context);
      if (convo == null) return;
      context.pushNamed(
        Routes.chatroom.name,
        pathParameters: {'roomId': convo.getRoomIdStr()},
      );
    } catch (e, s) {
      _log.severe('Couldn’t create chat', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToCreateChat(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}

class _CreateRoomFormWidget extends ConsumerStatefulWidget {
  final String? initialSelectedSpaceId;
  final PageController controller;
  final Future<ffi.Convo?> Function(String?, String?, List<String>)
      onCreateConvo;

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
    widget.initialSelectedSpaceId.map((p0) {
      isSpaceRoom = true;
      WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
        final notifier = ref.read(selectedSpaceIdProvider.notifier);
        notifier.state = p0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    final avatarUpload = ref.watch(_avatarProvider);
    final currentParentSpace = ref.watch(selectedSpaceIdProvider);
    final lang = L10n.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 18,
      ),
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
                lang.createGroupChat,
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
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(lang.avatar),
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
                          : const Icon(Atlas.up_arrow_from_bracket_thin),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(lang.name),
                    ),
                    InputTextField(
                      key: CreateChatPage.chatTitleKey,
                      hintText: lang.whatToCallThisChat,
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
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(lang.about),
          ),
          InputTextField(
            controller: _descriptionController,
            hintText: lang.description,
            textInputType: TextInputType.multiline,
            maxLines: 10,
          ),
          const SizedBox(height: 15),
          SelectSpaceFormField(
            canCheck: 'CanLinkSpaces',
            mandatory: true,
            title: lang.parentSpace,
            emptyText: lang.optionalParentSpace,
            selectTitle: lang.selectParentSpace,
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.cancel),
              ),
              const SizedBox(width: 10),
              ActerPrimaryActionButton(
                key: CreateChatPage.submiteKey,
                onPressed: () => _handleSubmit(titleInput, currentParentSpace),
                child: Text(lang.create),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleTitleChange(String? value) {
    value.map((val) {
      ref.read(_titleProvider.notifier).update((state) => val);
    });
  }

  Future<void> _handleAvatarUpload() async {
    FilePickerResult? result = await pickAvatar(context: context);
    if (result != null) {
      final filePath = result.files.single.path;
      if (filePath == null) {
        _log.severe('FilePickerResult had an empty path', result);
        return;
      }
      ref.read(_avatarProvider.notifier).update((state) => filePath);
    } else {
      // user cancelled the picker
    }
  }

  Future<void> _handleSubmit(
    String titleInput,
    String? currentParentSpace,
  ) async {
    String title = titleInput.trim();
    if (title.isEmpty) return;
    final lang = L10n.of(context);
    if (isSpaceRoom && currentParentSpace == null) {
      EasyLoading.showError(
        lang.parentSpaceMustBeSelected,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    EasyLoading.show(status: lang.creatingChat);
    try {
      final description = _descriptionController.text.trim();
      final convo = await widget.onCreateConvo(title, description, []);
      EasyLoading.dismiss();
      if (mounted && convo != null) {
        Navigator.pop(context);
        context.pushNamed(
          Routes.chatroom.name,
          pathParameters: {'roomId': convo.getRoomIdStr()},
        );
      }
    } catch (e, s) {
      _log.severe('Couldn’t create chat', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.failedToCreateChat(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
