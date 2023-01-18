import 'dart:io';

import 'package:beamer/beamer.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/chat_room_controller.dart';
import 'package:effektio/models/ImageSelectionModel.dart';
import 'package:effektio/widgets/CustomChatInput.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class ImageSelection extends StatefulWidget {
 final ImageSelectionModel imageSelectionModel;

  const ImageSelection({
    Key? key,
    required this.imageSelectionModel,
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
              itemCount: widget.imageSelectionModel.imageList.length,
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (context, index) {
                PlatformFile file = widget.imageSelectionModel.imageList[index];
                return PhotoViewGalleryPageOptions(
                  imageProvider: FileImage(File(file.path!)),
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
                  for (PlatformFile file in widget.imageSelectionModel.imageList)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 8),
                      child: buildImageItem(file),
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
            roomName: widget.imageSelectionModel.roomName,
            onButtonPressed: () async {
              Beamer.of(context).beamBack();
              for (PlatformFile file in widget.imageSelectionModel.imageList) {
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
          selectedIndex = widget.imageSelectionModel.imageList.indexOf(file);
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
              color: AppCommonTheme.backgroundColor,
              border: getItemBorder(file),
            ),
          ),
          Positioned(
            right: 4,
            top: 4,
            child: InkWell(
              onTap: () {
                int idx = widget.imageSelectionModel.imageList.indexOf(file);
                widget.imageSelectionModel.imageList.removeAt(idx);
                if (widget.imageSelectionModel.imageList.isEmpty) {
                  Beamer.of(context).beamBack();
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

  BoxBorder? getItemBorder(PlatformFile file) {
    if (selectedIndex != widget.imageSelectionModel.imageList.indexOf(file)) {
      return null;
    }
    return Border.all(
      color: ChatTheme01.chatSelectedImageBorderColor,
      width: 2,
    );
  }
}
