import 'package:flutter/material.dart';

class PodiumPainter extends CustomPainter {
  final Color color;
  final int position;
  final double depth;

  final Color? topColorOverride;
  final Color? sideColorOverride;

  final bool useFrontGradient;
  final double topCornerRadius;
  final TextStyle? numberStyle;

  PodiumPainter({
    required this.color,
    required this.position,
    this.depth = 22,
    this.topColorOverride,
    this.sideColorOverride,
    this.useFrontGradient = true,
    this.topCornerRadius = 10,
    this.numberStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final d = depth.clamp(0, w * 0.4).toDouble();

    final topColor = topColorOverride ?? _shift(color, 0.22);
    final sideColor = sideColorOverride ?? _shift(color, -0.14);

    // Front face bounds
    final frontRect = Rect.fromLTWH(0, d, w - d, h - d);
    final frontRRect = RRect.fromRectAndCorners(
      frontRect,
      topLeft: Radius.circular(topCornerRadius),
    );

    // ---- FRONT FACE ----
    final frontPaint = Paint();
    if (useFrontGradient) {
      frontPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color, _shift(color, 0.28)],
      ).createShader(frontRect);
    } else {
      frontPaint.color = color;
    }
    canvas.drawRRect(frontRRect, frontPaint);

    // ---- TOP FACE
    final topPath = Path()
      ..moveTo(topCornerRadius * 0.4, d)
      ..lineTo(d + topCornerRadius * 0.4, 0)
      ..lineTo(w, 0)
      ..lineTo(w - d, d)
      ..close();
    canvas.drawPath(topPath, Paint()..color = topColor);

    // ---- RIGHT SIDE FACE
    final sidePath = Path()
      ..moveTo(w - d, d)
      ..lineTo(w, 0)
      ..lineTo(w, h - d)
      ..lineTo(w - d, h)
      ..close();
    canvas.drawPath(sidePath, Paint()..color = sideColor);

    // ---- RANK NUMBER on the front face ----
    final style =
        numberStyle ??
        TextStyle(
          color: Colors.white,
          fontSize: (w - d) * 0.55,
          fontWeight: FontWeight.w900,
          height: 1.0,
        );
    final tp = TextPainter(
      text: TextSpan(text: '$position', style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final textOffset = Offset(
      (w - d - tp.width) / 2,
      d + (h - d - tp.height) / 2,
    );
    tp.paint(canvas, textOffset);
  }

  /// Lightens (positive [amount]) or darkens (negative [amount]) [c] by
  /// adjusting HSL lightness.
  Color _shift(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant PodiumPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.position != position ||
        oldDelegate.depth != depth ||
        oldDelegate.useFrontGradient != useFrontGradient;
  }
}
