import Cocoa
import FlutterMacOS
import app_links

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
        for window in NSApp.windows {
            if !window.isVisible {
                window.setIsVisible(true)
            }
            window.makeKeyAndOrderFront(self)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    return true
  }

  public override func application(_ application: NSApplication,
                                  continue userActivity: NSUserActivity,
                                  restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void) -> Bool {

    guard let url = AppLinks.shared.getUniversalLink(userActivity) else {
      return false
    }

    AppLinks.shared.handleLink(link: url.absoluteString)

    return false // Returning true will stop the propagation to other packages
  }
}
