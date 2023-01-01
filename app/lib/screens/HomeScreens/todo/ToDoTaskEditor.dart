import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:effektio/controllers/todo_controller.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDoTaskAssign.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/SubscriberScreen.dart';
import 'package:effektio/widgets/AppCommon.dart';
import 'package:effektio/widgets/ToDoTaskItem.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get_time_ago/get_time_ago.dart';

class ToDoTaskEditor extends StatefulWidget {
  const ToDoTaskEditor({Key? key, required this.item, required this.avatars})
      : super(key: key);

  final ToDoTaskItem item;
  final List<ImageProvider<Object>> avatars;

  @override
  State<ToDoTaskEditor> createState() => _ToDoTaskEditorState();
}

class _ToDoTaskEditorState extends State<ToDoTaskEditor> {
  final TextEditingController notesController = TextEditingController();
  final TextEditingController subtitleController = TextEditingController();
  RxString? lastUpdated;
  final settings = RestrictedAmountPositions(
    maxAmountItems: 5,
    maxCoverage: 0.7,
    minCoverage: 0.1,
    align: StackAlign.left,
  );

  @override
  void initState() {
    super.initState();

    lastUpdated = GetTimeAgo.parse(widget.item.lastUpdated!).obs;
    notesController.text = widget.item.notes ?? 'Add Notes';
    subtitleController.text = widget.item.title;
  }

