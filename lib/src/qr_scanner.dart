import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeOverlay;

import 'barcode_overlay.dart';
import 'scan_deduper.dart';
import 'scan_gate.dart';

/// A full-screen QR scanner with a camera preview, torch control, camera
/// switching, and a result callback.
class QrScanner extends StatefulWidget {
  /// Creates a QR scanner screen.
  ///
  /// When you provide [controller], the widget respects its `autoStart`
  /// setting and manages lifecycle start/stop. The widget takes ownership of
  /// the controller and disposes it when the widget is disposed.
  const QrScanner({
    super.key,
    required this.onScan,
    this.title,
    this.overlay,
    this.backgroundColor,
    this.popOnScan = true,
    this.controller,
    this.formats,
    this.hapticsEnabled = true,
    this.isAccepted,
    this.onRejected,
    this.continuous = false,
    this.duplicateWindow = const Duration(seconds: 2),
    this.hint,
    this.hintStyle,
    this.scanWindow,
    this.errorBuilder,
  });

  /// Receives the value of the first successfully scanned barcode.
  ///
  /// Runs at most once per widget lifetime and reports only the first
  /// successfully decoded non-empty barcode.
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
  ///
  /// When false, the screen stays open after the first scan but does not
  /// report further barcodes.
  final bool popOnScan;

  /// Controller for the camera preview.
  ///
  /// When omitted, the widget creates and owns a controller. When you provide
  /// one, the widget respects its `autoStart` setting and manages lifecycle
  /// start/stop. The widget takes ownership of the controller and disposes it
  /// when the widget is disposed.
  final MobileScannerController? controller;

  /// The barcode formats that the scanner detects.
  ///
  /// The widget passes this list to the internally created controller. When
  /// this is null, the scanner detects all formats. An injected [controller]
  /// keeps its own formats, so this parameter has no effect then.
  final List<BarcodeFormat>? formats;

  /// Whether the scanner plays a light haptic impact when it accepts a code.
  ///
  /// Defaults to `true`.
  final bool hapticsEnabled;

  /// Decides whether the scanner accepts a scanned value.
  ///
  /// The scanner checks this function before the one-shot gate. A rejected
  /// value consumes no scan attempt, fires no haptics, and calls no [onScan].
  /// The scanner then waits for the next code. When this is null, the scanner
  /// accepts every non-empty value.
  final bool Function(String value)? isAccepted;

  /// Receives every scanned value that [isAccepted] rejects.
  final void Function(String value)? onRejected;

  /// Whether the scanner keeps running after a successful scan.
  ///
  /// When true, the scanner reports every accepted code and never pops. When
  /// false (the default), it reports the first accepted code and stops.
  final bool continuous;

  /// Minimum time between two reports of the same code.
  ///
  /// Only continuous mode uses this window. Repeated captures of one code
  /// inside the window are ignored, so a barcode held in front of the camera
  /// does not flood [onScan].
  final Duration duplicateWindow;

  /// Short instruction drawn over the camera preview.
  final String? hint;

  /// Text style of [hint].
  ///
  /// Defaults to the body text style in `Colors.white70`.
  final TextStyle? hintStyle;

  /// Restricts detection to this rectangle of the preview.
  ///
  /// The rectangle uses the widget coordinate space. `null` scans the whole
  /// preview. The web platform does not support a scan window.
  final Rect? scanWindow;

  /// Builds the view shown when the camera fails to start.
  ///
  /// When `null`, the widget shows a short explanation and a retry button.
  final Widget Function(BuildContext, MobileScannerException)? errorBuilder;

  /// Creates the state for this scanner.
  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> with WidgetsBindingObserver {
  final ScanGate _scanGate = ScanGate();
  late ScanDeduper _deduper;
  late final MobileScannerController _controller;
  StreamSubscription<BarcodeCapture>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _deduper = ScanDeduper(window: widget.duplicateWindow);
    _controller =
        widget.controller ??
        MobileScannerController(
          autoStart: false,
          returnImage: false,
          detectionSpeed: DetectionSpeed.normal,
          formats: widget.formats ?? const [BarcodeFormat.all],
        );
    _subscribe();
    if (!_controller.autoStart) {
      _startScanner();
    }
  }

  @override
  void didUpdateWidget(QrScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duplicateWindow != widget.duplicateWindow) {
      _deduper = ScanDeduper(window: widget.duplicateWindow);
    }
  }

  void _subscribe() {
    _subscription = _controller.barcodes.listen(_handleBarcode);
  }

  void _startScanner() {
    if (_controller.value.isStarting || _controller.value.isRunning) {
      return;
    }
    _ignoreErrors(_controller.start());
  }

  void _ignoreErrors(Future<void> future) {
    unawaited(future.onError((Object _, StackTrace _) {}));
  }

  void _handleBarcode(BarcodeCapture capture) {
    final values = <String>[
      for (final barcode in capture.barcodes)
        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty)
          barcode.rawValue!,
    ];
    if (values.isEmpty) {
      return;
    }
    if (widget.continuous) {
      for (final value in values) {
        _handleContinuous(value);
      }
      return;
    }
    _handleOneShot(values.first);
  }

  bool _accepts(String value) {
    final isAccepted = widget.isAccepted;
    if (isAccepted != null && !isAccepted(value)) {
      widget.onRejected?.call(value);
      return false;
    }
    return true;
  }

  void _handleContinuous(String value) {
    if (!_accepts(value)) {
      return;
    }
    if (_deduper.isDuplicate(value)) {
      return;
    }
    if (widget.hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
    widget.onScan(value);
  }

  void _handleOneShot(String value) {
    if (!_accepts(value)) {
      return;
    }
    if (!_scanGate.tryHandle()) {
      return;
    }
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (widget.hapticsEnabled) {
      unawaited(HapticFeedback.lightImpact());
    }
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
                    icon: torchOn
                        ? const Icon(Icons.flash_off, color: Colors.white54)
                        : const Icon(Icons.flash_on, color: Colors.white),
                    iconSize: 32.0,
                    onPressed: () {
                      if (!_controller.value.isInitialized) {
                        return;
                      }
                      _ignoreErrors(_controller.toggleTorch());
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.flip_camera_android_sharp,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    iconSize: 32.0,
                    onPressed: () {
                      if (!_controller.value.isInitialized) {
                        return;
                      }
                      _ignoreErrors(_controller.switchCamera());
                    },
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
            MobileScanner(
              controller: _controller,
              scanWindow: widget.scanWindow,
              errorBuilder: (context, error) =>
                  widget.errorBuilder?.call(context, error) ??
                  _ScannerErrorView(
                    error: error,
                    onRetry: () => _ignoreErrors(_controller.start()),
                  ),
            ),
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
            if (widget.hint != null)
              Positioned(
                left: 24,
                right: 24,
                bottom: 48,
                child: Text(
                  widget.hint!,
                  textAlign: TextAlign.center,
                  style:
                      widget.hintStyle ??
                      theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
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
        unawaited(_subscription?.cancel());
        _subscribe();
        _startScanner();
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        _ignoreErrors(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
    _ignoreErrors(_controller.dispose());
    super.dispose();
  }
}

class _ScannerErrorView extends StatelessWidget {
  const _ScannerErrorView({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final denied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              denied
                  ? 'Camera permission denied'
                  : 'The camera could not start',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              denied
                  ? 'Allow camera access in the system settings, then try again.'
                  : 'Try again. If the problem persists, restart the app.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
