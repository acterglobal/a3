import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

final desktopFeaturesProvider = StateProvider<bool>((ref) => false);

final launchAtStartupProvider = Provider<LaunchAtStartup>(
  (ref) => launchAtStartup,
);
