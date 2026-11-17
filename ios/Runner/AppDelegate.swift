import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var installationChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DocumentCompressionPlugin") {
      DocumentCompressionPlugin.register(with: registrar)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "InstallationIdentity") {
      installationChannel = FlutterMethodChannel(
        name: "hywork/installation", binaryMessenger: registrar.messenger()
      )
      installationChannel?.setMethodCallHandler { call, result in
        guard call.method == "getInstallationId" else {
          result(FlutterMethodNotImplemented)
          return
        }
        do {
          result(try Self.installationId())
        } catch {
          result(FlutterError(
            code: "installation_unavailable",
            message: "Could not read installation identity.", details: nil
          ))
        }
      }
    }
  }

  private static func installationId() throws -> String {
    let manager = FileManager.default
    var directory = try manager.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true
    ).appendingPathComponent("HyworkInstallation", isDirectory: true)
    try manager.createDirectory(at: directory, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try directory.setResourceValues(values)
    let marker = directory.appendingPathComponent("auth_installation")
    if manager.fileExists(atPath: marker.path) {
      let id = try String(contentsOf: marker, encoding: .utf8)
      guard UUID(uuidString: id) != nil else {
        throw CocoaError(.fileReadCorruptFile)
      }
      return id
    }
    let id = UUID().uuidString
    try Data(id.utf8).write(to: marker, options: .atomic)
    return id
  }
}
