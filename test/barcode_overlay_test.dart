import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_scanner_kit/qr_scanner_kit.dart';

void main() {
  test('scale preserves the configured border color and width', () {
    final overlay = BarcodeOverlay(
      borderColor: Colors.green,
      borderWidth: 4,
      borderRadius: 8,
      borderLength: 20,
    );
    final scaled = overlay.scale(2) as BarcodeOverlay;
    expect(scaled.borderColor, Colors.green);
    expect(scaled.borderWidth, 4);
    expect(scaled.borderRadius, 8);
    expect(scaled.borderLength, 20);
  });

  test('outer path spans the full rect', () {
    final overlay = BarcodeOverlay();
    final path = overlay.getOuterPath(const Rect.fromLTWH(0, 0, 100, 100));
    expect(path.getBounds(), const Rect.fromLTWH(0, 0, 100, 100));
  });
}
