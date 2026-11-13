import Foundation
import PDFKit

enum PdfDocumentCompressor {
  static func compress(source: String, target: String) throws -> Bool {
    let input = URL(fileURLWithPath: source)
    let output = URL(fileURLWithPath: target)
    guard input != output else { return false }
    let bytes = try Data(contentsOf: input, options: .mappedIfSafe)
    // Rewriting a digitally signed file would invalidate its signature.
    guard bytes.range(of: Data("/ByteRange".utf8)) == nil,
          let document = PDFDocument(url: input),
          !document.isEncrypted, !document.isLocked, document.pageCount > 0 else {
      return false
    }
    var options: [PDFDocumentWriteOption: Any] = [:]
    if #available(iOS 16.4, macOS 13.4, *) {
      options[.optimizeImagesForScreenOption] = true
    }
    guard document.write(to: output, withOptions: options),
          let result = PDFDocument(url: output),
          result.pageCount == document.pageCount else {
      try? FileManager.default.removeItem(at: output)
      return false
    }
    return true
  }
}
