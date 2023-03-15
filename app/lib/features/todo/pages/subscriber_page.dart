// import 'package:acter/common/store/themes/SeperatedThemes.dart';
// import 'package:acter/controllers/todo_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class ToDoSubscriberScreen extends StatefulWidget {

//   const ToDoSubscriberScreen({Key? key}) : super(key: key);

//   @override
//   State<ToDoSubscriberScreen> createState() => _ToDoSubscriberScreenState();
// }

// class _ToDoSubscriberScreenState extends State<ToDoSubscriberScreen> {
//   bool allSelected = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: AppCommonTheme.backgroundColorLight,
//         leading: GestureDetector(
//           onTap: () {
//             Navigator.pop(context);
//           },
//           child: const Icon(
//             Icons.close,
//             color: Colors.white,
//             size: 24,
//           ),
//         ),
//         title: const Text(
//           'Subscriber',
//           style: TextStyle(color: Colors.white),
//         ),
//         centerTitle: true,
//         actions: [
//           Container(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               margin:
//                   const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
//               decoration: BoxDecoration(
//                   color: AppCommonTheme.primaryColor,
//                   borderRadius: BorderRadius.circular(8.0),),
//               child: Center(
//                 child: Text(
//                   'Save',
//                   style: ToDoTheme.buttonTextStyle
//                       .copyWith(color: ToDoTheme.primaryTextColor),
//                 ),
//               ),)
//         ],
//       ),
//       body: Padding(
//         padding: const EdgeInsets.fromLTRB(8.0, 16, 8, 16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal : 8.0),
//               child: Text(
//                 'No one will be notified when someone comments on this ToDo list',
//                 style: ToDoTheme.listTitleTextStyle.copyWith(
//                   fontSize: 16,
//                 ),
//               ),
//             ),
//             Row(
//               children: [
//                 Checkbox(
//                   value: allSelected,
//                   checkColor: Colors.white,
//                   activeColor: AppCommonTheme.secondaryColor,
//                   side: MaterialStateBorderSide.resolveWith(
//                     (states) => const BorderSide(
//                         width: 1.0, color: AppCommonTheme.secondaryColor,),
//                   ),
//                   onChanged: (newValue) {
//                   },
//                 ),
//                 Text('Select everyone',
//                     style: ToDoTheme.subtitleTextStyle
//                         .copyWith(color: AppCommonTheme.secondaryColor),),
//               ],
//             ),
//             GetBuilder<ToDoController>(
//               id: 'subscribeUser',
//               builder: (ToDoController controller) {
//                 return ListView.separated(
//                   shrinkWrap: true,
//                   itemBuilder: (context, index) {
//                     return ListTile(
//                       leading: const CircleAvatar(),
//                       title: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             controller.listSubscribers[index].name,
//                             style: ToDoTheme.listTitleTextStyle,
//                           ),
//                           const Text(
//                             'On this project',
//                             style: ToDoTheme.listSubtitleTextStyle,
//                           ),
//                         ],
//                       ),
//                       trailing: Checkbox(
//                         value: controller.listSubscribers[index].isSelected,
//                         checkColor: Colors.white,
//                         activeColor: AppCommonTheme.secondaryColor,
//                         side: MaterialStateBorderSide.resolveWith(
//                           (states) => const BorderSide(
//                               width: 1.0, color: AppCommonTheme.secondaryColor,),
//                         ),
//                         onChanged: (newValue) {
//                           setState(() {
//                             controller.handleCheckClick(index);
//                           });
//                         },
//                       ),
//                     );
//                   },
//                   separatorBuilder: (BuildContext context, int index) {
//                     return const Divider(
//                       indent: 8,
//                       endIndent: 8,
//                     );
//                   },
//                   itemCount: controller.listSubscribers.length,
//                 );
//               },
//             ),
//             const Padding(
//               padding: EdgeInsets.only(bottom: 22.0),
//               child: Divider(
//                 indent: 8,
//                 endIndent: 8,
//               ),
//             ),
//             Row(
//               children: [
//                 Radio(
//                   value: true,
//                   groupValue: true,
//                   fillColor: MaterialStateColor.resolveWith(
//                       (states) => AppCommonTheme.primaryColor,),
//                   onChanged: (value) {},
//                 ),
//                 Flexible(
//                   child: Text(
//                     'Notify new people on the all comment when posted as soon as possible.',
//                     style: ToDoTheme.listSubtitleTextStyle
//                         .copyWith(color: ToDoTheme.calendarColor),
//                   ),
//                 )
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
