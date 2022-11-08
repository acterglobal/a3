import 'package:flutter/material.dart';
import 'package:themed/themed.dart';

class AppCommonTheme {
  static const primaryColor = ColorRef(Color(0xffEC2758));
  static const secondaryColor = ColorRef(Color(0xff23AFC2));
  static const tertiaryColor = ColorRef(Color(0xff5C2A80));
  static const backgroundColor = ColorRef(Color.fromRGBO(36, 38, 50, 1));
  static const backgroundColorLight = ColorRef(Color(0xff333540), id: 'CIBC');
  static const svgIconColor = ColorRef(Colors.white, id: 'NavBar');
  static const textFieldColor = ColorRef(Color(0xff171717));
  static const darkShade = ColorRef(Color(0xff333540));
  static const greenButtonColor = ColorRef(Color(0xff33C481));
  static const dividerColor = ColorRef(Colors.grey);
  static const transparentColor = ColorRef(Colors.transparent);
  static const appBarTitleColor = ColorRef(Colors.white, id: 'ABT');

  static const appBarTitleStyle = TextStyleRef(
    TextStyleRef(
      TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: appBarTitleColor,
      ),
    ),
  );
}

class SideMenuAndProfileTheme {
  static const sideMenuTextColor = ColorRef(Color.fromRGBO(196, 196, 196, 1));
  static const sideMenuTextColorDisabled =
      ColorRef(Color.fromRGBO(196, 196, 196, 0.4));
  static const sideMenuProfileTextColor =
      ColorRef(Color.fromRGBO(229, 229, 229, 1));
  static const profileBodyTextColor = ColorRef(Colors.white, id: 'PBT');
  static const profileNameTextColor = ColorRef(Colors.black, id: 'PNT');
  static const profileUserIdTextColor = ColorRef(Colors.grey, id: 'PUIT');

  static const sideMenuStyle = TextStyleRef(
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: sideMenuTextColor,
    ),
  );

  static const sideMenuStyleDisabled = TextStyleRef(
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: sideMenuTextColorDisabled,
    ),
  );
  static const sideMenuProfileStyle = TextStyleRef(
    TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: sideMenuProfileTextColor,
    ),
  );

  static const profileMenuStyle = TextStyleRef(
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: profileBodyTextColor,
    ),
  );

  static const profileNameStyle = TextStyleRef(
    TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: profileNameTextColor,
    ),
  );

  static const profileUserIdStyle = TextStyleRef(
    TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: profileUserIdTextColor,
    ),
  );

  static const signOutText = TextStyleRef(
    TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppCommonTheme.primaryColor,
    ),
  );
}

class AuthTheme {
  static const authTextColor = ColorRef(Colors.white, id: 'AT');
  static const hintTextColor = ColorRef(Colors.grey, id: 'HT');
  static const textFieldTextColor = ColorRef(Colors.white, id: 'TFT');
  static const forgotPasswordColor = ColorRef(Color(0xff008080), id: 'FP');
  static const authSuccess = ColorRef(Colors.greenAccent, id: 'AS');
  static const authFailed = ColorRef(Colors.redAccent, id: 'AF');

  static const authTitleStyle = TextStyleRef(
    TextStyle(
      fontSize: 25,
      fontWeight: FontWeight.w700,
      color: authTextColor,
    ),
  );

  static const authBodyStyle = TextStyleRef(
    TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: authTextColor,
    ),
  );
}

class ChatTheme01 {
  static const chatListTextColor = ColorRef(Colors.white, id: 'CLT');
  static const latestChatTextColor = ColorRef(Colors.white, id: 'LCT');
  static const chatBodyTextColor = ColorRef(Colors.white, id: 'CBT');
  static const leaveBtnBg = ColorRef(Color(0xff594848));
  static const redText = ColorRef(Color(0xffFF4B4B));
  static const chatInputTextColor = ColorRef(Colors.white, id: 'CITXC');
  static const chatSelectedImageBorderColor = ColorRef(Color(0xff23AFC2));

  static const chatTitleStyle = TextStyleRef(
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: chatListTextColor,
    ),
  );

  static const chatInputPlaceholderStyle = TextStyleRef(
    TextStyle(
      fontSize: 18,
      color: ColorRef(
        Color.fromARGB(255, 103, 104, 107),
      ),
    ),
  );

  static const chatProfileTitleStyle = TextStyleRef(
    TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: chatListTextColor,
    ),
  );

  static const latestChatStyle = TextStyleRef(
    TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: latestChatTextColor,
    ),
  );

  static const latestChatDateStyle = TextStyleRef(
    TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: latestChatTextColor,
    ),
  );

  static const chatBodyStyle = TextStyleRef(
    TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: chatBodyTextColor,
    ),
  );

  static const emptyMsgTitle = TextStyleRef(
    TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w500,
      color: chatBodyTextColor,
    ),
  );
}

class FAQTheme {
  static const faqTitleColor =
      ColorRef(Color.fromRGBO(254, 254, 254, 1), id: 'FT');
  static const faqTeamColor = ColorRef(Colors.white, id: 'FT0');
  static const faqCardColor = ColorRef(Color.fromRGBO(47, 49, 62, 1));
  static const faqOutlineBorderColor = ColorRef(Color.fromRGBO(90, 90, 90, 1));

  static const uxColor = ColorRef(Color(0xFF7879F1));
  static const importantColor = ColorRef(Color(0xFF23AFC2));
  static const infoColor = ColorRef(Color(0xFFFA8E10));
  static const supportColor = ColorRef(Color(0xFFB8FFDD));

