import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Atlas.arrow_left_circle,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: const Text(
          'Bookmarks',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () => buildAboutDialog(),
              child: const Icon(
                Atlas.info_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: ListView.builder(
          itemBuilder: (context, index) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Oct 19 at 3:36am'),
                    Text('Web application on design'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text('View message'),
                            SizedBox(width: 8),
                            Icon(Atlas.arrow_right_circle, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future buildAboutDialog() {
    return showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            height: 250,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('About this Bookmark'),
                  const SizedBox(height: 16),
                  const Text(
                    'These bookmarks are only available in ToDo feature alone. They are available to your account only',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(100.0)),
                      ),
                      child: const Text('Okay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
