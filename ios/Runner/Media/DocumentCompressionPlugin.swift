import Flutter
import Foundation

final class DocumentCompressionPlugin: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "hywork/document_compression", binaryMessenger: registrar.messenger()
    )
    registrar.addMethodCallDelegate(DocumentCompressionPlugin(), channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "compressPdf" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard let arguments = call.arguments as? [String: String],
          let source = arguments["source"], let target = arguments["target"] else {
      result(FlutterError(code: "invalid_arguments", message: "Missing PDF paths", details: nil))
      return
    }
    DispatchQueue.global(qos: .utility).async {
      do {
        let compressed = try PdfDocumentCompressor.compress(source: source, target: target)
        DispatchQueue.main.async { result(compressed) }
      } catch {
        DispatchQueue.main.async {
          result(FlutterError(code: "pdf_compression_failed", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}
