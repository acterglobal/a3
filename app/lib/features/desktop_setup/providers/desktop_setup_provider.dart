import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

class DesktopSetupNotifier extends StateNotifier<bool> {
  DesktopSetupNotifier() : super(false) {
    _initialize();
  }

  Future<void> _initialize() async {
    final launchAtStartup = LaunchAtStartup.instance;
    state = await launchAtStartup.isEnabled();
  }

  Future<void> toggleLaunchAtStartup(bool enable) async {
    // Update state immediately for UI responsiveness
    state = enable;
    
    // Then perform the actual operation
    final launchAtStartup = LaunchAtStartup.instance;
    if (enable) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }
}

final desktopSetupNotifierProvider =
    StateNotifierProvider<DesktopSetupNotifier, bool>(
  (ref) => DesktopSetupNotifier(),
); 