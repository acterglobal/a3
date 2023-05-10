import 'dart:io';

import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/widgets/custom_app_bar.dart';
import 'package:acter/features/home/states/client_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show Client, NewsEntryDraft, Space;
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PostPage extends ConsumerStatefulWidget {
  final String? imgUri;

  const PostPage({required this.imgUri, super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: CustomAppBar(
        key: UniqueKey(),
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
                    child: widget.imgUri != null
                        ? Image.file(
                            File(widget.imgUri!),
                            fit: BoxFit.fitHeight,
                          )
                        : const Center(child: Icon(Atlas.image_gallery)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.neutral5,
                          radius: 18,
                        ),
                      ),
                      Text(
                        'Select Space',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(indent: 10, endIndent: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                padding: const EdgeInsets.all(8.0),
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
                padding: const EdgeInsets.all(8.0),
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
          Positioned(
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
                        shape:
                            MaterialStateProperty.all<BeveledRectangleBorder>(
                          const BeveledRectangleBorder(),
                        ),
                        fixedSize: MaterialStateProperty.all<Size>(
                          Size(MediaQuery.of(context).size.width * 0.45, 45),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: handlePost,
                      child: Text(
                        'Post',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Theme.of(context).colorScheme.tertiary,
                        ),
                        shape:
                            MaterialStateProperty.all<BeveledRectangleBorder>(
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
          ),
        ],
      ),
    );
  }

  Future<void> handlePost() async {
    Client client = ref.read(clientProvider)!;
    Space space = await client.getSpace('#news:acter.global');
    NewsEntryDraft draft = space.newsDraft();
    draft.newTextSlide('123');
  }
}
