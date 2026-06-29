import 'package:flutter/material.dart';

class FamilyHearthMark extends StatelessWidget {
  const FamilyHearthMark({
    super.key,
    this.size = 72,
    this.color = const Color(0xFFE85D43),
    this.flameColor = const Color(0xFFFFB545),
    this.backgroundColor,
  });

  final double size;
  final Color color;
  final Color flameColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      painter: _FamilyHearthMarkPainter(color: color, flameColor: flameColor),
    );

    if (backgroundColor == null) {
      return SizedBox.square(dimension: size, child: mark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(size * 0.15),
      child: mark,
    );
  }
}

class FamilyHearthLockup extends StatelessWidget {
  const FamilyHearthLockup({
    super.key,
    this.markSize = 64,
    this.textColor = const Color(0xFF221B16),
    this.subtitleColor = const Color(0xFF6F6258),
    this.subtitle = 'Family Connection App',
  });

  final double markSize;
  final Color textColor;
  final Color subtitleColor;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FamilyHearthMark(
          size: markSize,
          backgroundColor: const Color(0xFFFFE2BF),
        ),
        SizedBox(width: markSize * 0.18),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Family Hearth',
                  maxLines: 1,
                  style: TextStyle(
                    color: textColor,
                    fontSize: markSize * 0.4,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    height: 0.96,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: markSize * 0.19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyHearthMarkPainter extends CustomPainter {
  const _FamilyHearthMarkPainter({
    required this.color,
    required this.flameColor,
  });

  final Color color;
  final Color flameColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final strokeWidth = w * 0.07;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;

    final roof = Path()
      ..moveTo(w * 0.14, h * 0.54)
      ..lineTo(w * 0.5, h * 0.19)
      ..lineTo(w * 0.86, h * 0.54);
    canvas.drawPath(roof, stroke);

    final house = Path()
      ..moveTo(w * 0.22, h * 0.47)
      ..lineTo(w * 0.22, h * 0.84)
      ..lineTo(w * 0.78, h * 0.84)
      ..lineTo(w * 0.78, h * 0.47);
    canvas.drawPath(house, stroke);

    final flame = Path()
      ..moveTo(w * 0.5, h * 0.44)
      ..cubicTo(w * 0.39, h * 0.36, w * 0.45, h * 0.26, w * 0.5, h * 0.22)
      ..cubicTo(w * 0.62, h * 0.32, w * 0.59, h * 0.39, w * 0.64, h * 0.46)
      ..cubicTo(w * 0.68, h * 0.55, w * 0.59, h * 0.62, w * 0.5, h * 0.64)
      ..cubicTo(w * 0.41, h * 0.62, w * 0.33, h * 0.55, w * 0.36, h * 0.46)
      ..cubicTo(w * 0.38, h * 0.4, w * 0.43, h * 0.38, w * 0.5, h * 0.44)
      ..close();

    canvas.drawPath(
      flame,
      Paint()
        ..style = PaintingStyle.fill
        ..color = flameColor.withValues(alpha: 0.76),
    );

    final heart = Path()
      ..moveTo(w * 0.5, h * 0.82)
      ..cubicTo(w * 0.26, h * 0.66, w * 0.23, h * 0.49, w * 0.35, h * 0.43)
      ..cubicTo(w * 0.43, h * 0.39, w * 0.49, h * 0.45, w * 0.5, h * 0.5)
      ..cubicTo(w * 0.51, h * 0.45, w * 0.57, h * 0.39, w * 0.65, h * 0.43)
      ..cubicTo(w * 0.77, h * 0.49, w * 0.74, h * 0.66, w * 0.5, h * 0.82);

    canvas.drawPath(heart, stroke);

    canvas.drawPath(
      heart,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.38
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _FamilyHearthMarkPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.flameColor != flameColor;
  }
}
