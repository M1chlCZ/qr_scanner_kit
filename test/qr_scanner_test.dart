import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

import 'fake_mobile_scanner_platform.dart';

void main() {
  late FakeMobileScannerPlatform platform;
  late MobileScannerPlatform originalPlatform;

  setUp(() {
    originalPlatform = MobileScannerPlatform.instance;
    platform = FakeMobileScannerPlatform();
    MobileScannerPlatform.instance = platform;
    MobileScannerController.resetPlatformSessionOwner();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    MobileScannerPlatform.instance = originalPlatform;
    MobileScannerController.resetPlatformSessionOwner();
    await platform.close();
  });

  Future<void> pumpScanner(
    WidgetTester tester, {
    ValueChanged<String>? onScan,
    List<BarcodeFormat>? formats,
    bool hapticsEnabled = true,
    bool Function(String value)? isAccepted,
    void Function(String value)? onRejected,
    MobileScannerController? controller,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QrScanner(
          onScan: onScan ?? (_) {},
          formats: formats,
          hapticsEnabled: hapticsEnabled,
          isAccepted: isAccepted,
          onRejected: onRejected,
          controller: controller,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  List<MethodCall> capturePlatformCalls() {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          calls.add(call);
          return null;
        });
    return calls;
  }

  List<MethodCall> hapticCalls(List<MethodCall> calls) {
    return calls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
  }

  testWidgets('passes the configured formats to the internal controller', (
    tester,
  ) async {
    await pumpScanner(tester, formats: const [BarcodeFormat.qrCode]);

    expect(platform.startCalls, hasLength(1));
    expect(platform.startCalls.single.formats, const [BarcodeFormat.qrCode]);
  });

  testWidgets('detects all formats by default', (tester) async {
    await pumpScanner(tester);

    expect(platform.startCalls.single.formats, const [BarcodeFormat.all]);
  });

  testWidgets('an injected controller keeps its own formats', (tester) async {
    final controller = MobileScannerController(
      autoStart: false,
      formats: const [BarcodeFormat.ean13],
    );

    await pumpScanner(
      tester,
      controller: controller,
      formats: const [BarcodeFormat.qrCode],
    );

    expect(platform.startCalls.single.formats, const [BarcodeFormat.ean13]);
  });

  testWidgets('accepts the first non-empty value', (tester) async {
    final scans = <String>[];
    await pumpScanner(tester, onScan: scans.add);

    platform.emitCapture(
      BarcodeCapture(
        barcodes: const [
          Barcode(rawValue: ''),
          Barcode(rawValue: 'first'),
          Barcode(rawValue: 'second'),
        ],
      ),
    );
    await tester.pump();

    expect(scans, ['first']);
  });

  testWidgets('reports only the first accepted scan', (tester) async {
    final scans = <String>[];
    await pumpScanner(tester, onScan: scans.add);

    platform.emitValue('one');
    await tester.pump();
    platform.emitValue('two');
    await tester.pump();

    expect(scans, ['one']);
  });

  testWidgets('ignores captures without a value', (tester) async {
    final scans = <String>[];
    await pumpScanner(tester, onScan: scans.add);

    platform.emitCapture(const BarcodeCapture());
    platform.emitCapture(
      BarcodeCapture(barcodes: [const Barcode(rawValue: '')]),
    );
    await tester.pump();

    expect(scans, isEmpty);

    platform.emitValue('later');
    await tester.pump();

    expect(scans, ['later']);
  });

  testWidgets('plays a light haptic impact on an accepted scan', (
    tester,
  ) async {
    final calls = capturePlatformCalls();
    await pumpScanner(tester, onScan: (_) {});

    platform.emitValue('code');
    await tester.pump();

    final haptics = hapticCalls(calls);
    expect(haptics, hasLength(1));
    expect(haptics.single.arguments, 'HapticFeedbackType.lightImpact');
  });

  testWidgets('plays no haptics when hapticsEnabled is false', (tester) async {
    final calls = capturePlatformCalls();
    await pumpScanner(tester, hapticsEnabled: false, onScan: (_) {});

    platform.emitValue('code');
    await tester.pump();

    expect(hapticCalls(calls), isEmpty);
  });

  testWidgets('rejects a value and calls onRejected without haptics', (
    tester,
  ) async {
    final calls = capturePlatformCalls();
    final scans = <String>[];
    final rejected = <String>[];
    await pumpScanner(
      tester,
      onScan: scans.add,
      isAccepted: (value) => value.startsWith('OK-'),
      onRejected: rejected.add,
    );

    platform.emitValue('BAD-1');
    await tester.pump();

    expect(scans, isEmpty);
    expect(rejected, ['BAD-1']);
    expect(hapticCalls(calls), isEmpty);
  });

  testWidgets('accepts the next code after a rejection', (tester) async {
    final scans = <String>[];
    final rejected = <String>[];
    await pumpScanner(
      tester,
      onScan: scans.add,
      isAccepted: (value) => value.startsWith('OK-'),
      onRejected: rejected.add,
    );

    platform.emitValue('BAD-1');
    await tester.pump();
    platform.emitValue('OK-1');
    await tester.pump();

    expect(rejected, ['BAD-1']);
    expect(scans, ['OK-1']);
  });
}
