import 'dart:io';

import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/sliver_scaffold.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/spaces/model/keys.dart';
import 'package:acter/router/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

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
    return SliverScaffold(
      header: parentSelected
          ? L10n.of(context).createSubspace
          : L10n.of(context).createSpace,
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 15),
            Row(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(L10n.of(context).avatar),
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
                        key: CreateSpaceKeys.titleField,
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
                  controller: _descriptionController,
                  hintText: L10n.of(context).description,
                  textInputType: TextInputType.multiline,
                  maxLines: 10,
                ),
                SelectSpaceFormField(
                  canCheck: 'CanLinkSpaces',
                  mandatory: false,
                  title: L10n.of(context).parentSpace,
                  selectTitle: L10n.of(context).selectParentSpace,
                ),
              ],
            ),
          ],
        ),
      ),
      confirmActionTitle: L10n.of(context).createSpace,
      confirmActionKey: CreateSpaceKeys.submitBtn,
      cancelActionTitle: L10n.of(context).cancel,
      confirmActionOnPressed: titleInput.trim().isEmpty
          ? null
          : () {
              _handleCreateSpace(
                context,
                titleInput,
                _descriptionController.text.trim(),
              );
            },
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
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
      dialogTitle: L10n.of(context).uploadAvatar,
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
    EasyLoading.show(status: L10n.of(context).creatingSpace);
    try {
      final sdk = await ref.read(sdkProvider.future);
      final config = sdk.api.newSpaceSettingsBuilder();
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
      final client = ref.read(alwaysClientProvider);
      final roomId = await client.createActerSpace(config.build());
      if (parentRoomId != null) {
        final space = await ref.read(spaceProvider(parentRoomId).future);
        await space.addChildRoom(roomId.toString());
        // spaceRelations come from the server and must be manually invalidated
        ref.invalidate(spaceRelationsOverviewProvider(parentRoomId));
      }

      EasyLoading.dismiss();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // pop the create sheet
      goToSpace(context, roomId.toString());
    } catch (err) {
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        L10n.of(context).creatingSpaceFailed(err),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
