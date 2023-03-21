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
              onPageChanged: (int i) {
                setState(() => selectedIndex = i);
              },
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
                      child: buildImageItem(file),
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
            roomController: controller,
            isChatScreen: false,
            roomName: widget.roomName,
            onButtonPressed: () async {
              Navigator.of(context).pop();
              for (PlatformFile file in widget.imageList) {
                await controller.sendImage(file);
              }
            },
          )
        ],
      ),
    );
  }

  Widget buildImageItem(PlatformFile file) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedIndex = widget.imageList.indexOf(file);
          pageController.jumpToPage(selectedIndex);
        });
      },
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
              onTap: () {
                int idx = widget.imageList.indexOf(file);
                widget.imageList.removeAt(idx);
                if (widget.imageList.isEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: const CircleAvatar(
                radius: 8,
                child: Icon(Atlas.xmark_circle),
              ),
            ),
          ),
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
}
