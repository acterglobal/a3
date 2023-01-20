import 'package:beamer/beamer.dart';
import 'package:effektio/main.dart';
import 'package:effektio/models/ChatModel.dart';
import 'package:effektio/models/ChatProfileModel.dart';
import 'package:effektio/models/EditGroupInfoModel.dart';
import 'package:effektio/models/FaqModel.dart';
import 'package:effektio/models/ImageSelectionModel.dart';
import 'package:effektio/models/RequestScreenModel.dart';
import 'package:effektio/models/TodoTaskEditorModel.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatProfile.dart';
import 'package:effektio/screens/HomeScreens/chat/ChatScreen.dart';
import 'package:effektio/screens/HomeScreens/chat/EditGroupInfo.dart';
import 'package:effektio/screens/HomeScreens/chat/GroupLinkScreen.dart';
import 'package:effektio/screens/HomeScreens/chat/ImageSelectionScreen.dart';
import 'package:effektio/screens/HomeScreens/chat/ReqAndInvites.dart';
import 'package:effektio/screens/HomeScreens/chat/RoomLinkSetting.dart';
import 'package:effektio/screens/HomeScreens/faq/Item.dart';
import 'package:effektio/screens/HomeScreens/todo/AddToDo.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDo.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDoTaskAssign.dart';
import 'package:effektio/screens/HomeScreens/todo/ToDoTaskEditor.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/CommentsScreen.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/CreateTask.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/MyAssignments.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/MyRecentActivity.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/SubscriberScreen.dart';
import 'package:effektio/screens/HomeScreens/todo/screens/ToDoBookmarks.dart';
import 'package:effektio/screens/OnboardingScreens/LogIn.dart';
import 'package:effektio/screens/OnboardingScreens/Signup.dart';
import 'package:effektio/screens/SideMenuScreens/Gallery.dart';
import 'package:effektio/screens/UserScreens/SocialProfile.dart';
import 'package:effektio_flutter_sdk/effektio_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';

class Routes {
  static RoutesLocationBuilder getRoutes(){
    return RoutesLocationBuilder(
      routes: {
        '/': (context, state, data) => const EffektioHome(),
        '/login': (context, state, data) => const LoginScreen(),
        '/profile': (context, state, data) => const SocialProfileScreen(),
        '/signup': (context, state, data) => const SignupScreen(),
        '/gallery': (context, state, data) => const GalleryScreen(),
        '/todo': (context, state, data) => const ToDoScreen(),
        '/addTodo': (context, state, data) => const AddToDoScreen(),
        '/createTask' : (context, state, data) => const CreateTaskScreen(),
        '/groupLink' : (context, state, data) => const GroupLinkScreen(),
        '/myAssignment' : (context, state, data) => const MyAssignmentScreen(),
        '/todoBookmarks' : (context, state, data) => const ToDoBookmarkScreen(),
        '/myRecentActivity' : (context, state, data) => const MyRecentActivityScreen(),
        '/todoComment' : (context, state, data) => const ToDoCommentScreen(),
        '/todoSubscriber' : (context, state, data) => const ToDoSubscriberScreen(),
        '/faqListItem' : (context, state, data) {
          return FaqItemScreen(faqModel : (data as FaqModel),);
        },
        '/todoTaskEditor' : (context, state, data) {
          return ToDoTaskEditor(todoTaskEditorModel: (data as TodoTaskEditorModel),);
        },
        '/chat' : (context, state, data) {
          return ChatScreen( chatModel: (data as ChatModel),);
        },
        '/imageSelection' : (context, state, data) {
          return ImageSelection(imageSelectionModel: (data as ImageSelectionModel),);
        },
        '/todoTaskAssign' : (context, state, data) {
          return ToDoTaskAssignScreen(avatars : (data as List<ImageProvider<Object>>),);
        },
        '/roomLinkSettings' : (context, state, data) {
          return RoomLinkSettingsScreen(room : (data as Conversation),);
        },
        '/editGroupInfoScreen' : (context, state, data) {
          return EditGroupInfoScreen(editGroupInfoModel: (data as EditGroupInfoModel),);
        },
        '/requestScreen' : (context, state, data) {
          return RequestScreen(requestScreenModel: (data as RequestScreenModel),);
        },
        '/chatProfile' : (context, state, data) {
          return ChatProfileScreen(chatProfileModel: (data as ChatProfileModel),);
        },
      },
    );
  }
}