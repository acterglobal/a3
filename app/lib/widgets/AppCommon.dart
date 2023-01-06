import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/material.dart';

Widget navBarTitle(String title) {
  return Text(
    title,
    style: AppCommonTheme.appBarTitleStyle,
  );
}

void showNotYetImplementedMsg(BuildContext context, String message) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 1500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
      ),
    ),
  );
}

String? simplifyUserId(String name) {
  RegExp re = RegExp(r'^@(.*):\w+([\.-]?\w+)*(\.\w+)+$');
  RegExpMatch? m1 = re.firstMatch(name);
  if (m1 != null) {
    String? userId = m1.group(1);
    if (userId != null) {
      // replace symbol with string
      return userId.replaceAllMapped(RegExp(r'=([0-9a-fA-F]{2})'), (m2) {
        int charCode = int.parse('0x${m2.group(1)}');
        return String.fromCharCode(charCode);
      });
    }
  }
  return null;
}

String? simplifyRoomId(String name) {
  RegExp re = RegExp(r'^!(\w+([\.-]?\w+)*):\w+([\.-]?\w+)*(\.\w+)+$');
  RegExpMatch? match = re.firstMatch(name);
  if (match != null) {
    return match.group(1);
  }
  return null;
}

String simplifyBody(String formattedBody) {
  // strip out parent msg from reply msg
  RegExp re = RegExp(r'^<mx-reply>[\s\S]+</mx-reply>');
  return formattedBody.replaceAll(re, '');
}

String randomString() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}

Widget elevatedButton(
  String title,
  Color color,
  VoidCallback? callback,
  TextStyle textstyle,
) {
  return ElevatedButton(
    onPressed: callback,
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(title, style: textstyle),
  );
}

Widget noInternetWidget() {
  Size screenSize = WidgetsBinding.instance.window.physicalSize;
  bool isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  double width = screenSize.width;
  double height = screenSize.height;
  return Center(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Image.asset(
            'assets/images/no_internet.png',
            cacheHeight:
                isDesktop ? (height * 0.25).toInt() : (height * 0.10).toInt(),
            cacheWidth:
                isDesktop ? (width * 0.15).toInt() : (height * 0.10).toInt(),
            filterQuality: FilterQuality.high,
          ),
        ),
        const Text(
          'No internet\nPlease turn on internet to process',
          style: SideMenuAndProfileTheme.profileMenuStyle,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

int hexOfRGBA(int r, int g, int b, {double opacity = 1}) {
  r = (r < 0) ? -r : r;
  g = (g < 0) ? -g : g;
  b = (b < 0) ? -b : b;
  opacity = (opacity < 0) ? -opacity : opacity;
  opacity = (opacity > 1) ? 255 : opacity * 255;
  r = (r > 255) ? 255 : r;
  g = (g > 255) ? 255 : g;
  b = (b > 255) ? 255 : b;
  int a = opacity.toInt();
  return int.parse(
    '0x${a.toRadixString(16)}${r.toRadixString(16)}${g.toRadixString(16)}${b.toRadixString(16)}',
  );
}

bool isOnlyEmojis(String text) {
  final emojisRegExp = RegExp(
    r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
  );
  // find all emojis
  final emojis = emojisRegExp.allMatches(text);

  // return if none found
  if (emojis.isEmpty) return false;

  // remove all emojis from the this
  for (final emoji in emojis) {
    text = text.replaceAll(emoji.input.substring(emoji.start, emoji.end), '');
  }

  // remove all whitespace (optional)
  text = text.replaceAll('', '');

  // return true if nothing else left
  return text.isEmpty;
}
