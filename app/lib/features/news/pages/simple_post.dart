import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';
import 'package:image_picker/image_picker.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:typed_data';

final selectedSpaceIdProvider = StateProvider<String?>((ref) => null);
final selectedSpaceDetailsProvider =
    FutureProvider.autoDispose<SpaceItem?>((ref) async {
  final selectedSpaceId = ref.watch(selectedSpaceIdProvider);
  if (selectedSpaceId == null) {
    return null;
  }

  final spaces = await ref.watch(briefSpaceItemsProviderWithMembership.future);
  return spaces.firstWhere((element) => element.roomId == selectedSpaceId);
});

// upload avatar path
final selectedImageProvider = StateProvider<XFile?>((ref) => null);
final textProvider = StateProvider.autoDispose<String>((ref) => '');
final linkProvider = StateProvider.autoDispose<String>((ref) => '');

class SimpleNewsPost extends ConsumerStatefulWidget {
  const SimpleNewsPost({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SimpleNewsPostState();
}

class _SimpleNewsPostState extends ConsumerState<SimpleNewsPost> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final currentSelectedSpace = ref.watch(selectedSpaceIdProvider);
    final _selectedSpace = currentSelectedSpace != null;
    return SideSheet(
      header: 'Create new Update',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Consumer(
                  builder: (context, ref, child) {
                    final selectedImage = ref.watch(selectedImageProvider);
                    if (selectedImage != null) {
                      return SizedBox(
                        height: 300,
                        child: InkWell(
                          onTap: () async {
                            ref.read(selectedImageProvider.notifier).state =
                                null;
                          },
                          child: Center(
                            child: Image(
                              image: XFileImage(selectedImage),
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 300,
                      child: InkWell(
                        onTap: () async {
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          ref.read(selectedImageProvider.notifier).state =
                              image;
                        },
                        child: const Center(
                          child: Text('select an image (optional)'),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                child: TextFormField(
                  decoration: InputDecoration(
                    hintText:
                        (ref.read(selectedImageProvider.notifier).state == null)
                            ? 'The update you want to share'
                            : 'Text caption',
                    labelText:
                        ref.read(selectedImageProvider.notifier).state == null
                            ? 'Text Update'
                            : 'Image Caption',
                  ),
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: (value) => (value != null && value.isNotEmpty) ||
                          ref.read(selectedImageProvider.notifier).state != null
                      ? null
                      : 'Please enter a text or add an image',
                  onChanged: (String? value) {
                    ref.read(textProvider.notifier).state = value ?? '';
                  },
                ),
              ),
              FormField(
                builder: (state) => ListTile(
                  title: Text(
                    _selectedSpace ? 'Space' : 'Please select a space',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  subtitle: state.errorText != null
                      ? Text(
                          state.errorText!,
                          style:
                              Theme.of(context).textTheme.bodySmall!.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        )
                      : null,
                  trailing: _selectedSpace
                      ? Consumer(
                          builder: (context, ref, child) =>
                              ref.watch(selectedSpaceDetailsProvider).when(
                                    data: (space) => space != null
                                        ? SpaceChip(space: space)
                                        : Text(currentSelectedSpace),
                                    error: (e, s) => Text('error: $e'),
                                    loading: () => const Text('loading'),
                                  ),
                        )
                      : null,
                  onTap: () async {
                    final currentSpaceId = ref.read(selectedSpaceIdProvider);
                    final newSelectedSpaceId = await selectSpaceDrawer(
                      context: context,
                      currentSpaceId: currentSpaceId,
                      title: const Text('Select space'),
                    );
                    ref.read(selectedSpaceIdProvider.notifier).state =
                        newSelectedSpaceId;
                  },
                ),
                validator: (x) => (ref.read(selectedSpaceIdProvider) != null)
                    ? null
                    : 'You must select a space',
              ),
            ],
          ),
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
            if (_formKey.currentState!.validate()) {
              final spaceId = ref.read(selectedSpaceIdProvider);
              final file = ref.read(selectedImageProvider);
              final caption = ref.read(textProvider);
              late String displayMsg;

              if (file == null) {
                displayMsg = 'Posting image update to $spaceId';
              } else {
                displayMsg = 'Posting text update to $spaceId';
              }

              popUpDialog(
                context: context,
                title: Text(
                  displayMsg,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                isLoader: true,
              );

              final space = await ref.watch(spaceProvider(spaceId!).future);
              NewsEntryDraft draft = space.newsDraft();
              if (file == null) {
                draft.addTextSlide(caption);
              } else {
                String? mimeType = file.mimeType ?? lookupMimeType(file.path);

                if (mimeType != null) {
                  if (mimeType.startsWith('image/')) {
                    Uint8List bytes = await file.readAsBytes();
                    var decodedImage = await decodeImageFromList(bytes);
                    EventId eventId = await space.sendImageMessage(
                      file.path,
                      file.name,
                      mimeType,
                      bytes.length,
                      decodedImage.width,
                      decodedImage.height,
                      null,
                    );
                    draft.addImageSlide(
                      caption,
                      eventId.toString(),
                      mimeType,
                      bytes.length,
                      decodedImage.width,
                      decodedImage.height,
                      null,
                    );
                  } else {
                    customMsgSnackbar(
                      context,
                      'Posting of $mimeType not yet supported',
                    );
                    return;
                  }
                } else {
                  customMsgSnackbar(
                    context,
                    'Detecting mimetype failed. not supported.',
                  );
                  return;
                }
              }

              try {
                await draft.send();
                // close both
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context, rootNavigator: true).pop();
              } catch (err) {
                Navigator.of(context, rootNavigator: true).pop();
                popUpDialog(
                  context: context,
                  title: Text(
                    '$displayMsg failed: \n $err"',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  isLoader: false,
                  btnText: 'Close',
                  onPressedBtn: () {
                    Navigator.of(context, rootNavigator: true).pop();
                  },
                );
              }
            }
          },
          child: const Text('Post Update'),
          style: ElevatedButton.styleFrom(
            // backgroundColor: _titleInput.isNotEmpty
            //     ? Theme.of(context).colorScheme.success
            //     : Theme.of(context).colorScheme.success.withOpacity(0.6),
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
}
