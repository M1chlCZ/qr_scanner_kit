# qr_scanner_kit

A QR scanner screen and viewfinder overlay for Flutter, built on
[`mobile_scanner`](https://pub.dev/packages/mobile_scanner). You get torch
control, camera switching and one callback for the scanned value. The package
grew out of the Rocketbot app, so the scanner looks and behaves the same
everywhere it's used.

## Features

- `QrScanner`: a full-screen scanner with a live camera preview
- Torch toggle and front/back camera switching in the app bar
- `QrImageScanner`: gallery scanning from an image file
- Barcode format selection through `formats`
- Haptic feedback on accepted scans
- Validation hooks: `isAccepted` and `onRejected`
- Continuous scanning mode with a duplicate window for repeated codes
- `BarcodeOverlay`: a `ShapeBorder` that dims the preview and draws corner
  brackets around a centred cut-out
- `ScanGate`: a helper that lets a callback run at most once
- `ScanDeduper`: a helper that suppresses repeated codes in a time window
- One-shot `onScan` callback with `popOnScan` control
- Optional hint text over the camera preview
- Optional injection of a `MobileScannerController`
- No state-management dependency, only plain Flutter widgets

## Install

```bash
flutter pub add qr_scanner_kit
```

## Permissions

`mobile_scanner` needs camera access at runtime.

### Android

`mobile_scanner` declares the `CAMERA` permission in its own manifest and asks
for it at runtime, so you don't need to change anything. If your app handles
the permission prompt itself, ask before you open `QrScanner`.

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

## Gallery scanning

`QrImageScanner.scanImageFile` decodes one barcode from an image file:

```dart
final String? value = await QrImageScanner.scanImageFile('/path/to/code.png');
```

The method creates its own controller, analyses the file and disposes the
controller again. A running camera scan keeps its state. Image analysis works
on Android, physical iOS devices and macOS; other platforms throw an
`UnsupportedError`. The iOS Simulator can't analyse images.

## Barcode formats

`QrScanner` detects every barcode format by default. Pass `formats` to narrow
it down. The list goes to the controller the widget creates:

```dart
import 'package:mobile_scanner/mobile_scanner.dart';

QrScanner(
  formats: const [BarcodeFormat.qrCode, BarcodeFormat.ean13],
  onScan: (String value) {
    print('Scanned: $value');
  },
);
```

An injected controller keeps its own formats, so `formats` does nothing in
that case.

## Haptics

`QrScanner` plays a light haptic impact when it accepts a code. This is on by
default. Set `hapticsEnabled: false` to turn it off:

```dart
QrScanner(
  hapticsEnabled: false,
  onScan: (String value) {
    print('Scanned: $value');
  },
);
```

## Validation hooks

Use `isAccepted` to filter scanned values. The scanner checks it before the
one-shot gate. A rejected value uses up no scan attempt, plays no haptics and
never reaches `onScan`. The scanner stays ready for the next code, and
`onRejected` receives every value that failed the check:

```dart
QrScanner(
  isAccepted: (String value) => value.startsWith('SHOP-'),
  onRejected: (String value) => print('Rejected: $value'),
  onScan: (String value) => print('Accepted: $value'),
);
```

## Continuous scanning

Set `continuous: true` to keep the camera running and report every accepted
code. The same code is ignored for `duplicateWindow` (two seconds by default),
so a barcode held in front of the camera doesn't flood the callback:

```dart
QrScanner(
  continuous: true,
  duplicateWindow: const Duration(seconds: 3),
  onScan: (String value) => results.add(value),
);
```

You can also draw a short instruction over the preview:

```dart
QrScanner(
  hint: 'Point the camera at a code',
  onScan: (String value) => print(value),
);
```

## API

### QrScanner

| Parameter | Type | Default | Purpose |
| --- | --- | --- | --- |
| `onScan` | `ValueChanged<String>` | required | Receives the first decoded non-empty barcode value. |
| `title` | `String?` | `'Scan QR code'` | App bar title. |
| `overlay` | `BarcodeOverlay?` | red corner brackets | Overlay on the camera preview. |
| `backgroundColor` | `Color?` | `Theme.canvasColor` | Background colour of the scanner body. |
| `popOnScan` | `bool` | `true` | Pops the route after the first scan. |
| `controller` | `MobileScannerController?` | created internally | Camera controller. The widget respects its `autoStart` flag. |
| `formats` | `List<BarcodeFormat>?` | `null` (all formats) | Formats for the internally created controller. |
| `hapticsEnabled` | `bool` | `true` | Plays a light haptic impact on an accepted scan. |
| `isAccepted` | `bool Function(String)?` | `null` (accept all) | Filters values before the one-shot gate. |
| `onRejected` | `void Function(String)?` | `null` | Receives values that `isAccepted` rejects. |
| `continuous` | `bool` | `false` | Keeps scanning and reports every accepted code. |
| `duplicateWindow` | `Duration` | 2 seconds | Ignores repeats of one code in continuous mode. |
| `hint` | `String?` | `null` | Instruction drawn over the preview. |
| `hintStyle` | `TextStyle?` | white70 body text | Style of `hint`. |

In the default one-shot mode, `onScan` runs at most once per `QrScanner`. The
widget reports the first decoded barcode and cancels the subscription. With
`popOnScan: false`, the screen stays open but reports nothing more. Push a new
`QrScanner` to scan again.

With `continuous: true`, the scanner keeps running, reports each accepted code
once per `duplicateWindow` and never pops the route. `popOnScan` applies only
to the one-shot mode.

When you don't pass a controller, `QrScanner` creates one with
`autoStart: false`. The widget starts and stops it with the app lifecycle and
disposes it when the widget goes away. Don't dispose an injected controller
yourself, and don't reuse it after the scanner closes. To inject one, import
`package:mobile_scanner/mobile_scanner.dart`; the package doesn't re-export
`mobile_scanner`.

### QrImageScanner

`QrImageScanner.scanImageFile(path)` decodes one barcode from an image file
and returns its value, or `null` when the image has no barcode. The method
creates its own controller and disposes it after the scan. A running camera
scan keeps its state. Image analysis works on Android, physical iOS devices
and macOS; other platforms throw an `UnsupportedError`.

### BarcodeOverlay

| Parameter | Default | Purpose |
| --- | --- | --- |
| `borderColor` | `Colors.red` | Colour of the corner brackets. |
| `borderWidth` | `3.0` | Stroke width of the corner brackets. |
| `overlayColor` | translucent black | Dim colour outside the cut-out. |
| `borderRadius` | `0` | Corner radius of the cut-out and brackets. |
| `borderLength` | `40` | Length of each corner bracket. |
| `cutOutSize`, `cutOutWidth`, `cutOutHeight` | 250 | Cut-out dimensions. |
| `cutOutBottomOffset` | `0` | Vertical offset of the cut-out. |

Use `cutOutSize`, or use `cutOutWidth` and `cutOutHeight`. Not both.

### ScanGate

`ScanGate` keeps the one-shot guard in a small, testable helper. `tryHandle()`
returns `true` once and `false` on later calls until you call `reset()`.

### ScanDeduper

`ScanDeduper` suppresses repeated codes in continuous mode. `isDuplicate()`
returns `true` when the same value arrived inside the window; `reset()` clears
the history. Pass `clock` to keep tests instant.

## Example

A runnable app in [`example/`](example/) pushes the scanner and shows the last
scanned value. The example ships without platform directories, so generate
them before running it on a device with a camera:

```bash
cd example
flutter create . --platforms=android,ios
flutter run
```

## Attribution

`BarcodeOverlay` is a modified copy of `OverlayShape` from the
[`ai_barcode_scanner`](https://pub.dev/packages/ai_barcode_scanner) package
(version 5.2.2, Apache-2.0). It was renamed, documented and adjusted. The full
Apache-2.0 licence text is in [`THIRD_PARTY_NOTICES`](THIRD_PARTY_NOTICES).

The package itself is MIT licensed. See [`LICENSE`](LICENSE). Only the derived
`BarcodeOverlay` remains under Apache-2.0.
