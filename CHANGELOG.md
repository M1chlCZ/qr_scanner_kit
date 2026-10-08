## 0.1.1

- Rewrite the README. The install section now uses
  `flutter pub add qr_scanner_kit`.

## 0.1.0

- Initial release.
- Extracted the Rocketbot app's QR scanning into a reusable package:
  `QrScanner`, `BarcodeOverlay`, and `ScanGate`, built on `mobile_scanner ^7`.
- `QrScanner` is a full-screen scanner with a camera preview, torch control,
  and front/back camera switching.
- Every capture goes through a single scan-result path (one barcode stream
  subscription), fixing the app's old widget that handled results twice
  through both `onDetect` and a stream listener.
- Lifecycle-safe disposal ordering: the widget stops the subscription, then
  disposes the controller, and the controller is never disposed from the scan
  handler. Camera stop errors are swallowed instead of surfacing as unhandled
  exceptions.
- `BarcodeOverlay.scale` now preserves every configured value (border, radius,
  cut-out, and offset) instead of resetting them to defaults.
- `onScan` has one-shot semantics: at most one value per widget lifetime.
  `popOnScan: false` keeps the screen open but reports no further barcodes.
- An injected `MobileScannerController` has its `autoStart` setting respected;
  the widget still manages start/stop and takes ownership by disposing it.
- `BarcodeOverlay` is derived from `OverlayShape` in `ai_barcode_scanner`
  5.2.2 (Apache-2.0); attribution is documented in the README and
  `THIRD_PARTY_NOTICES`.
