import 'dart:io';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/attachments/actions/attach_ref_details.dart';
import 'package:acter/common/widgets/share/widgets/attach_options.dart';
import 'package:acter/common/widgets/share/widgets/external_share_options.dart';
import 'package:acter/common/widgets/share/widgets/file_share_options.dart';
import 'package:acter/features/deep_linking/actions/show_qr_code.dart';
import 'package:acter/features/deep_linking/types.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/files/actions/download_file.dart';
import 'package:acter/features/news/model/news_references_model.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

typedef SpaceObjectDetails = ({
  String spaceId,
  ObjectType objectType,
  String objectId,
});

typedef FileDetails = ({
  File file,
  String? mimeType,
});

Future<void> openShareSpaceObjectDialog({
  required BuildContext context,
  SpaceObjectDetails? spaceObjectDetails,
  FileDetails? fileDetails,
}) async {
  await showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => ShareSpaceObjectActionUI(
      spaceObjectDetails: spaceObjectDetails,
      fileDetails: fileDetails,
    ),
  );
}

class ShareSpaceObjectActionUI extends ConsumerWidget {
  final SpaceObjectDetails? spaceObjectDetails;
  final FileDetails? fileDetails;

  const ShareSpaceObjectActionUI({
    super.key,
    this.spaceObjectDetails,
    this.fileDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (spaceObjectDetails != null) ...[
              attachmentOptionsUI(context, ref, spaceObjectDetails!),
              SizedBox(height: 16),
              externalShareOptionsUI(context, spaceObjectDetails!),
              SizedBox(height: 20),
            ],
            if (fileDetails != null) fileShareOptionsUI(context, fileDetails!),
          ],
        ),
      ),
    );
  }

  Widget attachmentOptionsUI(
    BuildContext context,
    WidgetRef ref,
    SpaceObjectDetails spaceObjectDetails,
  ) {
    String spaceId = spaceObjectDetails.spaceId;
    ObjectType objectType = spaceObjectDetails.objectType;
    String objectId = spaceObjectDetails.objectId;

    final newsRefType = getNewsRefTypeFromObjType(objectType);
    return AttachOptions(
      onTapBoost: () {
        Navigator.pop(context);
        context.pushNamed(
          Routes.actionAddUpdate.name,
          queryParameters: {'spaceId': spaceId},
          extra: newsRefType != null
              ? NewsReferencesModel(type: newsRefType, id: objectId)
              : null,
        );
      },
      onTapPin: () async {
        final refDetails = await getRefDetails(
          ref: ref,
          objectDetails: spaceObjectDetails,
        );
        if (refDetails != null && context.mounted) {
          await attachRefDetailToPin(
            context: context,
            ref: ref,
            refDetails: refDetails,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      },
      onTapEvent: () async {
        final refDetails = await getRefDetails(
          ref: ref,
          objectDetails: spaceObjectDetails,
        );
        if (refDetails != null && context.mounted) {
          await attachRefDetailToEvent(
            context: context,
            ref: ref,
            refDetails: refDetails,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      },
      onTapTaskList: () async {
        final refDetails = await getRefDetails(
          ref: ref,
          objectDetails: spaceObjectDetails,
        );
        if (refDetails != null && context.mounted) {
          await attachRefDetailToTaskList(
            context: context,
            ref: ref,
            refDetails: refDetails,
          );
          if (!context.mounted) return;
          Navigator.pop(context);
        }
      },
    );
  }

  Widget externalShareOptionsUI(
    BuildContext context,
    SpaceObjectDetails spaceObjectDetails,
  ) {
    String spaceId = spaceObjectDetails.spaceId;
    ObjectType objectType = spaceObjectDetails.objectType;
    String objectId = spaceObjectDetails.objectId;

    final internalLink =
        'acter:o/${spaceId.substring(1)}/${objectType.name}/${objectId.substring(1)}';

    return ExternalShareOptions(
      onTapQr: () {
        Navigator.pop(context);
        showQrCode(
          context,
          internalLink,
        );
      },
    );
  }

  Widget fileShareOptionsUI(
    BuildContext context,
    FileDetails fileDetails,
  ) {
    File file = fileDetails.file;
    String? mimeType = fileDetails.mimeType;
    return FileShareOptions(
      onTapOpen: () async {
        final result = await OpenFilex.open(file.absolute.path);
        if (result.type == ResultType.done) {
          // done, close this dialog
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      onTapSave: !Platform.isAndroid
          ? () async {
              if (await downloadFile(context, file)) {
                // done, close this dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            }
          : null,
      onTapShare: () async {
        final result = await Share.shareXFiles(
          [XFile(file.path, mimeType: mimeType)],
        );
        if (result.status == ShareResultStatus.success) {
          // done, close this dialog
          if (context.mounted) {
            Navigator.pop(context);
          }
        }
      },
    );
  }

  NewsReferencesType? getNewsRefTypeFromObjType(ObjectType objectType) {
    return switch (objectType) {
      ObjectType.pin => NewsReferencesType.pin,
      ObjectType.calendarEvent => NewsReferencesType.calendarEvent,
      ObjectType.taskList => NewsReferencesType.taskList,
      _ => null,
    };
  }

  Future<RefDetails?> getRefDetails({
    required WidgetRef ref,
    required SpaceObjectDetails objectDetails,
  }) async {
    final objectId = objectDetails.objectId;
    switch (objectDetails.objectType) {
      case ObjectType.pin:
        final sourcePin = await ref.watch(pinProvider(objectId).future);
        return await sourcePin.refDetails();
      case ObjectType.calendarEvent:
        final sourceEvent =
            await ref.watch(calendarEventProvider(objectId).future);
        return await sourceEvent.refDetails();
      case ObjectType.taskList:
        final sourceTaskList = await ref.watch(taskListProvider(objectId).future);
        return await sourceTaskList.refDetails();
      default:
        return null;
    }
  }
}
