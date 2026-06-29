import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/family_contact.dart';
import '../../i18n/app_localizations.dart';

class ContactTile extends StatefulWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.enabled,
    required this.onPressed,
  });

  final FamilyContact contact;
  final bool enabled;
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
        final scale = widget.enabled ? 1.0 + pulse * 0.014 : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Semantics(
        button: true,
        label: context.t.callPerson(widget.contact.displayName),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          elevation: widget.enabled ? 14 : 2,
          shadowColor: accent.withValues(alpha: 0.28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            child: Ink(
              decoration: BoxDecoration(
                border: Border.all(
                  color: accent.withValues(alpha: 0.34),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _PortraitBackdropPainter(
                            accent: accent,
                            morph: _controller,
                          ),
                        ),
                        Center(
                          child: FractionallySizedBox(
                            widthFactor: 0.68,
                            heightFactor: 0.68,
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
                                  size: 74,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 14,
                          child: _MediaBadge(accent: accent),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    color: const Color(0xFF221B16),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.contact.displayName,
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.contact.relationship,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
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

class _MediaBadge extends StatelessWidget {
  const _MediaBadge({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xEEFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Icon(Icons.play_arrow_rounded, color: accent, size: 30),
    );
  }
}

class _PortraitBackdropPainter extends CustomPainter {
  _PortraitBackdropPainter({required this.accent, required this.morph})
    : super(repaint: morph);

  final Color accent;
  final Animation<double> morph;

  @override
  void paint(Canvas canvas, Size size) {
    final pulse = math.sin(morph.value * math.pi * 2);
    final base = Paint()..style = PaintingStyle.fill;

    base.color = accent;
    canvas.drawRect(Offset.zero & size, base);

    base.color = Color.alphaBlend(Colors.white.withValues(alpha: 0.22), accent);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * (0.7 + pulse * 0.025))
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * (0.5 - pulse * 0.035),
          size.width,
          size.height * (0.76 - pulse * 0.02),
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      base,
    );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: 0.22);

    for (var i = 0; i < 4; i++) {
      final top = size.height * (0.15 + i * 0.16);
      canvas.drawLine(
        Offset(size.width * (0.1 + pulse * 0.018), top),
        Offset(size.width * (0.9 - pulse * 0.018), top + size.height * 0.08),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PortraitBackdropPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.morph != morph;
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