  @override
  void dispose() {
    notesController.dispose();
    subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ToDoTheme.backgroundGradientColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: ToDoTheme.secondaryColor,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.close),
          color: ToDoTheme.primaryTextColor,
        ),
        title: const Text('Task Edit', style: ToDoTheme.listTitleTextStyle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              showMoreBottomSheet();
            },
            icon: const Icon(Icons.more_horiz),
            color: ToDoTheme.primaryTextColor,
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppCommonTheme.transparentColor,
                    radius: 23,
                    child: Container(
                      width: 25,
                      height: 25,
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: ToDoTheme.calendarColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 2,
                          color: ToDoTheme.floatingABColor,
                        ),
                      ),
                    ),
                  ),
                  GetBuilder<ToDoController>(
                    id: 'subtitle',
                    builder: (ToDoController controller) {
                      return Container(
                        margin: const EdgeInsets.only(left: 10, top: 20),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.09,
                        child: TextFormField(
                          /*onFieldSubmitted: (val) {
                            subtitleController.text = val;
                            controller.updateNotes(
                              widget.item,
                              subtitleController,
                            );
                          },*/
                          maxLines: null,
                          controller: subtitleController,
                          style: ToDoTheme.listTitleTextStyle,
                          cursorColor: ToDoTheme.primaryTextColor,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 3),
                            border: InputBorder.none,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Added by:', style: ToDoTheme.subtitleTextStyle),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'David Chunli on 12 May',
                  style: ToDoTheme.subtitleTextStyle,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: AvatarStack(
                        borderWidth: 0,
                        settings: settings,
                        avatars: widget.avatars,
                        infoWidgetBuilder: infoAvatarBuilder,
                        width: 28,
                        height: 28,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) {
                          return ToDoTaskAssignScreen(avatars: widget.avatars);
                        },
                      ),
                    ),
                    child: const Text(
                      '+ Assign',
                      style: ToDoTheme.addTaskTextStyle,
                    ),
                  )
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              InkWell(
                onTap: () => showBottomSheet('Add Due Date'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/images/calendar-2.svg',
                        width: 18,
                        height: 18,
                        color: ToDoTheme.calendarColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Add Due Date',
                          style: ToDoTheme.taskTitleTextStyle.copyWith(
                            color: ToDoTheme.calendarColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              InkWell(
                onTap: () => _showActionSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        'assets/images/quill_attachment.svg',
                        width: 18,
                        height: 18,
                        color: ToDoTheme.calendarColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Add File',
                          style: ToDoTheme.taskTitleTextStyle.copyWith(
                            color: ToDoTheme.calendarColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: [
                        const Icon(
                          FlutterIcons.message1_ant,
                          color: ToDoTheme.calendarColor,
                          size: 18,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'Discussion',
                            style: ToDoTheme.taskTitleTextStyle.copyWith(
                              color: ToDoTheme.calendarColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () {
                        showNotYetImplementedMsg(
                          context,
                          'Writing message is not implemented yet',
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Write message',
                          style: ToDoTheme.taskTitleTextStyle.copyWith(
                            color: AppCommonTheme.secondaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(8),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(100)),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 16.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Jane Doe',
                                      style: ToDoTheme.taskSubtitleTextStyle
                                          .copyWith(
                                        color: ToDoTheme.calendarColor,
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        showCommentBottomSheet();
                                      },
                                      child: const Icon(
                                        FlutterIcons.dots_three_horizontal_ent,
                                        color: Colors.white,
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Lorem ipsum dolor sit amet',
                                    style: ToDoTheme.taskSubtitleTextStyle
                                        .copyWith(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 30,
                                    child: ListView.builder(
                                      itemCount: 2,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return Container(
                                          padding: const EdgeInsets.all(4.0),
                                          margin:
                                              const EdgeInsets.only(right: 8.0),
                                          decoration: const BoxDecoration(
                                            color: AppCommonTheme
                                                .backgroundColorLight,
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(100),),
                                          ),
                                          child: const Text(
                                            '😍 1',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                  itemCount: 2,
                  separatorBuilder: (BuildContext context, int index) {
                    return const Divider(
                      color: ToDoTheme.dividerColor,
                    );
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'Subscribers',
                        style: ToDoTheme.taskTitleTextStyle.copyWith(
                          color: ToDoTheme.calendarColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'No one will be notified when someone comments on this to-do list',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        color: ToDoTheme.calendarColor,
                        fontSize: 13,
                      ),
                    ),
                    InkWell(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ToDoSubscriberScreen(),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(100)),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Text(
                          'Add/remove people',
                          style: ToDoTheme.taskTitleTextStyle.copyWith(
                            color: ToDoTheme.calendarColor,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        'You are not subscribed',
                        style: ToDoTheme.taskTitleTextStyle.copyWith(
                          color: ToDoTheme.calendarColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      "You won't be notified when comments are posted",
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        color: ToDoTheme.calendarColor,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(100)),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        'Subscriber me',
                        style: ToDoTheme.taskTitleTextStyle.copyWith(
                          color: ToDoTheme.calendarColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  color: ToDoTheme.dividerColor,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Obx(
                  () => SizedBox(
                    height: 30,
                    width: double.infinity,
                    child: Text(
                      'Last Update $lastUpdated',
                      style: ToDoTheme.activeTasksTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showBottomSheet(String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ToDoTheme.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: false,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Remove',
                        style: ToDoTheme.taskSubtitleTextStyle.copyWith(
                          color: ToDoTheme.removeColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(title, style: ToDoTheme.taskTitleTextStyle),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Done',
                        style: ToDoTheme.taskSubtitleTextStyle.copyWith(
                          color: ToDoTheme.floatingABColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(
              color: ToDoTheme.bottomSheetDividerColor,
              height: 0,
              thickness: 1,
              indent: 20,
              endIndent: 20,
            ),
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              children: <Widget>[
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: ToDoTheme.primaryTextColor,
                    ),
                    title: Text(
                      'Later Today',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/calendar-2.svg',
                      color: ToDoTheme.primaryTextColor,
                    ),
                    title: Text(
                      'Tomorrow',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/calendar.svg',
                      color: ToDoTheme.primaryTextColor,
                    ),
                    title: Text(
                      'Next Week',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: SvgPicture.asset(
                      'assets/images/calendar-tick.svg',
                      color: ToDoTheme.floatingABColor,
                    ),
                    title: Text(
                      'Pick a Date & Time',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: ToDoTheme.floatingABColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: ToDoTheme.floatingABColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void showMoreBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ToDoTheme.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: true,
      builder: (BuildContext context) {
        return Wrap(
          children: <Widget>[
            ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              children: <Widget>[
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: const Icon(
                      Icons.bookmark_border,
                      color: ToDoTheme.primaryTextColor,
                    ),
                    title: Text(
                      'Bookmark',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading:const Icon(Icons.link, color: ToDoTheme.primaryTextColor,),
                    title: Text(
                      'Copy Link',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: const Icon(Icons.comments_disabled_outlined, color: ToDoTheme.primaryTextColor,),
                    title: Text(
                      'Close comment',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline, color: ToDoTheme.primaryTextColor,),
                    title: Text(
                      'Delete',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {},
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: ToDoTheme.primaryTextColor,),
                    title: Text(
                      'View change log',
                      style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              height: 60,
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: ToDoTheme.primaryTextColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('Share this ToDo', style: ToDoTheme.taskTitleTextStyle.copyWith(
                  fontWeight: FontWeight.w500,
                ),),
              ),
            )
          ],
        );
      },
    );
  }

  Widget infoAvatarBuilder(int count) {
    return CircleAvatar(
      radius: 28,
      backgroundColor: ToDoTheme.infoAvatarColor,
      child: Text('+$count', style: ToDoTheme.infoAvatarTextStyle),
    );
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoTheme(
        data: const CupertinoThemeData(
          scaffoldBackgroundColor: ToDoTheme.bottomSheetColor,
        ),
        child: CupertinoActionSheet(
          actions: <CupertinoActionSheetAction>[
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    FlutterIcons.camera_outline_mco,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Take a Photo',
                          style: ToDoTheme.listTitleTextStyle,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    FlutterIcons.md_photos_ion,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Choose from Photos',
                          style: ToDoTheme.listTitleTextStyle,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  const Icon(
                    FlutterIcons.file_document_outline_mco,
                    color: Colors.white,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Choose from Files',
                          style: ToDoTheme.listTitleTextStyle,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text(
              'Cancel',
              style: ToDoTheme.listTitleTextStyle,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void showCommentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ToDoTheme.bottomSheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      isDismissible: true,
      builder: (BuildContext context) {
        return Wrap(
          children: [
            Padding(padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                      color: ToDoTheme.secondaryCardColor,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bookmark_border, color: ToDoTheme.primaryTextColor,),
                      const SizedBox(
                        height: 8,
                      ),
                      Text('Save', style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                      color: ToDoTheme.secondaryCardColor,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.link, color: ToDoTheme.primaryTextColor,),
                      const SizedBox(
                        height: 8,
                      ),
                      Text('Copy Link', style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                      color: ToDoTheme.secondaryCardColor,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.file_upload_outlined, color: ToDoTheme.primaryTextColor,),
                      const SizedBox(
                        height: 8,
                      ),
                      Text('Save', style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      )
                    ],
                  ),
                ),
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                      color: ToDoTheme.secondaryCardColor,
                      borderRadius: BorderRadius.circular(12)
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red,),
                      const SizedBox(
                        height: 8,
                      ),
                      Text('Save', style: ToDoTheme.taskTitleTextStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                      )
                    ],
                  ),
                ),
              ],
            ),)
          ],
        );
      },
    );
  }
}
