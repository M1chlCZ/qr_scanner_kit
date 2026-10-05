# qr_scanner_kit

A ready-to-use QR scanner screen and viewfinder overlay built on
[`mobile_scanner`](https://pub.dev/packages/mobile_scanner), with torch
control, camera switching, and a simple scan callback. Extracted from the
Rocketbot app so every scanner screen behaves the same.

## Features

- `QrScanner`: a full-screen scanner with a live camera preview.
- Torch toggle and front/back camera switching in the app bar.
- `BarcodeOverlay`: a `ShapeBorder` that dims the preview and draws corner
  brackets around a centered cut-out.
- `ScanGate`: a small helper that lets a callback run at most once.
- One-shot `onScan` callback with `popOnScan` control.
- Optional injection of a `MobileScannerController`.
- No state-management dependency; plain Flutter widgets.

## Install

```bash
flutter pub add qr_scanner_kit
```

Until the package is published on pub.dev, depend on it with a path:

```yaml
dependencies:
  qr_scanner_kit:
    path: packages/qr_scanner_kit
```

## Permissions

`mobile_scanner` needs camera access at runtime. Android permissions are
merged from the plugin manifest and requested by the plugin, while iOS
requires a usage description in the app's `Info.plist`.

### Android

`mobile_scanner` merges the `CAMERA` permission from its own manifest and
requests it at runtime, so no app-side change is strictly required. To declare
it explicitly, add it to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

If the app handles permission UX itself, for example with `permission_handler`,
request the permission before pushing `QrScanner`.

### iOS

This entry is required on iOS. Add a usage description to
`ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes.</string>
```

The system shows this text in the permission prompt, and the app is rejected
by App Review without it.

## Usage

The snippet below matches `example/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

void main() {
  runApp(const QrScannerExampleApp());
}

class QrScannerExampleApp extends StatelessWidget {
  const QrScannerExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'qr_scanner_kit example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF9BD41E),
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  String _lastScan = 'No scan yet';

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return QrScanner(
            title: 'Scan QR code',
            onScan: (String value) {
              setState(() {
                _lastScan = value;
              });
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('qr_scanner_kit example')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Last scan: $_lastScan', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Open scanner'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## API

### QrScanner

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `onScan` | `ValueChanged<String>` | required | Called with the first successfully decoded non-empty barcode value. |
| `title` | `String?` | `'Scan QR code'` | Title shown in the app bar. |
| `overlay` | `BarcodeOverlay?` | `BarcodeOverlay(borderColor: red, borderRadius: 10, borderLength: 30, borderWidth: 5)` | Overlay drawn on top of the camera preview. |
| `backgroundColor` | `Color?` | `Theme.canvasColor` | Background color of the scanner body. |
| `popOnScan` | `bool` | `true` | Whether to attempt to pop the enclosing route after the first scan. |
| `controller` | `MobileScannerController?` | created internally | Camera controller; its `autoStart` setting is respected. |

### Scan behavior

`onScan` is called **at most once per `QrScanner` instance**: only the first
successfully decoded, non-empty barcode is reported, and the barcode stream
subscription is cancelled immediately afterwards. With the default
`popOnScan: true` the scanner attempts to pop the enclosing route (via
`Navigator.maybePop`) after that first scan. With `popOnScan: false` the screen
stays open and the camera preview keeps running, but no further barcodes are
reported. Push a new `QrScanner` to scan again.

### Controller ownership

When no `controller` is passed, `QrScanner` creates one with
`autoStart: false` and starts it after subscribing. A provided controller is
not started blindly: its `autoStart` flag is respected, the widget still
starts and stops it with the app lifecycle, and the widget disposes the
controller when it is disposed. Do not dispose an injected controller
yourself and do not reuse it after the scanner is closed.

Injecting a controller requires a direct dependency on `mobile_scanner` and
`import 'package:mobile_scanner/mobile_scanner.dart';`, because
`qr_scanner_kit` does not re-export it.

### ScanGate

`ScanGate` implements the one-shot guard as a tiny, testable helper:
`tryHandle()` returns `true` once and `false` on every later call until
`reset()` is called. It is exported for callers who want the same semantics
in their own barcode handling.

### BarcodeOverlay

`BarcodeOverlay` is a `ShapeBorder` for use with `ShapeDecoration`. It dims
the area outside a centered cut-out and draws corner brackets around it.

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `borderColor` | `Color` | `Colors.red` | Color of the corner brackets. |
| `borderWidth` | `double` | `3.0` | Stroke width of the corner brackets. |
| `overlayColor` | `Color` | translucent black | Color used to dim the area outside the cut-out. |
| `borderRadius` | `double` | `0` | Corner radius of the cut-out and corner brackets. |
| `borderLength` | `double` | `40` | Length of each corner bracket. |
| `cutOutSize` | `double?` | `null` | Square cut-out size. Mutually exclusive with `cutOutWidth`/`cutOutHeight`. |
| `cutOutWidth` | `double?` | effective default: 250 (or `cutOutSize`) | Width of the cut-out. |
| `cutOutHeight` | `double?` | effective default: 250 (or `cutOutSize`) | Height of the cut-out. |
| `cutOutBottomOffset` | `double` | `0` | Vertical offset applied to the cut-out. |

Provide either `cutOutSize` or both `cutOutWidth` and `cutOutHeight`, never
both. `scale` returns a copy with every configured value preserved.

## Example

A runnable app that pushes the scanner and shows the last scanned value lives
in [`example/`](example/). The example ships without platform folders, so
generate them locally before running on a device with a camera:

```bash
cd example
flutter create . --platforms=android,ios
flutter run
```

The generated `android/` and `ios/` folders are not committed.

## Screenshot

A screenshot for the pub.dev listing is not included yet. Run the example app
to see the default overlay and the app bar controls.

## Attribution

`BarcodeOverlay` is a modified copy of `OverlayShape` from the
[`ai_barcode_scanner`](https://pub.dev/packages/ai_barcode_scanner) package
(version 5.2.2, Apache-2.0). It was renamed to `BarcodeOverlay`, public
documentation was added, default border values were changed, validation and
assert messages were corrected, and `scale` now preserves the configured
overlay values. The full Apache-2.0 license text is reproduced in
[`THIRD_PARTY_NOTICES`](THIRD_PARTY_NOTICES).

The package itself is MIT licensed (see [`LICENSE`](LICENSE)); only the
derived `BarcodeOverlay` remains under Apache-2.0.
