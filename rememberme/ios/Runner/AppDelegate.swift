import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // MARK: - Universal Links Handler
  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
       let url = userActivity.webpageURL {
      print("🔗 AppDelegate: Universal Link received: \(url)")
      
      // Delegiere an Flutter
      _ = super.application(application, continue: userActivity, restorationHandler: restorationHandler)
      
      // IMMER true zurückgeben um Safari zu verhindern!
      return true
    }
    
    return super.application(application, continue: userActivity, restorationHandler: restorationHandler)
  }
}
