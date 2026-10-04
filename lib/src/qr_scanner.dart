import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeOverlay;

import 'barcode_overlay.dart';
import 'scan_gate.dart';

/// A full-screen QR scanner with a camera preview, torch control, camera
/// switching, and a result callback.
class QrScanner extends StatefulWidget {
  /// Creates a QR scanner screen.
  ///
  /// When [controller] is provided, this widget takes ownership of it and
  /// disposes it when the widget is disposed.
  const QrScanner({
    super.key,
    required this.onScan,
    this.title,
    this.overlay,
    this.backgroundColor,
    this.popOnScan = true,
    this.controller,
  });

  /// Called with the value of the first successfully scanned barcode.
  final ValueChanged<String> onScan;

  /// Title shown in the app bar.
  ///
  /// Defaults to `'Scan QR code'`.
  final String? title;

  /// Overlay drawn on top of the camera preview.
  ///
  /// Defaults to a red corner bracket overlay.
  final BarcodeOverlay? overlay;

  /// Background color of the scanner body.
  ///
  /// Defaults to [ThemeData.canvasColor].
  final Color? backgroundColor;

  /// Whether to pop the enclosing route after the first scan.
  final bool popOnScan;

  /// Controller used for the camera preview.
  ///
  /// When omitted, the widget creates and owns a controller. When provided,
  /// the widget takes ownership and disposes it.
  final MobileScannerController? controller;

  /// Creates the state for this scanner.
  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> with WidgetsBindingObserver {
  final ScanGate _scanGate = ScanGate();
  late final MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller =
        widget.controller ??
        MobileScannerController(
          autoStart: false,
          returnImage: false,
          detectionSpeed: DetectionSpeed.normal,
          formats: [BarcodeFormat.all],
        );
    _subscribe();
    unawaited(_controller.start());
  }

  void _subscribe() {
    _subscription = _controller.barcodes.listen(_handleBarcode);
  }

  void _handleBarcode(BarcodeCapture capture) {
    String? value;
    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        value = rawValue;
        break;
      }
    }
    if (value == null || !_scanGate.tryHandle()) {
      return;
    }
    unawaited(_subscription?.cancel());
    _subscription = null;
    widget.onScan(value);
    if (widget.popOnScan && mounted) {
      unawaited(Navigator.maybePop(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white70),
        backgroundColor: theme.canvasColor,
        title: Text(
          widget.title ?? 'Scan QR code',
          style:
              theme.textTheme.bodyLarge?.copyWith(color: Colors.white70) ??
              const TextStyle(color: Colors.white70),
        ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              final torchOn = _controller.value.torchState == TorchState.on;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    color: Colors.white,
                    icon: torchOn
                        ? const Icon(Icons.flash_off, color: Colors.white54)
                        : const Icon(Icons.flash_on, color: Colors.white),
                    iconSize: 32.0,
                    onPressed: () => _controller.toggleTorch(),
                  ),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(
                      Icons.flip_camera_android_sharp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    iconSize: 32.0,
                    onPressed: () => _controller.switchCamera(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Container(
        color: widget.backgroundColor ?? theme.canvasColor,
        child: Stack(
          children: [
            MobileScanner(controller: _controller),
            Container(
              decoration: ShapeDecoration(
                shape:
                    widget.overlay ??
                    BarcodeOverlay(
                      borderColor: Colors.red,
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 5,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        _subscribe();
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_controller.dispose());
    super.dispose();
  }
}
