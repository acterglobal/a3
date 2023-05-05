import 'dart:io';

import 'package:acter/common/themes/app_theme.dart';
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => MediaQuery.of(context).size.width > 600
              ? context.go('/dashboard')
              : context.pop(),
          icon: const Icon(Atlas.arrow_left),
        ),
        title: Text(
          'Post',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(color: Theme.of(context).colorScheme.neutral5),
                  onChanged: (String val) {},
                  decoration: InputDecoration(
                    hintText: 'Caption your update',
                    hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
          const Divider(
            indent: 10,
            endIndent: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              keyboardType: TextInputType.multiline,
              controller: descriptionController,
              maxLines: 4,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Theme.of(context).colorScheme.neutral5),
              onChanged: (String val) {},
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              cursorColor: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          const Divider(
            indent: 10,
            endIndent: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.neutral5,
                  radius: 18,
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    items: const [],
                    onChanged: (String? val) => {},
                    icon: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Select Space',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_outlined,
                          color: Theme.of(context).colorScheme.neutral6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(
            indent: 10,
            endIndent: 10,
          ),
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
          const Divider(
            indent: 10,
            endIndent: 10,
          ),
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
          const Divider(
            indent: 10,
            endIndent: 10,
          ),
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
          const Spacer(),
          Visibility(
            visible: true,
            child: Container(
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
                    onPressed: () {},
                    child: Text(
                      'Next',
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
        ],
      ),
    );
  }
}
