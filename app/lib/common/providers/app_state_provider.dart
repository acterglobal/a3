import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appStateProvider = StateProvider<AppLifecycleState>(
  (ref) => AppLifecycleState.resumed,
);

final isAppInForeground = StateProvider<bool>(
  (ref) =>
      ref.watch(appStateProvider) ==
      AppLifecycleState.resumed, // this means we are running
);
