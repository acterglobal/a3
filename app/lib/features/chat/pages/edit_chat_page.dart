import 'dart:async';
import 'dart:io';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/base_body_widget.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

final _log = Logger('a3::chat::edit_profile_page');

class EditChatPage extends ConsumerStatefulWidget {
  final String roomId;

  const EditChatPage({
    required this.roomId,
    super.key,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditChatPage> {
  final ValueNotifier<File?> selectedUserAvatar = ValueNotifier(null);
  final chatNameController = TextEditingController();
  final chatDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setChatData();
  }

  Future<void> _setChatData() async {
    final profileData =
        await ref.read(chatProfileDataProviderById(widget.roomId).future);
    final convoData = await ref.read(chatProvider(widget.roomId).future);
    if (profileData.hasAvatar()) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      final dirPath = p.join(appDocDir.path, 'dir');
      await Directory(dirPath).create(recursive: true);
      String filePath = p.join(appDocDir.path, '${widget.roomId}.jpg');
      final imageFile = File(filePath);
      imageFile.writeAsBytes(profileData.avatar!.asTypedList());
      selectedUserAvatar.value = imageFile;
    }
    chatNameController.text = profileData.displayName ?? '';
    chatDescriptionController.text = convoData.topic() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BaseBody(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.0,
      title: Text(
        L10n.of(context).edit,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              const SizedBox(height: 40),
              _buildAvatarUI(),
              const SizedBox(height: 40),
              _chatName(),
              const SizedBox(height: 20),
              _chatDescription(),
              const SizedBox(height: 30),
              _saveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> pickAvtar() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: L10n.of(context).uploadAvatar,
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      selectedUserAvatar.value = File(result.files.first.path!);
    }
  }

  Widget _buildAvatarUI() {
    return ValueListenableBuilder(
      valueListenable: selectedUserAvatar,
      builder: (context, userAvatar, child) {
        return GestureDetector(
          onTap: () => pickAvtar(),
          child: Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
              image: userAvatar != null
                  ? DecorationImage(
                      image: FileImage(userAvatar),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(5),
            ),
            child: userAvatar == null
                ? Icon(
                    Atlas.up_arrow_from_bracket_thin,
                    color: Theme.of(context).colorScheme.neutral4,
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _chatName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(L10n.of(context).chatName),
        ),
        InputTextField(
          hintText: L10n.of(context).typeName,
          textInputType: TextInputType.multiline,
          controller: chatNameController,
        ),
        const SizedBox(height: 3),
        Text(
          L10n.of(context).egGlobalMovement,
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: Theme.of(context).colorScheme.neutral4,
              ),
        ),
      ],
    );
  }

  Widget _chatDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Text(L10n.of(context).about),
        ),
        InputTextField(
          hintText: L10n.of(context).description,
          textInputType: TextInputType.multiline,
          controller: chatDescriptionController,
          maxLines: 10,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (chatNameController.text.trim().isEmpty) return;
    final convo = await ref.read(chatProvider(widget.roomId).future);
    if (!mounted) return;
    EasyLoading.show(status: L10n.of(context).updatingChat);
    try {
      // await convo.setName(chatNameController.text.trim());
      await convo.setTopic(chatDescriptionController.text.trim());
      if (selectedUserAvatar.value != null) {
        await convo.uploadAvatar(selectedUserAvatar.value!.path);
      }
      EasyLoading.dismiss();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      _log.severe('Failed to edit chat', e, st);
      EasyLoading.dismiss();
    }
  }

  Widget _saveButton() {
    return ActerPrimaryActionButton(
      onPressed: _save,
      child: Text(L10n.of(context).saveChanges),
    );
  }
}
