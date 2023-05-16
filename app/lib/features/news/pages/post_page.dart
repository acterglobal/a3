import 'dart:io';
import 'dart:typed_data';

import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/not_implemented.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/custom_app_bar.dart';
import 'package:acter/common/widgets/custom_avatar.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter/features/news/notifiers/search_space_notifier.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, EventId, FfiListNewsSlide, NewsEntryDraft, NewsSlide, Space;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';

class PostPage extends ConsumerStatefulWidget {
  final String? attachmentUri;

  const PostPage({required this.attachmentUri, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.watch(searchSpaceProvider);
    final selectedSpace = ref.watch(selectedSpaceProvider);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        title: const Text('Post'),
        context: context,
      ),
      body: Stack(
        children: <Widget>[
          ListView(
            shrinkWrap: true,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.all(8),
                    color: Theme.of(context).colorScheme.neutral5,
                    width: 100,
                    height: 100,
                    child: buildAttachment(),
                  ),
                  Expanded(
                    child: TextFormField(
                      keyboardType: TextInputType.multiline,
                      controller: titleController,
                      maxLines: 5,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.neutral5,
                          ),
                      onChanged: (String val) {},
                      decoration: InputDecoration(
                        hintText: 'Caption your update',
                        hintStyle:
                            Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.neutral5,
                                ),
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      cursorColor: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),
              const Divider(indent: 10, endIndent: 10),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: TextFormField(
                  keyboardType: TextInputType.multiline,
                  controller: descriptionController,
                  maxLines: 4,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Theme.of(context).colorScheme.neutral5),
                  onChanged: (String val) {},
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.neutral5,
                        ),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  cursorColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              const Divider(indent: 10, endIndent: 10),
              GestureDetector(
                onTap: () => context.push('/updates/post/search_space'),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: selectedSpace != null
                            ? CustomAvatar(
                                uniqueKey: UniqueKey().toString(),
                                radius: 20,
                                isGroup: false,
                                cacheHeight: 120,
                                cacheWidth: 120,
                                stringName: selectedSpace.avatar != null
                                    ? ''
                                    : 'fallback',
                                avatar: selectedSpace.avatar,
                              )
                            : CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.neutral5,
                                radius: 18,
                              ),
                      ),
                      Text(
                        selectedSpace != null
                            ? selectedSpace.displayName!
                            : 'Select Space',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(indent: 10, endIndent: 10),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () {},
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.neutral6,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Add Message Link',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(indent: 10, endIndent: 10),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () {},
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Add Reminder',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.keyboard_arrow_right,
                        color: Theme.of(context).colorScheme.neutral6,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(indent: 10, endIndent: 10),
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () {},
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Atlas.curve_arrow_right,
                        color: Theme.of(context).colorScheme.neutral6,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Share to',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            ],
          ),
          buildBottomBar(selectedSpace),
        ],
      ),
    );
  }

  Widget buildAttachment() {
    if (widget.attachmentUri == null) {
      return const Center(child: Icon(Atlas.text));
    }
    String? mimeType = lookupMimeType(widget.attachmentUri!);
    if (mimeType != null) {
      if (mimeType.startsWith('image/')) {
        return Image.file(
          File(widget.attachmentUri!),
          fit: BoxFit.fitHeight,
        );
      } else if (mimeType.startsWith('audio/')) {
        return const Center(child: Icon(Atlas.file_audio));
      } else if (mimeType.startsWith('video/')) {
        return const Center(child: Icon(Atlas.file_video));
      }
    }
    return const Center(child: Icon(Atlas.user_file));
  }

  Widget buildBottomBar(SpaceItem? selectedSpace) {
    return Positioned(
      bottom: 0,
      child: Visibility(
        visible: true,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {},
                child: Text(
                  'Save to Draft',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                style: ButtonStyle(
                  shape: MaterialStateProperty.all<BeveledRectangleBorder>(
                    const BeveledRectangleBorder(),
                  ),
                  fixedSize: MaterialStateProperty.all<Size>(
                    Size(MediaQuery.of(context).size.width * 0.45, 45),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => handlePost(selectedSpace),
                child: Text(
                  'Post',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                  shape: MaterialStateProperty.all<BeveledRectangleBorder>(
                    const BeveledRectangleBorder(),
                  ),
                  fixedSize: MaterialStateProperty.all<Size>(
                    Size(MediaQuery.of(context).size.width * 0.4, 45),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<EventId?> handlePost(SpaceItem? selectedSpace) async {
    if (selectedSpace == null) {
      return null;
    }
    Client client = ref.read(clientProvider)!;
    Space space = await client.getSpace(selectedSpace.roomId);
    NewsEntryDraft draft = space.newsDraft();
    NewsSlide? slide;
    if (widget.attachmentUri == null) {
      slide = draft.newTextSlide(descriptionController.text);
    } else {
      String? mimeType = lookupMimeType(widget.attachmentUri!);
      if (mimeType != null) {
        if (mimeType.startsWith('image/')) {
          File image = File(widget.attachmentUri!);
          Uint8List bytes = image.readAsBytesSync();
          var decodedImage = await decodeImageFromList(bytes);
          EventId eventId = await space.sendImageMessage(
            widget.attachmentUri!,
            'Untitled Image',
            mimeType,
            bytes.length,
            decodedImage.width,
            decodedImage.height,
            null,
          );
          slide = draft.newImageSlide(
            descriptionController.text,
            eventId.toString(),
            mimeType,
            bytes.length,
            decodedImage.width,
            decodedImage.height,
            null,
          );
        } else if (mimeType.startsWith('audio/')) {
          File audio = File(widget.attachmentUri!);
          Uint8List bytes = audio.readAsBytesSync();
          EventId eventId = await space.sendAudioMessage(
            widget.attachmentUri!,
            'Untitled Audio',
            mimeType,
            null,
            bytes.length,
          );
          slide = draft.newAudioSlide(
            descriptionController.text,
            eventId.toString(),
            null,
            mimeType,
            bytes.length,
          );
        } else if (mimeType.startsWith('video/')) {
          File video = File(widget.attachmentUri!);
          Uint8List bytes = video.readAsBytesSync();
          EventId eventId = await space.sendVideoMessage(
            widget.attachmentUri!,
            'Untitled Video',
            mimeType,
            null,
            null,
            null,
            bytes.length,
            null,
          );
          slide = draft.newVideoSlide(
            descriptionController.text,
            eventId.toString(),
            null,
            null,
            null,
            mimeType,
            bytes.length,
            null,
          );
        }
      }
      if (slide == null) {
        File file = File(widget.attachmentUri!);
        Uint8List bytes = file.readAsBytesSync();
        EventId eventId = await space.sendFileMessage(
          widget.attachmentUri!,
          'Untitled File',
          mimeType ?? 'application/octet',
          bytes.length,
        );
        slide = draft.newFileSlide(
          descriptionController.text,
          eventId.toString(),
          mimeType ?? 'application/octet',
          bytes.length,
        );
      }
    }
    List<NewsSlide> slides = [];
    slides.add(slide);
    draft.slides(slides as FfiListNewsSlide);
    return await draft.send();
  }

  void handleDraft(SpaceItem? selectedSpace) {
    showNotYetImplementedMsg(
      context,
      'Draft is not implemented yet',
    );
  }
}
