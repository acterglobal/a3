import 'dart:io';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/custom_app_bar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/news/providers/news_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
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
    final selectedSpace = ref.watch(selectedSpaceProvider);
    // pre-fetch spaces prior to selection
    ref.watch(searchSpaceProvider);

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
                onTap: () => context.pushNamed(Routes.updatesPostSearch.name),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      selectedSpace != null
                          ? Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: ActerAvatar(
                                mode: DisplayMode.Space,
                                uniqueId: selectedSpace.roomId,
                                avatar: selectedSpace.spaceProfileData
                                    .getAvatarImage(),
                                size: 36,
                                displayName:
                                    selectedSpace.spaceProfileData.displayName,
                              ),
                            )
                          : Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.neutral5,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                      Text(
                        selectedSpace != null
                            ? selectedSpace.spaceProfileData.displayName!
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

  Widget buildBottomBar(SpaceItem? selectedSpace) {
    return Positioned(
      bottom: 0,
      child: Visibility(
        visible: true,
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ref.read(selectedSpaceProvider) != null
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.neutral5,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              ElevatedButton(
                onPressed: () => customMsgSnackbar(
                  context,
                  'Save to Draft is not implemented yet',
                ),
                child: Text(
                  'Save to Draft',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                style: ButtonStyle(
                  backgroundColor: ref.read(selectedSpaceProvider) != null
                      ? null
                      : MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.neutral5,
                        ),
                  shape: MaterialStateProperty.all<BeveledRectangleBorder>(
                    const BeveledRectangleBorder(),
                  ),
                  fixedSize: MaterialStateProperty.all<Size>(
                    Size(MediaQuery.of(context).size.width * 0.45, 45),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => ref.read(selectedSpaceProvider) != null
                    ? handlePost(context, mounted)
                    : customMsgSnackbar(
                        context,
                        'Please select space to continue',
                      ),
                child: Text(
                  'Post',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                style: ButtonStyle(
                  backgroundColor: ref.read(selectedSpaceProvider) != null
                      ? MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.tertiary,
                        )
                      : MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.neutral5,
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

  void handlePost(BuildContext context, [bool mounted = true]) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                // The loading indicator
                CircularProgressIndicator(),
                SizedBox(
                  height: 15,
                ),
                // Some text
                Text('Posting Update...')
              ],
            ),
          ),
        );
      },
    );
    // do async operation
    await ref
        .read(postUpdateProvider.notifier)
        .postUpdate(widget.attachmentUri, descriptionController.text);
    // Close the dialog programmatically
    // We use "mounted" variable to get rid of the "Do not use BuildContexts across async gaps" warning
    if (mounted) {
      context.pop();
      context.go('/updates');
      // FIXME: Will this refresh the updates??
      // ignore: unused_local_variable
      var syncState = ref.read(clientProvider)!.startSync();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.success,
          content: Text(
            'Update posted successfully to ${ref.read(selectedSpaceProvider)!.roomId}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
