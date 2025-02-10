import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:acter/common/utils/routes.dart';
import 'package:acter/router/router.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

final _log = Logger('a3::config::desktop');
const appName = kDebugMode ? 'Acter-dev' : 'Acter';

class DesktopSupport extends StatefulWidget {
  final Widget child;

  const DesktopSupport({
    super.key,
    required this.child,
  });

  @override
  State<DesktopSupport> createState() => _DesktopSupportState();
}

class _DesktopSupportState extends State<DesktopSupport>
    with WindowListener, TrayListener {
  Timer? _saveCoordinatesFtr;
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
    windowManager.addListener(this);
    _initDesktop();
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  void saveCoords() {
    _saveCoordinatesFtr?.cancel();
    _saveCoordinatesFtr = Timer(Duration(seconds: 1), () async {
      final size = await windowManager.getSize();
      final pos = await windowManager.getPosition();
      final preferences = await sharedPrefs();
      await preferences.setDouble('windowX', pos.dx);
      await preferences.setDouble('windowY', pos.dy);
      await preferences.setDouble('windowHeight', size.height);
      await preferences.setDouble('windowWidth', size.width);

      _log.info(
        'stored window size to ${size.width}x${size.height} at (${pos.dx} | ${pos.dy})',
      );
    });
  }

  Future<void> _initDesktop() async {
    // Must add this line.
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      title: appName,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });

    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/icon/tray_icon.ico'
          : 'assets/icon/tray_icon.png',
    );
    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'search',
          label: 'Search',
        ),
        MenuItem(
          key: 'home',
          label: 'Home',
        ),
        MenuItem(
          key: 'chat',
          label: 'Chat',
        ),
        MenuItem(
          key: 'activities',
          label: 'Activities',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    if (!Platform.isMacOS) {
      // the menu crashes on macos if hidden for some reason.
      await trayManager.setContextMenu(menu);
    }
    if (!Platform.isLinux) {
      // not supported on linux;
      await trayManager.setToolTip(appName);
    }

    // Restore previous Window position and size
    final preferences = await sharedPrefs();
    final windowX = preferences.getDouble('windowX');
    final windowY = preferences.getDouble('windowY');
    final windowWidth = preferences.getDouble('windowWidth');
    final windowHeight = preferences.getDouble('windowHeight');
    _log.warning(
      'resetting window size to ${windowWidth}x$windowHeight at ($windowX | $windowY)"',
    );
    final displaySize = (await screenRetriever.getPrimaryDisplay()).size;
    // occupy at least 20% of screen size, even if the user made us smaller last time
    // so we do show up somewhere recognizable...
    final minWidth = displaySize.width / 5;
    final minHeight = displaySize.height / 5;
    if (windowHeight != null && windowWidth != null) {
      final newSize = Size(
        max(
          min(max(0, displaySize.width), windowWidth),
          minWidth, // minimum a quarter of the screen
        ),
        max(
          min(max(0, displaySize.height), windowHeight),
          minHeight, // minimum a quarter of the screen
        ),
      );
      windowManager.setSize(newSize);
    }
    if (windowX != null && windowY != null) {
      // ensure we are always on the visible part of the screen with at at least
      // minHeight & minWidth showing
      final offset = Offset(
        min(max(0, displaySize.width - minWidth), windowX),
        min(max(0, displaySize.height - minHeight), windowY),
      );
      windowManager.setPosition(offset);
    } else {
      windowManager.setPosition(Offset(minWidth, minHeight));
    }
  }

  @override
  void onWindowResize() => saveCoords(); // keep the size for later restoring
  @override
  void onWindowMove() => saveCoords(); // keep the size for later restoring

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    // toggle visiblity
    if (await windowManager.isVisible()) {
      _log.info('hiding window on toggle');
      await windowManager.hide();
    } else {
      _log.info('showing window on toggle');
      await windowManager.show();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    // do something
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == 'exit_app') {
      _log.info('exit app');
      await trayManager.destroy();
      await windowManager.destroy();
      return;
    }

    await windowManager.show();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) async {
      if (menuItem.key == 'search') {
        _log.info('route search');
        rootNavKey.currentContext!.pushNamed(Routes.search.name);
      } else if (menuItem.key == 'home') {
        _log.info('route home');
        rootNavKey.currentContext!.pushNamed(Routes.main.name);
      } else if (menuItem.key == 'chat') {
        _log.info('route chat');
        rootNavKey.currentContext!.pushNamed(Routes.chat.name);
      } else if (menuItem.key == 'activities') {
        _log.info('route activities');
        rootNavKey.currentContext!.pushNamed(Routes.activities.name);
      }
    });
  }
}
