import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkConnectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
  final con = Connectivity();
  yield await con.checkConnectivity();
  await for (final value in con.onConnectivityChanged) {
    yield value;
  }
});

// Network/Connectivity Providers
final hasNetworkProvider = StateProvider<bool>((ref) {
  final val = ref.watch(networkConnectivityProvider).valueOrNull ?? [];
  return !val.contains(ConnectivityResult.none);
});

// Network/Connectivity Providers
final hasWifiNetworkProvider = StateProvider<bool>((ref) {
  final val = ref.watch(networkConnectivityProvider).valueOrNull ?? [];
  return val.contains(ConnectivityResult.wifi);
});
