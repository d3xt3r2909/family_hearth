import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/family_contact.dart';
import '../../i18n/app_localizations.dart';

class ContactTile extends StatefulWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.enabled,
    this.gardenIndex = 0,
    required this.onPressed,
  });

  final FamilyContact contact;
  final bool enabled;
  final int gardenIndex;
  final VoidCallback onPressed;

  @override
  State<ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<ContactTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 9000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(widget.contact.accentColorValue);
    final phase = _phaseFor(widget.contact);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse =
            (math.sin((_controller.value + phase) * math.pi * 2) + 1) / 2;
        final scale = widget.enabled ? 1.0 + pulse * 0.018 : 1.0;
        final bob = widget.enabled
            ? math.sin((_controller.value + phase) * math.pi * 2) * 4
            : 0.0;
        final tilt = widget.enabled
            ? math.sin((_controller.value + phase + 0.25) * math.pi * 2) * 0.012
            : 0.0;
        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: tilt,
            child: Transform.scale(scale: scale, child: child),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: context.t.callPerson(widget.contact.displayName),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          elevation: widget.enabled ? 18 : 2,
          shadowColor: accent.withValues(alpha: 0.28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                border: Border.all(
                  color: accent.withValues(alpha: 0.48),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PortraitBackdropPainter(
                        accent: accent,
                        morph: _controller,
                        phase: phase + widget.gardenIndex * 0.11,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shortestSide = math.min(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final portraitSize = shortestSide * 0.56;
                        final iconSize = portraitSize * 0.46;
                        final clampedPortraitSize = portraitSize
                            .clamp(132.0, 230.0)
                            .toDouble();
                        final clampedIconSize = iconSize
                            .clamp(62.0, 104.0)
                            .toDouble();

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          child: Column(
                            children: [
                              Expanded(
                                child: Center(
                                  child: SizedBox.square(
                                    dimension: clampedPortraitSize,
                                    child: CustomPaint(
                                      painter: _MorphingPortraitPainter(
                                        accent: accent,
                                        morph: _controller,
                                        phase: phase,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _iconFor(widget.contact.relationship),
                                          color: accent,
                                          size: clampedIconSize,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _NameBubble(
                                accent: accent,
                                name: widget.contact.displayName,
                                relationship: widget.contact.relationship,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: _MediaBadge(accent: accent),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: _MiniSparkleBadge(
                      accent: accent,
                      morph: _controller,
                      phase: phase,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _phaseFor(FamilyContact contact) {
    final value = '${contact.id}:${contact.displayName}';
    var hash = 0;
    for (final unit in value.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return (hash % 1000) / 1000;
  }

  IconData _iconFor(String relationship) {
    final value = relationship.toLowerCase();
    if (value.contains('grandpa') || value.contains('uncle')) {
      return Icons.face_6_rounded;
    }
    if (value.contains('aunt') || value.contains('grandma')) {
      return Icons.face_3_rounded;
    }
    return Icons.favorite_rounded;
  }
}

class _NameBubble extends StatelessWidget {
  const _NameBubble({
    required this.accent,
    required this.name,
    required this.relationship,
  });

  final Color accent;
  final String name;
  final String relationship;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.34), width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF221B16),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_rounded, color: accent, size: 17),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  relationship,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF5F534A).withValues(alpha: 0.86),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSparkleBadge extends StatelessWidget {
  const _MiniSparkleBadge({
    required this.accent,
    required this.morph,
    required this.phase,
  });

  final Color accent;
  final Animation<double> morph;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: morph,
      builder: (context, child) {
        final turn = (morph.value + phase) * math.pi * 2;
        return Transform.rotate(angle: turn * 0.08, child: child);
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFFFB545),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          color: Color(0xFF221B16),
          size: 25,
        ),
      ),
    );
  }
}

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 31),
    );
  }
}

class _PortraitBackdropPainter extends CustomPainter {
  _PortraitBackdropPainter({
    required this.accent,
    required this.morph,
    required this.phase,
  }) : super(repaint: morph);

  final Color accent;
  final Animation<double> morph;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = math.sin((morph.value + phase) * math.pi * 2);
    final base = Paint()..style = PaintingStyle.fill;

    base.color = Color.alphaBlend(
      accent.withValues(alpha: 0.08),
      const Color(0xFFFFFBF2),
    );
    canvas.drawRect(Offset.zero & size, base);

    base.color = accent.withValues(alpha: 0.12);
    canvas.drawCircle(
      Offset(size.width * (0.18 + pulse * 0.02), size.height * 0.24),
      size.shortestSide * 0.23,
      base,
    );
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * (0.32 - pulse * 0.02)),
      size.shortestSide * 0.18,
      base,
    );

    base.color = const Color(0xFFFFB545).withValues(alpha: 0.2);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * (0.62 + pulse * 0.025))
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * (0.48 - pulse * 0.035),
          size.width,
          size.height * (0.7 - pulse * 0.02),
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      base,
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.14);

    for (var index = 0; index < 4; index += 1) {
      final y = size.height * (0.18 + index * 0.18);
      final path = Path()
        ..moveTo(size.width * 0.08, y)
        ..quadraticBezierTo(
          size.width * 0.38,
          y + (index.isEven ? 16 : -12),
          size.width * 0.62,
          y,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          y - (index.isEven ? 12 : -16),
          size.width * 0.92,
          y + 8,
        );
      canvas.drawPath(path, line);
    }

    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.18);
    for (var index = 0; index < 7; index += 1) {
      _drawStar(
        canvas,
        Offset(
          size.width * ((0.16 + index * 0.21 + pulse * 0.01) % 0.86),
          size.height * ((0.18 + index * 0.17) % 0.82),
        ),
        8 + index % 3 * 2,
        phase + index,
        starPaint,
      );
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    for (var index = 0; index < 10; index += 1) {
      final pointRadius = index.isEven ? radius : radius * 0.48;
      final angle = rotation - math.pi / 2 + index * math.pi / 5;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * pointRadius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PortraitBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.morph != morph ||
        oldDelegate.phase != phase;
  }
}

