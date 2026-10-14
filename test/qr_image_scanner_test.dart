import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

import 'fake_mobile_scanner_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeMobileScannerPlatform platform;
  late MobileScannerPlatform originalPlatform;

  setUp(() {
    originalPlatform = MobileScannerPlatform.instance;
    platform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  tearDown(() async {
    MobileScannerPlatform.instance = originalPlatform;
    MobileScannerController.resetPlatformSessionOwner();
    await platform.close();
  });

  test('returns the first non-empty barcode value', () async {
    platform.analyzeResult = BarcodeCapture(
      barcodes: const [
        Barcode(rawValue: ''),
        Barcode(rawValue: 'from-file'),
        Barcode(rawValue: 'second'),
      ],
    );

    final value = await QrImageScanner.scanImageFile('/tmp/code.png');

    expect(value, 'from-file');
    expect(platform.analyzePaths, ['/tmp/code.png']);
  });

  test('returns null when the image holds no barcode', () async {
    platform.analyzeResult = null;

    final value = await QrImageScanner.scanImageFile('/tmp/code.png');

    expect(value, isNull);
  });

  test('returns null when every barcode holds an empty value', () async {
    platform.analyzeResult = BarcodeCapture(
      barcodes: const [
        Barcode(rawValue: ''),
        Barcode(),
      ],
    );

    final value = await QrImageScanner.scanImageFile('/tmp/code.png');

    expect(value, isNull);
  });

  test('disposes its own controller after the scan', () async {
    platform.analyzeResult = BarcodeCapture(
      barcodes: const [Barcode(rawValue: 'value')],
    );

    await QrImageScanner.scanImageFile('/tmp/code.png');

    expect(platform.disposeCount, 1);
  });

  test('throws UnsupportedError on unsupported platforms', () async {
    platform.analyzeError = UnsupportedError('Image analysis is unavailable.');

    await expectLater(
      QrImageScanner.scanImageFile('/tmp/code.png'),
      throwsA(isA<UnsupportedError>()),
    );

    expect(platform.disposeCount, 1);
  });

  testWidgets('does not stop or dispose the live camera scan', (tester) async {
    final controller = MobileScannerController(autoStart: false);
    await tester.pumpWidget(
      MaterialApp(
        home: QrScanner(controller: controller, onScan: (_) {}),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(controller.value.isRunning, isTrue);

    platform.analyzeResult = BarcodeCapture(
      barcodes: const [Barcode(rawValue: 'from-file')],
    );
    final value = await QrImageScanner.scanImageFile('/tmp/code.png');

    expect(value, 'from-file');
    expect(platform.stopCount, 0);
    expect(platform.disposeCount, 0);
    expect(controller.value.isRunning, isTrue);
  });
}
