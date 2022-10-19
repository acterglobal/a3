import 'dart:io';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageSelection extends StatefulWidget {
  final List imageList;
  final String roomName;

  const ImageSelection({
    Key? key,
    required this.imageList,
    required this.roomName,
  }) : super(key: key);

  @override
  State<ImageSelection> createState() => _ImageSelectionState();
}

class _ImageSelectionState extends State<ImageSelection> {
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
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(widget.imageList[index].path)),
                  initialScale: PhotoViewComputedScale.contained * 0.8,
                );
              },
              backgroundDecoration: const BoxDecoration(
                color: AppCommonTheme.backgroundColor,
              ),
              pageController: pageController,
              onPageChanged: (int i) {
                setState(() => selectedIndex = i);
              },
            ),
          ),
          Container(
            width: double.infinity,
            color: AppCommonTheme.backgroundColorLight,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var item in widget.imageList)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 8),
                      child: buildImageItem(item),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: SvgPicture.asset(
                      'assets/images/select_new_item.svg',
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomChatInput(
            isChatScreen: false,
            roomName: widget.roomName,
            onButtonPressed: () async {
              Navigator.of(context).pop();
              for (var image in widget.imageList) {
                await controller.sendImage(image);
              }
            },
          )
        ],
      ),
    );
  }

  Widget buildImageItem(item) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedIndex = widget.imageList.indexOf(item);
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
                image: FileImage(File(item.path)),
              ),
              color: AppCommonTheme.backgroundColor,
              border: getItemBorder(item),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: InkWell(
              onTap: () {
                int idx = widget.imageList.indexOf(item);
                widget.imageList.removeAt(idx);
                if (widget.imageList.isEmpty) {
                  Navigator.of(context).pop();
                }
              },
              child: CircleAvatar(
                radius: 8,
                backgroundColor: AppCommonTheme.transparentColor,
                child: SvgPicture.asset(
                  'assets/images/remove_selected_item.svg',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxBorder? getItemBorder(item) {
    if (selectedIndex != widget.imageList.indexOf(item)) {
      return null;
    }
    return Border.all(
      color: ChatTheme01.chatSelectedImageBorderColor,
      width: 2,
    );
  }
}
