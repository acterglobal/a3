import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/files/actions/pick_avatar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::avatar_upload');

Future<void> openAvatar(
  BuildContext context,
  WidgetRef ref,
  String roomId,
) async {
  final membership = await ref.read(roomMembershipProvider(roomId).future);
  final canUpdateAvatar = membership?.canString('CanUpdateAvatar') == true;
  final avatarInfo = ref.read(roomAvatarInfoProvider(roomId));

  if (avatarInfo.avatar != null && context.mounted) {
    //Open avatar in full screen if avatar data available
    context.pushNamed(
      Routes.fullScreenAvatar.name,
      queryParameters: {'roomId': roomId},
    );
  } else if (avatarInfo.avatar == null && canUpdateAvatar && context.mounted) {
    //Change avatar if avatar is null and have relevant permission
    uploadAvatar(ref, context, roomId);
  }
}

Future<void> uploadAvatar(
  WidgetRef ref,
  BuildContext context,
  String roomId,
) async {
  final lang = L10n.of(context);
  final room = await ref.read(maybeRoomProvider(roomId).future);
  if (room == null || !context.mounted) return;
  FilePickerResult? result = await pickAvatar(context: context);
  if (result == null || result.files.isEmpty) return;
  if (!context.mounted) return;
  try {
    EasyLoading.show(status: lang.avatarUploading);
    final filePath = result.files.first.path;
    if (filePath == null) {
      _log.severe('FilePickerResult had an empty path', result);
      return;
    }
    await room.uploadAvatar(filePath);
    // close loading
    EasyLoading.dismiss();
  } catch (e, s) {
    _log.severe('Failed to upload avatar', e, s);
    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showError(
      lang.failedToUploadAvatar(e),
      duration: const Duration(seconds: 3),
    );
  }
}
