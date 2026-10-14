import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans barcodes from image files.
///
/// Image analysis works on Android, physical iOS devices, and macOS.
/// Unsupported platforms throw an [UnsupportedError]. The iOS Simulator does
/// not support image analysis.
class QrImageScanner {
  const QrImageScanner._();

  /// Scans the image file at [path] and returns the first non-empty value.
  ///
  /// The method creates its own controller and disposes it after the scan.
  /// A running camera scan keeps its state.
  ///
  /// Returns `null` when the image holds no barcode.
  static Future<String?> scanImageFile(String path) async {
    final controller = MobileScannerController(autoStart: false);
    try {
      final capture = await controller.analyzeImage(path);
      if (capture == null) {
        return null;
      }
      for (final barcode in capture.barcodes) {
        final rawValue = barcode.rawValue;
        if (rawValue != null && rawValue.isNotEmpty) {
          return rawValue;
        }
      }
      return null;
    } finally {
      await controller.dispose();
    }
  }
}
