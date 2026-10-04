import 'dart:math';

import 'package:flutter/material.dart';

/// A scanner viewfinder overlay that dims the camera preview and draws corner
/// brackets around a centered cut-out.
class BarcodeOverlay extends ShapeBorder {
  /// Creates a scanner overlay with a configurable border and cut-out.
  ///
  /// Provide either [cutOutSize] or both [cutOutWidth] and [cutOutHeight],
  /// never both.
  BarcodeOverlay({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    double? cutOutSize,
    double? cutOutWidth,
    double? cutOutHeight,
    this.cutOutBottomOffset = 0,
  }) : cutOutWidth = cutOutWidth ?? cutOutSize ?? 250,
       cutOutHeight = cutOutHeight ?? cutOutSize ?? 250 {
    assert(
      borderLength <=
          min(this.cutOutWidth, this.cutOutHeight) / 2 + borderWidth * 2,
      "Border can't be larger than ${min(this.cutOutWidth, this.cutOutHeight) / 2 + borderWidth * 2}",
    );
    assert(
      (cutOutWidth == null && cutOutHeight == null) ||
          (cutOutSize == null && cutOutWidth != null && cutOutHeight != null),
      'Use only cutOutWidth and cutOutHeight or only cutOutSize',
    );
  }

  /// Color of the corner brackets.
  final Color borderColor;

  /// Stroke width of the corner brackets.
  final double borderWidth;

  /// Color used to dim the area outside the cut-out.
  final Color overlayColor;

  /// Corner radius of the cut-out and corner brackets.
  final double borderRadius;

  /// Length of each corner bracket.
  final double borderLength;

  /// Width of the cut-out.
  final double cutOutWidth;

  /// Height of the cut-out.
  final double cutOutHeight;

  /// Vertical offset applied to the cut-out.
  final double cutOutBottomOffset;

  /// The extra space this overlay asks for around the border rectangle.
  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  /// Returns the inner edge path of the overlay for [rect].
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  /// Returns the outer edge path of the overlay for [rect].
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  /// Paints the dimmed area, cut-out, and corner brackets on [canvas].
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final mBorderLength =
        borderLength > min(cutOutHeight, cutOutHeight) / 2 + borderWidth * 2
        ? borderWidthSize / 2
        : borderLength;
    final mCutOutWidth = cutOutWidth < width
        ? cutOutWidth
        : width - borderOffset;
    final mCutOutHeight = cutOutHeight < height
        ? cutOutHeight
        : height - borderOffset;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final boxPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill
      ..blendMode = BlendMode.dstOut;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - mCutOutWidth / 2 + borderOffset,
      -cutOutBottomOffset +
          rect.top +
          height / 2 -
          mCutOutHeight / 2 +
          borderOffset,
      mCutOutWidth - borderOffset * 2,
      mCutOutHeight - borderOffset * 2,
    );

    canvas
      ..saveLayer(rect, backgroundPaint)
      ..drawRect(rect, backgroundPaint)
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - mBorderLength,
          cutOutRect.top,
          cutOutRect.right,
          cutOutRect.top + mBorderLength,
          topRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.top,
          cutOutRect.left + mBorderLength,
          cutOutRect.top + mBorderLength,
          topLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.right - mBorderLength,
          cutOutRect.bottom - mBorderLength,
          cutOutRect.right,
          cutOutRect.bottom,
          bottomRight: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromLTRBAndCorners(
          cutOutRect.left,
          cutOutRect.bottom - mBorderLength,
          cutOutRect.left + mBorderLength,
          cutOutRect.bottom,
          bottomLeft: Radius.circular(borderRadius),
        ),
        borderPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
        boxPaint,
      )
      ..restore();
  }

  /// Returns a copy of this overlay with every configured value preserved.
  @override
  ShapeBorder scale(double t) {
    return BarcodeOverlay(
      borderColor: borderColor,
      borderWidth: borderWidth,
      overlayColor: overlayColor,
      borderRadius: borderRadius,
      borderLength: borderLength,
      cutOutWidth: cutOutWidth,
      cutOutHeight: cutOutHeight,
      cutOutBottomOffset: cutOutBottomOffset,
    );
  }
}
