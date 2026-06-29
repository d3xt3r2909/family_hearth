import 'package:flutter/material.dart';

import '../../domain/play_session.dart';
import '../../i18n/app_localizations.dart';

class ChildPlaySurface extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!session.hasPrompt) {
      return const SizedBox.shrink();
    }

    final strings = context.t;
    final answered = session.isAnswered;
    final correct = session.childResponseCorrect ?? false;
    final targetLabel = strings.playTargetLabel(session.targetKey);

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: overlay ? const Color(0xF7FFF7EC) : const Color(0xFFFFF7EC),
          borderRadius: overlay ? BorderRadius.circular(8) : BorderRadius.zero,
          border: overlay
              ? Border.all(color: const Color(0xFFFFB545), width: 3)
              : null,
          boxShadow: overlay
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
            const Positioned.fill(child: _PlaySprinkles()),
            Positioned.fill(
              child: SafeArea(
                minimum: EdgeInsets.all(overlay ? 18 : 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final tileSize = constraints.maxWidth > 900
                        ? 190.0
                        : constraints.maxWidth > 560
                        ? 164.0
                        : 132.0;

                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _activityIcon(session.activity),
                              color: const Color(0xFFE85D43),
                              size: overlay ? 44 : 64,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              answered
                                  ? correct
                                        ? strings.playWallCorrect(targetLabel)
                                        : strings.playWallTryAgain
                                  : strings.playWallPrompt(
                                      session.activity,
                                      targetLabel,
                                    ),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF221B16),
                                fontSize: overlay ? 30 : 44,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                for (final option in session.options)
                                  _ChildAnswerButton(
                                    keyValue: option,
                                    label: strings.playTargetLabel(option),
                                    activity: session.activity,
                                    selected:
                                        answered &&
                                        option == session.childResponseKey,
                                    enabled: session.isPrompting,
                                    size: tileSize,
                                    onPressed: () => onAnswer(option),
                                  ),
                              ],
                            ),
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
  PlayActivity _activity = PlayActivity.colorPop;

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
              _RelativePromptButton(
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
      PlaySessionStatus.prompting => strings.playWaitingForChild(
        strings.playTargetLabel(session.targetKey),
      ),
      PlaySessionStatus.answered => strings.playChildAnswered(
        strings.playTargetLabel(session.childResponseKey ?? ''),
        session.childResponseCorrect ?? false,
      ),
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

class _RelativePromptButton extends StatelessWidget {
  const _RelativePromptButton({
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
        minimumSize: const Size(132, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: enabled ? onPressed : null,
      icon: Icon(_iconFor(activity, keyValue)),
      label: Text(label),
    );
  }
}

class _ChildAnswerButton extends StatelessWidget {
  const _ChildAnswerButton({
    required this.keyValue,
    required this.label,
    required this.activity,
    required this.selected,
    required this.enabled,
    required this.size,
    required this.onPressed,
  });

  final String keyValue;
  final String label;
  final PlayActivity activity;
  final bool selected;
  final bool enabled;
  final double size;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = _colorForKey(keyValue);
    final foreground = _foregroundFor(color);

    return SizedBox.square(
      dimension: size,
      child: Material(
        color: selected ? const Color(0xFF197A6E) : color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.check_rounded : _iconFor(activity, keyValue),
                  color: foreground,
                  size: size * 0.38,
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaySprinkles extends StatelessWidget {
  const _PlaySprinkles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PlaySprinklesPainter());
  }
}

class _PlaySprinklesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final dots = [
      (const Color(0xFFFFB545), 0.10, 0.16, 18.0),
      (const Color(0xFFD9F0DF), 0.84, 0.14, 22.0),
      (const Color(0xFFE85D43), 0.16, 0.78, 14.0),
      (const Color(0xFF4967B1), 0.88, 0.72, 16.0),
      (const Color(0xFF197A6E), 0.50, 0.90, 12.0),
    ];

    for (final dot in dots) {
      paint.color = dot.$1.withValues(alpha: 0.28);
      canvas.drawCircle(
        Offset(size.width * dot.$2, size.height * dot.$3),
        dot.$4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

IconData _activityIcon(PlayActivity activity) => switch (activity) {
  PlayActivity.colorPop => Icons.palette_rounded,
  PlayActivity.findShape => Icons.category_rounded,
  PlayActivity.peekabooBox => Icons.inventory_2_rounded,
};

IconData _iconFor(PlayActivity activity, String key) {
  if (activity == PlayActivity.peekabooBox) {
    return Icons.inventory_2_rounded;
  }

  return switch (key) {
    'star' => Icons.star_rounded,
    'triangle' => Icons.change_history_rounded,
    'circle' => Icons.circle,
    _ => Icons.circle,
  };
}

Color _colorForKey(String key) => switch (key) {
  'red' => const Color(0xFFE85D43),
  'yellow' => const Color(0xFFFFB545),
  'blue' => const Color(0xFF4967B1),
  'green' => const Color(0xFF197A6E),
  'star' => const Color(0xFFFFB545),
  'triangle' => const Color(0xFFE85D43),
  'circle' => const Color(0xFF4967B1),
  'box1' => const Color(0xFFE85D43),
  'box2' => const Color(0xFF197A6E),
  'box3' => const Color(0xFF4967B1),
  _ => const Color(0xFFE85D43),
};

Color _foregroundFor(Color color) {
  return color.computeLuminance() > 0.55
      ? const Color(0xFF221B16)
      : Colors.white;
}