  static const titleStyle = TextStyleRef(
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: faqTitleColor,
    ),
  );

  static const teamNameStyle = TextStyleRef(
    TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: faqTeamColor,
    ),
  );

  static const likeAndCommentStyle = TextStyleRef(
    TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      color: faqTitleColor,
    ),
  );

  static const lableStyle = TextStyleRef(
    TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );
}

class NotificationTheme {
  static const notificationTextColor = ColorRef(Colors.white, id: 'NT');
  static const notificationcardColor = ColorRef(AppCommonTheme.primaryColor);

  static const titleStyle = TextStyleRef(
    TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: notificationTextColor,
    ),
  );

  static const subTitleStyle = TextStyleRef(
    TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: notificationTextColor,
    ),
  );
}

class CrossSigningSheetTheme {
  static const backgroundColor = ColorRef(Color(0xff333540));
  static const primaryTextColor = ColorRef(Colors.white, id: 'ABT');
  static const secondaryTextColor = ColorRef(Colors.grey);
  static const greenButtonColor = ColorRef(Color(0xff33C481));
  static const redButtonColor = ColorRef(Color(0xffEC2758));
  static const gridBackgroundColor = ColorRef(Color.fromRGBO(36, 38, 50, 1));
  static const loadingIndicatorColor = ColorRef(Colors.grey);

  static const primaryTextStyle = TextStyleRef(
    TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: primaryTextColor,
    ),
  );

  static const secondaryTextStyle = TextStyleRef(
    TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: secondaryTextColor,
    ),
  );

  static const buttonTextStyle = TextStyleRef(
    TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: primaryTextColor,
    ),
  );
}

class ToDoTheme {
  // Color Scheme.
  static const activeCheckColor = ColorRef(Color(0xFF1CF18F));
  static const assignedIconColor = ColorRef(Color(0xFFFF9292));
  static const backgroundGradientColor = ColorRef(Color(0xFF242632));
  static const backgroundGradient2Color = ColorRef(Color(0xFF2C5156));
  static const bottomSheetColor = ColorRef(Color(0xFF333540));
  static const bottomSheetDividerColor = ColorRef(Color(0xFF4A4A4A));
  static const secondaryCardColor = ColorRef(Color(0xFF3F404B));
  static const btnBorderColor = ColorRef(Color(0xFF484C4F));
  static const calendarColor = ColorRef(Color(0xFFC4C4C4));
  static const dividerColor = ColorRef(Color(0xFF343A43));
  static const floatingABColor = ColorRef(Color(0xFF23AFC2));
  static const inactiveCheckColor = ColorRef(Color(0xFF50555C));
  static const infoAvatarColor = ColorRef(Color(0xFF50555C));
  static const inactiveTextColor = ColorRef(Color(0xFFC4C4C4));
  static const listDividerColor = ColorRef(Color(0xFF4A4A4A));
  static const lastUpdatedColor = ColorRef(Color(0xFFE5E5E5));
  static const primaryColor = ColorRef(Color(0xFFEC2758));
  static const primaryTextColor = ColorRef(Color(0xFFFFFFFF));
  static const plannedIconColor = ColorRef(Color(0xFFDBFFDE));
  static const removeColor = ColorRef(Color(0xFFE04C4C));
  static const roleNameColor = ColorRef(Color(0xFFC4C4C4));
  static const secondaryColor = ColorRef(Color(0xFF333540));
  static const secondaryTextColor = ColorRef(Color(0xFFEC2758));
  static const subscribedIconColor = ColorRef(Color(0xFFFCE5E5));
  static const taskIconColor = ColorRef(Color(0xFFEAD0FF));
  static const todayCalendarColor = ColorRef(Color(0xFF23AFC2));
  static const unAssignedIconColor = ColorRef(Color(0xFFFFE9C9));

  // Text Scheme.
  static const titleTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 25,
    fontWeight: FontWeight.w700,
  );

  static const subtitleTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const listTitleTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const listSubtitleTextStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const taskTitleTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  static const taskSubtitleTextStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const calendarTextStyle = TextStyle(
    color: calendarColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const buttonTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const todayCalendarTextStyle = TextStyle(
    color: todayCalendarColor,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const taskListTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const addTaskTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const infoAvatarTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 9,
    fontWeight: FontWeight.w500,
  );

  static const activeTasksTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static const roleTextStyle = TextStyle(
    color: floatingABColor,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const roleNameTextStyle = TextStyle(
    color: roleNameColor,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static const listMemberTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 15,
    fontWeight: FontWeight.w500,
  );

  // Background Scheme.
  static const toDoDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: FractionalOffset(0.5, 0.3),
      end: Alignment.topCenter,
      colors: [
        ToDoTheme.backgroundGradientColor,
        ToDoTheme.backgroundGradient2Color
      ],
    ),
  );
}

class PinsTheme {
  // Color Scheme.
  static const backgroundGradientColor = ColorRef(Color(0xFF242632));
  static const backgroundGradient2Color = ColorRef(Color(0x885C2A80));
  static const primaryTextColor = Color.fromARGB(255, 255, 255, 255);

  // Text Scheme.
  // Background Scheme.
  static const pinsDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: FractionalOffset(0.5, 0.3),
      end: Alignment.topCenter,
      colors: [
        PinsTheme.backgroundGradientColor,
        PinsTheme.backgroundGradient2Color
      ],
    ),
  );

  // Text Scheme.
  static const titleTextStyle = TextStyle(
    color: primaryTextColor,
    fontSize: 25,
    fontWeight: FontWeight.w700,
  );
}
