import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: constant_identifier_names
enum NetworkStatus { NotDetermined, On, Off }

final networkAwareProvider =
    StateNotifierProvider<NetworkStateNotifier, NetworkStatus>(
  (ref) => NetworkStateNotifier(),
);

class NetworkStateNotifier extends StateNotifier<NetworkStatus> {
  late NetworkStatus res;
  NetworkStateNotifier() : super(NetworkStatus.NotDetermined) {
    res = NetworkStatus.NotDetermined;
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      late NetworkStatus newState;
      switch (result) {
        case ConnectivityResult.mobile:
        case ConnectivityResult.wifi:
          newState = NetworkStatus.On;
          break;
        case ConnectivityResult.bluetooth:
        case ConnectivityResult.ethernet:
        case ConnectivityResult.other:
        case ConnectivityResult.vpn:
        case ConnectivityResult.none:
          newState = NetworkStatus.Off;
          break;
      }
      if (newState != state) {
        state = newState;
      }
    });
  }
}
