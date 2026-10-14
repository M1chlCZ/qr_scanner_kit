import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A fake [MobileScannerPlatform] that records calls and emits barcodes.
///
/// Install it with `MobileScannerPlatform.instance = FakeMobileScannerPlatform()`.
class FakeMobileScannerPlatform extends MobileScannerPlatform {
  final StreamController<BarcodeCapture?> _barcodes =
      StreamController<BarcodeCapture?>.broadcast();
  final StreamController<TorchState> _torchStates =
      StreamController<TorchState>.broadcast();
  final StreamController<double> _zoomScales =
      StreamController<double>.broadcast();

  /// The start options of every `start` call.
  final List<StartOptions> startCalls = [];

  /// The file paths of every `analyzeImage` call.
  final List<String> analyzePaths = [];

  /// The capture that `analyzeImage` returns.
  BarcodeCapture? analyzeResult;

  /// The error that `analyzeImage` throws.
  Object? analyzeError;

  /// The number of `stop` calls.
  int stopCount = 0;

  /// The number of `dispose` calls.
  int disposeCount = 0;

  /// The barcode stream of this fake platform.
  @override
  Stream<BarcodeCapture?> get barcodesStream => _barcodes.stream;

  /// The torch state stream of this fake platform.
  @override
  Stream<TorchState> get torchStateStream => _torchStates.stream;

  /// The zoom scale stream of this fake platform.
  @override
  Stream<double> get zoomScaleStateStream => _zoomScales.stream;

  /// Records the call and returns [analyzeResult] or throws [analyzeError].
  @override
  Future<BarcodeCapture?> analyzeImage(
    String path, {
    List<BarcodeFormat> formats = const <BarcodeFormat>[],
  }) async {
    analyzePaths.add(path);
    final error = analyzeError;
    if (error != null) {
      throw error;
    }
    return analyzeResult;
  }

  /// Returns an empty placeholder for the camera view.
  @override
  Widget buildCameraView() => const SizedBox.shrink();

  /// Records the start options and reports a running camera.
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    startCalls.add(startOptions);
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.off,
      size: Size(640, 480),
      numberOfCameras: 2,
    );
  }

  /// Counts one stop call.
  @override
  Future<void> stop() async {
    stopCount += 1;
  }

  /// Counts one dispose call.
  @override
  Future<void> dispose() async {
    disposeCount += 1;
  }

  /// Emits a capture with one barcode that holds [value].
  void emitValue(String? value) {
    _barcodes.add(BarcodeCapture(barcodes: [Barcode(rawValue: value)]));
  }

  /// Emits the given [capture].
  void emitCapture(BarcodeCapture capture) {
    _barcodes.add(capture);
  }

  /// Closes the internal streams.
  Future<void> close() async {
    await _barcodes.close();
    await _torchStates.close();
    await _zoomScales.close();
  }
}
