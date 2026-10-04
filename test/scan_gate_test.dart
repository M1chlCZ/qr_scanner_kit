import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

void main() {
  test('allows exactly one handle', () {
    final gate = ScanGate();
    expect(gate.tryHandle(), isTrue);
    expect(gate.tryHandle(), isFalse);
    expect(gate.tryHandle(), isFalse);
  });

  test('can be reset for reuse', () {
    final gate = ScanGate();
    expect(gate.tryHandle(), isTrue);
    gate.reset();
    expect(gate.tryHandle(), isTrue);
  });
}
