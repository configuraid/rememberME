import UIKit
import Flutter
import SwiftUI

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    // Stored result callback for onboarding completion
    private var onboardingResult: FlutterResult?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        
        // MARK: - Onboarding MethodChannel
        let controller = window?.rootViewController as! FlutterViewController
        let onboardingChannel = FlutterMethodChannel(
            name: "com.rememberme/onboarding",
            binaryMessenger: controller.binaryMessenger
        )
        
        onboardingChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "showOnboarding":
                self?.showNativeOnboarding(
                    controller: controller,
                    arguments: call.arguments as? [String: Any],
                    result: result
                )
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    // MARK: - Native Onboarding Presentation
    private func showNativeOnboarding(
        controller: FlutterViewController,
        arguments: [String: Any]?,
        result: @escaping FlutterResult
    ) {
        if #available(iOS 26.0, *) {
            self.onboardingResult = result
            
            DispatchQueue.main.async {
                let items: [iOS26StyleOnBoarding.Item] = [
                    .init(
                        id: 0,
                        title: "Willkommen bei RememberMe",
                        subtitle: "Erstellen Sie eine digitale Gedenkseite\nfür Ihre Liebsten – mit einem QR-Code.",
                        screenshot: UIImage(named: "Screen"),
                        linkURL: URL(string: "https://www.google.com"),
                        linkTitle: "QR-Code bestellen"
                    ),
                    .init(
                        id: 1,
                        title: "Registrieren & Scannen",
                        subtitle: "Erstellen Sie Ihr Konto und scannen\nSie Ihren QR-Code, um loszulegen.",
                        videoName: "Step2"
                    ),    .init(
                        id: 2,
                        title: "Gedenkseite erstellen",
                        subtitle: "Laden Sie ein Foto und einen Namen hoch –\nden Rest gestalten Sie ganz nach Ihren Wünschen.",
                        videoName: "Step3"
                    ),
                   /* .init(
                        id: 2,
                        title: "Gedenkseite gestalten",
                        subtitle: "Fügen Sie Fotos, Videos, den Lebenslauf\nund persönliche Geschichten hinzu.",
                        screenshot: UIImage(named: "Screen"),
                        zoomScale: 1.3,
                        zoomAnchor: .bottom
                    ),*/
                    .init(
                        id: 3,
                        title: "Ihre Erinnerung, Ihre Geschichte",
                        subtitle: "Gestalten Sie ein einzigartiges\nAndenken für Ihre Liebsten.",
                        screenshot: UIImage(named: "Screen2"),
                        zoomScale: 1.2,
                        zoomAnchor: .init(x: 0.5, y: -0.1)
                    ),
                ]

                let onboardingView = iOS26StyleOnBoarding(
                    tint: Color(red: 0x7E/255, green: 0x68/255, blue: 0x57/255),
                    items: items,
                    hideBezels: true,
                    onSkip: { [weak self] in
                        controller.dismiss(animated: true) {
                            self?.onboardingResult?(true)
                            self?.onboardingResult = nil
                        }
                    }
                ) { [weak self] in
                    controller.dismiss(animated: true) {
                        self?.onboardingResult?(true)
                        self?.onboardingResult = nil
                    }
                }
                
                let hostingController = UIHostingController(rootView: onboardingView)
                hostingController.modalPresentationStyle = .fullScreen
                controller.present(hostingController, animated: true)
            }
        } else {
            // Ältere iOS-Versionen: Onboarding überspringen
            result(true)
        }
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
