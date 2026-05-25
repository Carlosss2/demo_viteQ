import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.example.app_demo/fake_gps",
      binaryMessenger: engineBridge.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "isMockLocationEnabled" {
        result(self?.isMockLocationEnabled() ?? false)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func isMockLocationEnabled() -> Bool {
    #if targetEnvironment(simulator)
      return true
    #else
      return false
    #endif
  }
}
