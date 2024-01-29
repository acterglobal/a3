import 'dart:io';
import 'dart:math';

import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/widgets/acter_video_player.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/features/news/model/news_slide_model.dart';
import 'package:acter/features/news/providers/news_post_editor_providers.dart';
import 'package:acter/features/news/widgets/news_post_editor/select_action_item.dart';
import 'package:acter/features/news/widgets/news_post_editor/slide_editor_options.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class NewsPostEditor extends ConsumerStatefulWidget {
  const NewsPostEditor({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _NewsPostEditorState();
}

class _NewsPostEditorState extends ConsumerState<NewsPostEditor> {
  //General variable declaration
  final textController = TextEditingController();
  NewsSlideItem? selectedNewsPost;
  List<NewsSlideItem> newsPostList = <NewsSlideItem>[];
  String? invitedSpaceId;
  String? invitedChatId;

  //Build UI
  @override
  Widget build(BuildContext context) {
    selectedNewsPost = ref.watch(currentNewsSlideProvider);
    newsPostList = ref.watch(newSlideListProvider).getNewsList();
    debugPrint('selectedNewsPost : ${selectedNewsPost?.textBackgroundColor}');

    return Scaffold(
      appBar: appBarUI(context),
      body: bodyUI(context),
      floatingActionButton: actionButtonUI(context),
    );
  }

  //App Bar
  AppBar appBarUI(BuildContext context) {
    return AppBar(
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Atlas.xmark_circle),
      ),
      backgroundColor: selectedNewsPost == null
          ? Colors.transparent
          : selectedNewsPost?.textBackgroundColor,
      actions: [
        Visibility(
          visible: selectedNewsPost?.type == NewsSlideType.text,
          child: IconButton(
            onPressed: () {
              selectedNewsPost?.textBackgroundColor =
                  Colors.primaries[Random().nextInt(Colors.primaries.length)];
              setState(() {});
            },
            icon: const Icon(Atlas.color),
          ),
        ),
      ],
    );
  }

  //Action Button
  Widget actionButtonUI(BuildContext context) {
    return Visibility(
      visible: selectedNewsPost != null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => selectActionItemDialog(context),
          child: const Icon(Atlas.plus_circle),
        ),
      ),
    );
  }

  //Select any widget for action button
  void selectActionItemDialog(BuildContext context) {
    showAdaptiveDialog(
      context: context,
      builder: (context) {
        return AlertDialog.adaptive(
          title: const Text('Add an action widget'),
          content: SelectActionItem(
            onSpaceItemSelected: (spaceId) async {
              Navigator.of(context, rootNavigator: true).pop();
              invitedSpaceId = spaceId;
              setState(() {});
            },
            onChatItemSelected: (chatId) async {
              Navigator.of(context, rootNavigator: true).pop();
              invitedChatId = chatId;
              setState(() {});
            },
          ),
        );
      },
    );
  }

  //Body UI
  Widget bodyUI(BuildContext context) {
    return Column(
      children: [
        //News content UI
        Expanded(child: newsContentUI()),
        //Slide options
        const SlideEditorOptions(),
      ],
    );
  }

  Widget newsContentUI() {
    return Stack(
      fit: StackFit.expand,
      children: [
        //Selected Slide Data View
        slidePostUI(context),
        //Selected Action Buttons View
        selectedActionButtonsUI(),
      ],
    );
  }

  //Show slide data view based on the current slide selection
  Widget slidePostUI(BuildContext context) {
    switch (selectedNewsPost?.type) {
      case NewsSlideType.text:
        return slideTextPostUI(context);
      case NewsSlideType.image:
        return slideImagePostUI(context);
      case NewsSlideType.video:
        return slideVideoPostUI(context);
      default:
        return emptySlidePostUI(context);
    }
  }

  //Show selected Action Buttons
  Widget selectedActionButtonsUI() {
    return Positioned(
      bottom: 10,
      left: 10,
      child: Row(
        children: [
          if (invitedSpaceId != null)
            Column(
              children: [
                const Text('Space'),
                SpaceChip(spaceId: invitedSpaceId),
              ],
            ),
          if (invitedSpaceId != null) const SizedBox(width: 10.0),
          if (invitedChatId != null)
            Column(
              children: [
                const Text('Chat'),
                chatChip(),
              ],
            ),
        ],
      ),
    );
  }

  Widget chatChip() {
    return Chip(
      avatar: RoomAvatar(
        roomId: invitedChatId!,
        avatarSize: 30,
        showParent: true,
      ),
      label: ref.watch(chatProfileDataProviderById(invitedChatId!)).when(
            data: (profile) => Text(
              profile.displayName ?? invitedChatId!,
              softWrap: true,
              textAlign: TextAlign.center,
            ),
            error: (err, stackTrace) {
              return Text(
                invitedChatId!,
                overflow: TextOverflow.clip,
              );
            },
            loading: () => const CircularProgressIndicator(),
          ),
    );
  }

  Widget emptySlidePostUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SvgPicture.asset(
            'assets/images/empty_updates.svg',
            semanticsLabel: 'state',
            height: 150,
            width: 150,
          ),
          const SizedBox(height: 20),
          Text(
            'Create actionable posts and engage everyone within your space.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 40),
          OutlinedButton(
            onPressed: () => addTextSlide(),
            child: const Text('Add text slide'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () async => await addImageSlide(),
            child: const Text('Add image slide'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () async => await addVideoSlide(),
            child: const Text('Add video slide'),
          ),
        ],
      ),
    );
  }

  //Add text slide
  void addTextSlide() {
    NewsSlideItem textSlide = NewsSlideItem(
      type: NewsSlideType.text,
      text: '',
      textBackgroundColor:
          Colors.primaries[Random().nextInt(Colors.primaries.length)],
    );
    ref.watch(newSlideListProvider).addSlide(textSlide);
  }

  //Add image slide
  Future<void> addImageSlide() async {
    XFile? imageFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      ref.watch(newSlideListProvider).addSlide(
            NewsSlideItem(
              type: NewsSlideType.image,
              mediaFile: imageFile,
            ),
          );
    }
  }

  //Add video slide
  Future<void> addVideoSlide() async {
    XFile? videoFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (videoFile != null) {
      ref.watch(newSlideListProvider).addSlide(
            NewsSlideItem(
              type: NewsSlideType.video,
              mediaFile: videoFile,
            ),
          );
    }
  }

  Widget slideTextPostUI(BuildContext context) {
    textController.text = selectedNewsPost!.text ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      alignment: Alignment.center,
      color: selectedNewsPost!.textBackgroundColor,
      child: TextField(
        controller: textController,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.newline,
        minLines: 1,
        maxLines: 10,
        onChanged: (value) {
          setState(() {
            final index = newsPostList.indexOf(selectedNewsPost!);
            selectedNewsPost!.text = value;
            newsPostList[index] = selectedNewsPost!;
          });
        },
        decoration: InputDecoration(
          fillColor: Colors.transparent,
          hintText: 'Type a text',
          hintStyle: Theme.of(context)
              .textTheme
              .titleMedium!
              .copyWith(color: Colors.white.withOpacity(0.5)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget slideImagePostUI(BuildContext context) {
    final imageFile = selectedNewsPost!.mediaFile;
    return Image.file(
      File(imageFile!.path),
      fit: BoxFit.contain,
    );
  }

  Widget slideVideoPostUI(BuildContext context) {
    final videoFile = selectedNewsPost!.mediaFile!;
    return ActerVideoPlayer(
      key: Key(videoFile.name),
      videoFile: File(videoFile.path),
    );
  }
}