class _MorphingPortraitPainter extends CustomPainter {
  _MorphingPortraitPainter({
    required this.accent,
    required this.morph,
    required this.phase,
  }) : super(repaint: morph);

  final Color accent;
  final Animation<double> morph;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _shapePath(size, (morph.value + phase) % 1);
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.22), 12, false);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withValues(alpha: 0.94),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = accent.withValues(alpha: 0.08),
    );
  }

  Path _shapePath(Size size, double value) {
    const samples = 96;
    const shapeCount = 4;
    final progress = value * shapeCount;
    final fromShape = progress.floor() % shapeCount;
    final toShape = (fromShape + 1) % shapeCount;
    final local = _ease(progress - progress.floor());
    final points = <Offset>[];
    final center = Offset(size.width / 2, size.height / 2);
    final xRadius = size.width * 0.46;
    final yRadius = size.height * 0.46;

    for (var index = 0; index < samples; index++) {
      final theta = -math.pi / 2 + (index / samples) * math.pi * 2;
      final fromRadius = _radiusForShape(fromShape, theta);
      final toRadius = _radiusForShape(toShape, theta);
      final radius = _lerp(fromRadius, toRadius, local);
      points.add(
        Offset(
          center.dx + math.cos(theta) * xRadius * radius,
          center.dy + math.sin(theta) * yRadius * radius,
        ),
      );
    }

    final path = Path();
    final firstMidpoint = Offset.lerp(points.last, points.first, 0.5)!;
    path.moveTo(firstMidpoint.dx, firstMidpoint.dy);

    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final next = points[(index + 1) % points.length];
      final midpoint = Offset.lerp(current, next, 0.5)!;
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
    }

    return path..close();
  }

  double _radiusForShape(int shape, double theta) {
    return switch (shape) {
      0 =>
        0.9 +
            math.sin(theta * 3 + 0.8) * 0.045 +
            math.cos(theta * 5 - 0.4) * 0.03,
      1 => _starRadius(theta),
      2 => 0.91,
      3 => _triangleRadius(theta),
      _ => 0.9,
    };
  }

  double _starRadius(double theta) {
    final wave = math.cos(theta * 5);
    final point = math.pow(math.max(0, wave), 2.4).toDouble();
    final valley = math.pow(math.max(0, -wave), 1.2).toDouble();
    return 0.7 + point * 0.26 - valley * 0.1;
  }

  double _triangleRadius(double theta) {
    const sides = 3;
    const sector = math.pi * 2 / sides;
    final normalized =
        ((theta + math.pi / 2 + sector / 2) % sector) - sector / 2;
    return 0.58 / math.cos(normalized) + 0.03;
  }

  double _ease(double value) {
    return value * value * (3 - 2 * value);
  }

  double _lerp(double from, double to, double value) {
    return from + (to - from) * value;
  }

  @override
  bool shouldRepaint(covariant _MorphingPortraitPainter oldDelegate) {
    return oldDelegate.accent != accent ||
        oldDelegate.morph != morph ||
        oldDelegate.phase != phase;
  }
}
