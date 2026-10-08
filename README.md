# qr_scanner_kit

A ready-to-use QR scanner screen and viewfinder overlay built on
[`mobile_scanner`](https://pub.dev/packages/mobile_scanner), with torch
control, camera switching, and a simple scan callback. The package comes from
the Rocketbot app, so every scanner screen behaves the same.

## Features

- `QrScanner`: a full-screen scanner with a live camera preview
- Torch toggle and front/back camera switching in the app bar
- `BarcodeOverlay`: a `ShapeBorder` that dims the preview and draws corner
  brackets around a centered cut-out
- `ScanGate`: a helper that lets a callback run at most once
- One-shot `onScan` callback with `popOnScan` control
- Optional injection of a `MobileScannerController`
- No state-management dependency, only plain Flutter widgets

## Install

```bash
flutter pub add qr_scanner_kit
```

## Permissions

`mobile_scanner` needs camera access at runtime.

### Android

`mobile_scanner` merges the `CAMERA` permission from its own manifest and
requests it at runtime. No app-side change is necessary. When the app handles
permission UX itself, request the permission before you push `QrScanner`.

### iOS

Add a usage description to `ios/Runner/Info.plist`. App Review rejects the app
without this entry:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan QR codes.</string>
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (BuildContext context) {
      return QrScanner(
        title: 'Scan QR code',
        onScan: (String value) {
          print('Scanned: $value');
        },
      );
    },
  ),
);
```

## API

### QrScanner

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `onScan` | `ValueChanged<String>` | required | Receives the first decoded non-empty barcode value. |
| `title` | `String?` | `'Scan QR code'` | App bar title. |
| `overlay` | `BarcodeOverlay?` | red corner brackets | Overlay on the camera preview. |
| `backgroundColor` | `Color?` | `Theme.canvasColor` | Background color of the scanner body. |
| `popOnScan` | `bool` | `true` | Pops the route after the first scan. |
| `controller` | `MobileScannerController?` | created internally | Camera controller. The widget respects its `autoStart` flag. |

`onScan` runs at most once per `QrScanner`. The widget reports only the first
decoded non-empty barcode and then cancels the subscription. With
`popOnScan: false`, the screen stays open but reports no more barcodes. Push a
new `QrScanner` to scan again.

When you do not pass a controller, `QrScanner` creates one with
`autoStart: false`. The widget starts and stops the controller with the app
lifecycle and disposes it. Do not dispose an injected controller yourself. Do
not reuse it after the scanner closes. To inject a controller, import
`package:mobile_scanner/mobile_scanner.dart`. The package does not re-export
`mobile_scanner`.

### BarcodeOverlay

| Parameter | Default | Purpose |
| --- | --- | --- |
| `borderColor` | `Colors.red` | Color of the corner brackets. |
| `borderWidth` | `3.0` | Stroke width of the corner brackets. |
| `overlayColor` | translucent black | Dim color outside the cut-out. |
| `borderRadius` | `0` | Corner radius of the cut-out and brackets. |
| `borderLength` | `40` | Length of each corner bracket. |
| `cutOutSize`, `cutOutWidth`, `cutOutHeight` | 250 | Cut-out dimensions. |
| `cutOutBottomOffset` | `0` | Vertical offset of the cut-out. |

Use `cutOutSize`, or use `cutOutWidth` and `cutOutHeight`. Do not use both.

### ScanGate

`ScanGate` holds the one-shot guard as a small, testable helper. `tryHandle()`
returns `true` once and `false` on later calls until you call `reset()`.

## Example

A runnable app in [`example/`](example/) pushes the scanner and shows the last
scanned value. The example ships without platform folders, so generate them
before you run it on a device with a camera:

```bash
cd example
flutter create . --platforms=android,ios
flutter run
```

## Attribution

`BarcodeOverlay` is a modified copy of `OverlayShape` from the
[`ai_barcode_scanner`](https://pub.dev/packages/ai_barcode_scanner) package
(version 5.2.2, Apache-2.0). It was renamed, documented, and adjusted. The
full Apache-2.0 license text is in [`THIRD_PARTY_NOTICES`](THIRD_PARTY_NOTICES).

The package itself is MIT licensed. See [`LICENSE`](LICENSE). Only the derived
`BarcodeOverlay` remains under Apache-2.0.
