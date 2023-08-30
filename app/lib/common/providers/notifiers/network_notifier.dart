import 'package:acter/common/utils/utils.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NetworkStateNotifier extends StateNotifier<NetworkStatus> {
  NetworkStateNotifier() : super(NetworkStatus.NotDetermined) {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      late NetworkStatus newState;
      if (result == ConnectivityResult.none) {
        newState = NetworkStatus.Off;
      } else if (result == ConnectivityResult.other) {
        newState = NetworkStatus.NotDetermined;
      } else {
        newState = NetworkStatus.On;
      }
      if (newState != state) {
        state = newState;
      }
    });
  }
}
