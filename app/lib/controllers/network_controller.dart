import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:effektio/common/store/themes/SeperatedThemes.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons_null_safety/flutter_icons_null_safety.dart';
import 'package:get/get.dart';
import 'package:overlay_support/overlay_support.dart';

class NetworkController extends GetxController {
  static NetworkController to = Get.find();

  var connectionType = 0.obs;
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _streamSubscription;

  @override
  void onInit() {
    super.onInit();
    _getConnectionType();
    _streamSubscription =
        _connectivity.onConnectivityChanged.listen(_updateState);
  }

  Future<void> _getConnectionType() async {
    ConnectivityResult? connectivityResult;
    try {
      connectivityResult = await (_connectivity.checkConnectivity());
    } on PlatformException catch (e) {
      debugPrint(e.toString());
    }
    return _updateState(connectivityResult!);
  }

  void _updateState(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType.value = 1;
        break;
      case  ConnectivityResult.mobile:
        connectionType.value = 2;
        break;
      case ConnectivityResult.none:
        connectionType.value = 0;
        _showNoInternetNotification();
        break;
      default:
        _showNoInternetNotification();
    }
  }

  OverlaySupportEntry _showNoInternetNotification(){

    return showSimpleNotification(
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            FlutterIcons.loader_fea, color: NotificationPopUpTheme.networkTextColor,
          ),
          SizedBox(
            width: 12,
          ),
          Text(
            'Network connectivity limited or unavailable',
            style: NotificationPopUpTheme.networkTitleStyle,
          ),
        ],
      ),
      background: NotificationPopUpTheme.networkBackgroundColor,
      slideDismissDirection: DismissDirection.up,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
    super.onClose();
  }
}
