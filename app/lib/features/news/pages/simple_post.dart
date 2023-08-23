import 'dart:typed_data';

import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

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
final textProvider = StateProvider<String>((ref) => '');

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
    final spaceNotifier = ref.watch(selectedSpaceIdProvider.notifier);
    final selectedSpace = currentSelectedSpace != null;
    final imageNotifier = ref.watch(selectedImageProvider.notifier);
    final captionNotifier = ref.watch(textProvider.notifier);
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
                child: Consumer(builder: imageBuilder),
              ),
              Expanded(
                child: TextFormField(
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    hintText: imageNotifier.state == null
                        ? 'The update you want to share'
                        : 'Text caption',
                    labelText: imageNotifier.state == null
                        ? 'Text Update'
                        : 'Image Caption',
                  ),
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return null;
                    }
                    if (imageNotifier.state != null) {
                      return null;
                    }
                    return 'Please enter a text or add an image';
                  },
                  onChanged: (String? value) {
                    captionNotifier.state = value ?? '';
                  },
                ),
              ),
              FormField(
                builder: (state) => ListTile(
                  title: Text(
                    selectedSpace ? 'Space' : 'Please select a space',
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
                  trailing: selectedSpace
                      ? _SpaceBuilder(
                          currentSelectedSpace: currentSelectedSpace,
                        )
                      : null,
                  onTap: () async {
                    final newSelectedSpaceId = await selectSpaceDrawer(
                      context: context,
                      currentSpaceId: ref.read(selectedSpaceIdProvider),
                      canCheck: 'CanPostNews',
                      title: const Text('Select space'),
                    );
                    spaceNotifier.state = newSelectedSpaceId;
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
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Cancel'),
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

              final space = await ref.read(spaceProvider(spaceId!).future);
              NewsEntryDraft draft = space.newsDraft();
              if (file == null) {
                draft.addTextSlide(caption);
              } else {
                String? mimeType = file.mimeType ?? lookupMimeType(file.path);

                if (mimeType != null) {
                  if (mimeType.startsWith('image/')) {
                    Uint8List bytes = await file.readAsBytes();
                    final decodedImage = await decodeImageFromList(bytes);
                    await draft.addImageSlide(
                      caption,
                      file.path,
                      mimeType,
                      bytes.length,
                      decodedImage.width,
                      decodedImage.height,
                      null,
                    );
                  } else {
                    // We are doing as expected, but the lints triggers.
                    // ignore: use_build_context_synchronously
                    if (!context.mounted) {
                      return;
                    }
                    customMsgSnackbar(
                      context,
                      'Posting of $mimeType not yet supported',
                    );
                    return;
                  }
                } else {
                  // We are doing as expected, but the lints triggers.
                  // ignore: use_build_context_synchronously
                  if (!context.mounted) {
                    return;
                  }
                  customMsgSnackbar(
                    context,
                    'Detecting mimetype failed. not supported.',
                  );
                  return;
                }
              }

              try {
                await draft.send();
                // reset fields
                captionNotifier.state = '';
                imageNotifier.state = null;
                // close both

                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context, rootNavigator: true).pop();
                // FIXME due to #718. well lets at least try forcing a refresh upon route.
                ref.invalidate(newsListProvider);
              } catch (err) {
                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
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
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Post Update'),
        ),
      ],
    );
  }

  Widget imageBuilder(BuildContext context, WidgetRef ref, Widget? child) {
    final selectedImage = ref.watch(selectedImageProvider);
    if (selectedImage != null) {
      return SizedBox(
        height: 300,
        child: InkWell(
          onTap: () {
            final imageNotifier = ref.read(selectedImageProvider.notifier);
            imageNotifier.state = null;
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
          final imageNotifier = ref.read(selectedImageProvider.notifier);
          imageNotifier.state = await picker.pickImage(
            source: ImageSource.gallery,
          );
        },
        child: const Center(
          child: Text('select an image (optional)'),
        ),
      ),
    );
  }
}

class _SpaceBuilder extends ConsumerWidget {
  final String currentSelectedSpace;

  const _SpaceBuilder({
    Key? key,
    required this.currentSelectedSpace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spaceDetails = ref.watch(selectedSpaceDetailsProvider);
    return spaceDetails.when(
      data: (space) =>
          space != null ? SpaceChip(space: space) : Text(currentSelectedSpace),
      error: (e, s) => Text('error: $e'),
      loading: () => const Text('loading'),
    );
  }
}
