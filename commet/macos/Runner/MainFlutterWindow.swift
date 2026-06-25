import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Dock unread badge. Dart sends the unread count; show it on the dock icon
    // (or clear it when zero).
    let dockChannel = FlutterMethodChannel(
      name: "chat.commet.commetapp/dock",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    dockChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "setBadgeCount":
        let count = call.arguments as? Int ?? 0
        NSApp.dockTile.badgeLabel = count > 0 ? String(count) : nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}
