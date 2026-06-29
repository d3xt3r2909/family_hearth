import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/play_session.dart';
import '../../i18n/app_localizations.dart';
import 'play_sound_effects.dart';

class ChildPlaySurface extends StatefulWidget {
  const ChildPlaySurface({
    super.key,
    required this.session,
    required this.onAnswer,
    this.overlay = false,
  });

  final PlaySession session;
  final ValueChanged<String> onAnswer;
  final bool overlay;

  @override
  State<ChildPlaySurface> createState() => _ChildPlaySurfaceState();
}

class _ChildPlaySurfaceState extends State<ChildPlaySurface> {
  String? _lastPlayedPromptSignature;
  int _tapBurst = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPromptSound());
  }

  @override
  void didUpdateWidget(covariant ChildPlaySurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    _playPromptSound();
  }

  void _playPromptSound() {
    final session = widget.session;
    if (!session.isPrompting) {
      return;
    }

    final signature =
        '${session.id}-${session.activity.name}-${session.targetKey}-${session.updatedAt.microsecondsSinceEpoch}';
    if (signature == _lastPlayedPromptSignature) {
      return;
    }
    _lastPlayedPromptSignature = signature;
    unawaited(PlaySoundEffects.playMoment(session.activity, session.targetKey));
  }

  void _handleSurfaceTap() {
    final session = widget.session;
    if (!session.hasPrompt) {
      return;
    }

    Feedback.forTap(context);
    setState(() => _tapBurst += 1);
    unawaited(
      PlaySoundEffects.playBabyTouch(session.activity, session.targetKey),
    );
    if (session.isPrompting) {
      widget.onAnswer(PlaySession.childTouchKey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (!session.hasPrompt) {
      return const SizedBox.shrink();
    }

    final strings = context.t;
    final answered = session.isAnswered;
    final targetLabel = strings.playTargetLabel(session.targetKey);
    final accent = _colorForKey(session.targetKey);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: widget.overlay
            ? BorderRadius.circular(8)
            : BorderRadius.zero,
        onTap: session.hasPrompt ? _handleSurfaceTap : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.overlay
                ? const Color(0xF7FFF7EC)
                : const Color(0xFFFFF7EC),
            borderRadius: widget.overlay
                ? BorderRadius.circular(8)
                : BorderRadius.zero,
            border: widget.overlay ? Border.all(color: accent, width: 3) : null,
            boxShadow: widget.overlay
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _PlaySprinkles(accent: accent)),
              Positioned.fill(
                child: SafeArea(
                  minimum: EdgeInsets.all(widget.overlay ? 18 : 24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 520;
                      final visualSize = widget.overlay
                          ? (compact ? 176.0 : 230.0)
                          : (compact ? 220.0 : 300.0);

                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BabyMomentVisual(
                                session: session,
                                label: targetLabel,
                                accent: accent,
                                size: visualSize,
                                answered: answered,
                                burstIndex: _tapBurst,
                              ),
                              const SizedBox(height: 22),
                              Text(
                                answered
                                    ? strings.playWallBabyJoined
                                    : strings.playWallMoment(
                                        session.activity,
                                        targetLabel,
                                      ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF221B16),
                                  fontSize: widget.overlay
                                      ? (compact ? 28 : 34)
                                      : (compact ? 36 : 52),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              if (session.isPrompting) ...[
                                const SizedBox(height: 12),
                                Text(
                                  strings.playWallTapHint,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF221B16,
                                    ).withValues(alpha: 0.58),
                                    fontSize: widget.overlay ? 18 : 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RelativePlayroomPanel extends StatefulWidget {
  const RelativePlayroomPanel({
    super.key,
    required this.enabled,
    required this.session,
    required this.onSendPrompt,
    required this.onClear,
  });

  final bool enabled;
  final PlaySession session;
  final void Function(PlayActivity activity, String targetKey) onSendPrompt;
  final VoidCallback onClear;

  @override
  State<RelativePlayroomPanel> createState() => _RelativePlayroomPanelState();
}

class _RelativePlayroomPanelState extends State<RelativePlayroomPanel> {
  PlayActivity _activity = PlayActivity.babyBeats;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final targetKeys = PlayActivityCatalog.optionsFor(_activity);
    final session = widget.session;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 36),
        Row(
          children: [
            const Icon(Icons.toys_rounded, color: Color(0xFFE85D43)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                strings.playroom,
                style: const TextStyle(
                  color: Color(0xFF221B16),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (session.hasPrompt)
              IconButton(
                tooltip: strings.clearPlay,
                onPressed: widget.enabled ? widget.onClear : null,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final activity in PlayActivity.values)
              ChoiceChip(
                selected: _activity == activity,
                label: Text(strings.playActivityLabel(activity)),
                avatar: Icon(_activityIcon(activity), size: 18),
                onSelected: widget.enabled
                    ? (_) => setState(() => _activity = activity)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final key in targetKeys)
              _RelativeMomentButton(
                keyValue: key,
                label: strings.playTargetLabel(key),
                activity: _activity,
                enabled: widget.enabled,
                onPressed: () => widget.onSendPrompt(_activity, key),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _PlayroomStatus(session: session),
      ],
    );
  }
}

class _PlayroomStatus extends StatelessWidget {
  const _PlayroomStatus({required this.session});

  final PlaySession session;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final text = switch (session.status) {
      PlaySessionStatus.idle => strings.playroomReady,
      PlaySessionStatus.prompting => strings.playWaitingForChild,
      PlaySessionStatus.answered => strings.playChildResponded,
    };

    return Row(
      children: [
        Icon(
          session.status == PlaySessionStatus.answered
              ? Icons.touch_app_rounded
              : Icons.auto_awesome_rounded,
          color: const Color(0xFF197A6E),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF5F534A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RelativeMomentButton extends StatelessWidget {
  const _RelativeMomentButton({
    required this.keyValue,
    required this.label,
    required this.activity,
    required this.enabled,
    required this.onPressed,
  });

  final String keyValue;
  final String label;
  final PlayActivity activity;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = _colorForKey(keyValue);

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: _foregroundFor(color),
        minimumSize: const Size(122, 54),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: enabled
          ? () {
              unawaited(PlaySoundEffects.playMoment(activity, keyValue));
              onPressed();
            }
          : null,
      icon: Icon(_iconFor(activity, keyValue)),
      label: Text(label),
    );
  }
}

class _BabyMomentVisual extends StatelessWidget {
  const _BabyMomentVisual({
    required this.session,
    required this.label,
    required this.accent,
    required this.size,
    required this.answered,
    required this.burstIndex,
  });

  final PlaySession session;
  final String label;
  final Color accent;
  final double size;
  final bool answered;
  final int burstIndex;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(
        '${session.activity.name}-${session.targetKey}-${session.updatedAt.microsecondsSinceEpoch}-$answered-$burstIndex',
      ),
      tween: Tween(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _PulseHalo(
                accent: answered ? const Color(0xFF197A6E) : accent,
              ),
            ),
            Positioned.fill(
              child: _CelebrationBurst(
                accent: answered ? const Color(0xFF197A6E) : accent,
                foreground: _foregroundFor(
                  answered ? const Color(0xFF197A6E) : accent,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: answered ? const Color(0xFF197A6E) : accent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.32),
                      blurRadius: 34,
                      spreadRadius: 3,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: _MomentGraphic(
                  activity: session.activity,
                  keyValue: session.targetKey,
                  label: label,
                  foreground: _foregroundFor(
                    answered ? const Color(0xFF197A6E) : accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PulseHalo extends StatelessWidget {
  const _PulseHalo({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 680),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 1 + value * 0.24,
          child: Opacity(
            opacity: 1 - value,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CelebrationBurst extends StatelessWidget {
  const _CelebrationBurst({required this.accent, required this.foreground});

  final Color accent;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 720),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return CustomPaint(
          painter: _CelebrationBurstPainter(
            progress: value,
            accent: accent,
            foreground: foreground,
          ),
        );
      },
    );
  }
}

class _CelebrationBurstPainter extends CustomPainter {
  const _CelebrationBurstPainter({
    required this.progress,
    required this.accent,
    required this.foreground,
  });

  final double progress;
  final Color accent;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.68;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var index = 0; index < 12; index += 1) {
      final angle = -math.pi / 2 + index * math.pi / 6;
      final distance = maxRadius * Curves.easeOut.transform(progress);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final opacity = (1 - progress).clamp(0.0, 1.0);
      final color = index.isEven ? accent : foreground;
      paint.color = color.withValues(alpha: opacity * 0.72);

      if (index % 3 == 0) {
        _drawTriangle(canvas, point, 12 + index % 4 * 2, angle, paint);
      } else {
        canvas.drawCircle(point, 7 + index % 4 * 2, paint);
      }
    }
  }

  void _drawTriangle(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Paint paint,
  ) {
    final path = Path();
    for (var index = 0; index < 3; index += 1) {
      final pointAngle = angle + index * math.pi * 2 / 3;
      final point =
          center + Offset(math.cos(pointAngle), math.sin(pointAngle)) * radius;
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
  bool shouldRepaint(covariant _CelebrationBurstPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.foreground != foreground;
  }
}

class _MomentGraphic extends StatelessWidget {
  const _MomentGraphic({
    required this.activity,
    required this.keyValue,
    required this.label,
    required this.foreground,
  });

  final PlayActivity activity;
  final String keyValue;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    if (activity == PlayActivity.bubbles) {
      return _BubbleMoment(label: label, foreground: foreground);
    }

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_iconFor(activity, keyValue), color: foreground, size: 86),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foreground,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BubbleMoment extends StatelessWidget {
  const _BubbleMoment({required this.label, required this.foreground});

  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 34,
          top: 40,
          child: _SmallCircle(size: 54, color: foreground),
        ),
        Positioned(
          right: 42,
          top: 58,
          child: _SmallCircle(size: 78, color: foreground),
        ),
        Positioned(
          left: 64,
          bottom: 54,
          child: _SmallCircle(size: 96, color: foreground),
        ),
        Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallCircle extends StatelessWidget {
  const _SmallCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.55), width: 4),
      ),
    );
  }
}

class _PlaySprinkles extends StatefulWidget {
  const _PlaySprinkles({required this.accent});

  final Color accent;

  @override
  State<_PlaySprinkles> createState() => _PlaySprinklesState();
}

class _PlaySprinklesState extends State<_PlaySprinkles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlaySprinklesPainter(widget.accent, _controller),
    );
  }
}

class _PlaySprinklesPainter extends CustomPainter {
  _PlaySprinklesPainter(this.accent, this.animation)
    : super(repaint: animation);

  final Color accent;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final progress = animation.value * math.pi * 2;
    final marks = [
      (accent, 0.10, 0.16, 18.0),
      (const Color(0xFFFFB545), 0.84, 0.14, 22.0),
      (const Color(0xFFE85D43), 0.16, 0.78, 14.0),
      (const Color(0xFF4967B1), 0.88, 0.72, 16.0),
      (const Color(0xFF197A6E), 0.50, 0.90, 12.0),
    ];

    for (var index = 0; index < marks.length; index += 1) {
      final mark = marks[index];
      final bob = math.sin(progress + index * 1.7) * 9;
      final drift = math.cos(progress * 0.7 + index * 1.1) * 8;
      paint.color = mark.$1.withValues(alpha: 0.22);
      final center = Offset(
        size.width * mark.$2 + drift,
        size.height * mark.$3 + bob,
      );
      if (index == 2) {
        _drawSoftTriangle(canvas, center, mark.$4 + 6, progress, paint);
      } else {
        canvas.drawCircle(center, mark.$4, paint);
      }
    }
  }

  void _drawSoftTriangle(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    for (var index = 0; index < 3; index += 1) {
      final angle = rotation + index * math.pi * 2 / 3;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
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
  bool shouldRepaint(covariant _PlaySprinklesPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.animation != animation;
  }
}

IconData _activityIcon(PlayActivity activity) => switch (activity) {
  PlayActivity.babyBeats => Icons.graphic_eq_rounded,
  PlayActivity.peekaboo => Icons.face_rounded,
  PlayActivity.bubbles => Icons.bubble_chart_rounded,
  PlayActivity.clapAlong => Icons.waving_hand_rounded,
  PlayActivity.animalSounds => Icons.pets_rounded,
};

IconData _iconFor(PlayActivity activity, String key) {
  return switch (key) {
    'boom' => Icons.radio_button_checked_rounded,
    'ding' => Icons.notifications_rounded,
    'whoosh' => Icons.air_rounded,
    'peekaboo' => Icons.face_rounded,
    'hello' => Icons.waving_hand_rounded,
    'smile' => Icons.sentiment_very_satisfied_rounded,
    'bubbles' => Icons.bubble_chart_rounded,
    'stars' => Icons.star_rounded,
    'rainbow' => Icons.auto_awesome_rounded,
    'clap' => Icons.front_hand_rounded,
    'wave' => Icons.waving_hand_rounded,
    'dance' => Icons.directions_run_rounded,
    'dog' || 'cat' || 'cow' => Icons.pets_rounded,
    _ => _activityIcon(activity),
  };
}

Color _colorForKey(String key) => switch (key) {
  'boom' => const Color(0xFFE85D43),
  'ding' => const Color(0xFFFFB545),
  'whoosh' => const Color(0xFF4967B1),
  'peekaboo' => const Color(0xFFE85D43),
  'hello' => const Color(0xFF197A6E),
  'smile' => const Color(0xFFFFB545),
  'bubbles' => const Color(0xFF4967B1),
  'stars' => const Color(0xFFFFB545),
  'rainbow' => const Color(0xFFE85D43),
  'clap' => const Color(0xFFE85D43),
  'wave' => const Color(0xFF197A6E),
  'dance' => const Color(0xFF4967B1),
  'dog' => const Color(0xFF197A6E),
  'cat' => const Color(0xFFE85D43),
  'cow' => const Color(0xFF4967B1),
  _ => const Color(0xFFE85D43),
};

Color _foregroundFor(Color color) {
  return color.computeLuminance() > 0.55
      ? const Color(0xFF221B16)
      : Colors.white;
}
