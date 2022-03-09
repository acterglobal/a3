class ValidConstants {
  ValidConstants._();

  //PADDINGS
  static const double padding = 20;
  static const double avatarRadius = 45;

//TEXT FILED VALIDATIONS REGEX
  static bool isEmail(String em) {
    String p =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(p);
    return regExp.hasMatch(em);
  }

  static bool isUrl(String em) {
    String p = r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+';
    RegExp regExp = RegExp(p);
    return regExp.hasMatch(em);
  }

  static bool isYouTubeUrl(String em) {
    String p =
        r'^https:\/\/(?:www\.|m\.)?youtube\.com\/watch\?v=([_\-a-zA-Z0-9]{11}).*$';
    RegExp regExp = RegExp(p);
    return regExp.hasMatch(em);
  }
}

class Constant {
  static const List<String> gender = ['Male', 'Female', 'Other'];

  static const List<String> colleges = [
    'All Colleges',
    'Dream Colleges',
  ];

  static const List<String> visibily = [
    'Public',
    'Private',
  ];

  static const List<String> months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
}
