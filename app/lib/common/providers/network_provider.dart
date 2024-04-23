import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkConnectivityProvider =
    StreamProvider<ConnectivityResult>((ref) async* {
  final con = Connectivity();
  yield await con.checkConnectivity();
  await for (final value in Connectivity().onConnectivityChanged) {
    yield value;
  }
});

// Network/Connectivity Providers
final hasNetworkProvider = StateProvider<bool>(
  (ref) => switch (ref.watch(networkConnectivityProvider).value) {
    ConnectivityResult.none || ConnectivityResult.other => false,
    _ => true,
  },
);
