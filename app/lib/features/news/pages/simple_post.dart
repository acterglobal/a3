import 'dart:typed_data';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/md_editor_with_preview.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:cross_file_image/cross_file_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

// upload avatar path
final selectedImageProvider = StateProvider<XFile?>((ref) => null);
final textProvider =
    StateProvider<TextEditingController>((ref) => TextEditingController());

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
    return SideSheet(
      header: 'Create new Update',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Form(
          key: _formKey,
          child: _ImageBuilder(),
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
          key: NewsUpdateKeys.submitBtn,
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final spaceId = ref.read(selectedSpaceIdProvider);
              final file = ref.read(selectedImageProvider);
              final caption = ref.read(textProvider);
              late String displayMsg;

              if (file == null) {
                displayMsg = 'Posting image update';
              } else {
                displayMsg = 'Posting text update';
              }

              EasyLoading.show(status: displayMsg);
              try {
                final space = await ref.read(spaceProvider(spaceId!).future);
                NewsEntryDraft draft = space.newsDraft();
                if (file == null) {
                  draft.addTextSlide(caption.text);
                } else {
                  String? mimeType = file.mimeType ?? lookupMimeType(file.path);

                  if (mimeType != null) {
                    if (mimeType.startsWith('image/')) {
                      Uint8List bytes = await file.readAsBytes();
                      final decodedImage = await decodeImageFromList(bytes);
                      await draft.addImageSlide(
                        caption.text,
                        file.path,
                        mimeType,
                        bytes.length,
                        decodedImage.width,
                        decodedImage.height,
                        null,
                      );
                    } else {
                      EasyLoading.showError(
                        'Posting of $mimeType not yet supported',
                      );
                      return;
                    }
                  } else {
                    EasyLoading.showError(
                      'Detecting mimetype failed. not supported.',
                    );
                    return;
                  }
                }

                await draft.send();

                // reset fields
                ref.read(textProvider.notifier).state.text = '';
                ref.read(selectedImageProvider.notifier).state = null;
                // close both
                EasyLoading.dismiss();

                // We are doing as expected, but the lints triggers.
                // ignore: use_build_context_synchronously
                if (!context.mounted) {
                  return;
                }
                // closing the sidebar.
                Navigator.of(context, rootNavigator: true).pop();
                // FIXME due to #718. well lets at least try forcing a refresh upon route.
                ref.invalidate(newsListProvider);
              } catch (err) {
                EasyLoading.showError(
                  '$displayMsg failed: \n $err"',
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
}

class _ImageBuilder extends ConsumerStatefulWidget {
  const _ImageBuilder({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => __ImageBuilderState();
}

class __ImageBuilderState extends ConsumerState<_ImageBuilder> {
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final selectedImage = ref.watch(selectedImageProvider);
    final halfHeight = MediaQuery.of(context).size.height * 0.5;
    if (selectedImage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              // make sure we always have enough space for the other items.
              maxHeight: halfHeight,
            ),
            child: Center(
              child: InkWell(
                onTap: () {
                  final imageNotifier =
                      ref.read(selectedImageProvider.notifier);
                  imageNotifier.state = null;
                },
                child: Image(
                  image: XFileImage(selectedImage),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextFormField(
                controller: ref.read(textProvider),
                key: NewsUpdateKeys.imageCaption,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'caption',
                  labelText: 'Image Caption',
                ),
                expands: false,
                minLines: null,
                maxLines: 2,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
          const SelectSpaceFormField(canCheck: 'CanPostNews'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: halfHeight * 0.5,
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
        ),
        MdEditorWithPreview(
          controller: ref.read(textProvider),
          key: NewsUpdateKeys.textUpdateField,
          hintText: 'Text Update',
          labelText: 'Text Update',
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              return null;
            }
            return 'Please enter a text or add an image';
          },
        ),
        const SelectSpaceFormField(canCheck: 'CanPostNews'),
      ],
    );
  }
}
