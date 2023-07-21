import 'dart:io';
import 'package:acter/features/chat/controllers/chat_room_controller.dart';
import 'package:acter/features/chat/widgets/custom_input.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageSelectionPage extends StatefulWidget {
  final List<PlatformFile> imageList;
  final String roomName;

  const ImageSelectionPage({
    Key? key,
    required this.imageList,
    required this.roomName,
  }) : super(key: key);

  @override
  State<ImageSelectionPage> createState() => _ImageSelectionPageState();
}

class _ImageSelectionPageState extends State<ImageSelectionPage> {
  ChatRoomController controller = Get.find<ChatRoomController>();
  int selectedIndex = 0;
  final PageController pageController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: PhotoViewGallery.builder(
              itemCount: widget.imageList.length,
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                PlatformFile file = widget.imageList[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(file.path!)),
                  initialScale: PhotoViewComputedScale.contained * 0.8,
                );
              },
              backgroundDecoration: const BoxDecoration(),
              pageController: pageController,
              onPageChanged: onChangePage,
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (PlatformFile file in widget.imageList)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 8),
                      child: InkWell(
                        onTap: () => onClickItem(file),
                        child: Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                image: DecorationImage(
                                  fit: BoxFit.fill,
                                  image: FileImage(File(file.path!)),
                                ),
                                border: getItemBorder(file),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              top: 4,
                              child: InkWell(
                                onTap: () => onCloseItem(file),
                                child: const CircleAvatar(
                                  radius: 8,
                                  child: Icon(Atlas.xmark_circle),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Icon(Atlas.image_chat),
                  ),
                ],
              ),
            ),
          ),
          CustomChatInput(
            roomName: widget.roomName,
            onButtonPressed: () async => await onSend(context),
          )
        ],
      ),
    );
  }

  BoxBorder? getItemBorder(PlatformFile file) {
    if (selectedIndex != widget.imageList.indexOf(file)) {
      return null;
    }
    return Border.all(
      width: 2,
    );
  }

  void onChangePage(int index) {
    if (mounted) {
      setState(() => selectedIndex = index);
    }
  }

  void onClickItem(PlatformFile file) {
    if (mounted) {
      int index = widget.imageList.indexOf(file);
      setState(() => selectedIndex = index);
      pageController.jumpToPage(index);
    }
  }

  void onCloseItem(PlatformFile file) {
    int index = widget.imageList.indexOf(file);
    widget.imageList.removeAt(index);
    if (widget.imageList.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  Future<void> onSend(BuildContext context) async {
    Navigator.of(context).pop();
    for (PlatformFile file in widget.imageList) {
      await controller.sendImage(file);
    }
  }
}
