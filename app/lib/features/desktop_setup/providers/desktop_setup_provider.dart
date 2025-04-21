import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

class DesktopSetupNotifier extends StateNotifier<bool> {
  final LaunchAtStartup _launchAtStartup;

  DesktopSetupNotifier([LaunchAtStartup? launchAtStartup])
      : _launchAtStartup = launchAtStartup ?? LaunchAtStartup.instance,
        super(false) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = await _launchAtStartup.isEnabled();
  }

  Future<void> toggleLaunchAtStartup(bool enable) async {
    // Update state immediately for UI responsiveness
    state = enable;
    
    // Then perform the actual operation
    if (enable) {
      await _launchAtStartup.enable();
    } else {
      await _launchAtStartup.disable();
    }
  }
}

final desktopSetupNotifierProvider =
    StateNotifierProvider<DesktopSetupNotifier, bool>(
  (ref) => DesktopSetupNotifier(),
); 