import 'dart:typed_data';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_button.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

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
              imageNotifier.state == null
                  ? MdEditorWithPreview(
                      hintText: 'Text Update',
                      labelText: 'Text Update',
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
                    )
                  : Expanded(
                      child: TextFormField(
                        textAlignVertical: TextAlignVertical.top,
                        decoration: const InputDecoration(
                          hintText: 'Text caption',
                          labelText: 'Image Caption',
                        ),
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
              const SelectSpaceFormField(canCheck: 'CanPostNews'),
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

              showAdaptiveDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) => DefaultDialog(
                  title: Text(
                    displayMsg,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
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
                showAdaptiveDialog(
                  context: context,
                  builder: (context) => DefaultDialog(
                    title: Text(
                      '$displayMsg failed: \n $err"',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    actions: <Widget>[
                      DefaultButton(
                        onPressed: () =>
                            Navigator.of(context, rootNavigator: true).pop(),
                        title: 'Close',
                      ),
                    ],
                  ),
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
