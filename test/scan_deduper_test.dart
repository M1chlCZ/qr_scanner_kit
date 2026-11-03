import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

void main() {
  test('reports a new code once', () {
    final deduper = ScanDeduper(window: const Duration(seconds: 2));
    expect(deduper.isDuplicate('code'), isFalse);
    expect(deduper.isDuplicate('code'), isTrue);
  });

  test('reports a code again after the window', () {
    var now = DateTime(2026, 11, 3, 12);
    final deduper = ScanDeduper(
      window: const Duration(seconds: 2),
      clock: () => now,
    );
    expect(deduper.isDuplicate('code'), isFalse);
    now = now.add(const Duration(seconds: 3));
    expect(deduper.isDuplicate('code'), isFalse);
  });

  test('keeps different codes apart', () {
    final deduper = ScanDeduper();
    expect(deduper.isDuplicate('alpha'), isFalse);
    expect(deduper.isDuplicate('beta'), isFalse);
    expect(deduper.isDuplicate('alpha'), isTrue);
  });

  test('reset forgets every code', () {
    final deduper = ScanDeduper();
    deduper.isDuplicate('code');
    deduper.reset();
    expect(deduper.isDuplicate('code'), isFalse);
  });

  test('drops entries outside the window', () {
    var now = DateTime(2026, 11, 3, 12);
    final deduper = ScanDeduper(
      window: const Duration(seconds: 2),
      clock: () => now,
    );
    deduper.isDuplicate('alpha');
    deduper.isDuplicate('beta');
    expect(deduper.length, 2);
    now = now.add(const Duration(seconds: 3));
    deduper.isDuplicate('gamma');
    expect(deduper.length, 1);
  });
}
