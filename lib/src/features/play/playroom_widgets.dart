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
    this.onBoardStroke,
    this.onBoardSticker,
    this.actorId = 'child-wall',
    this.interactive = true,
    this.overlay = false,
    this.playfulButton = false,
  });

  final PlaySession session;
  final ValueChanged<String> onAnswer;
  final ValueChanged<PlayBoardStroke>? onBoardStroke;
  final ValueChanged<PlayBoardSticker>? onBoardSticker;
  final String actorId;
  final bool interactive;
  final bool overlay;
  final bool playfulButton;

  @override
  State<ChildPlaySurface> createState() => _ChildPlaySurfaceState();
}

class _ChildPlaySurfaceState extends State<ChildPlaySurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _buttonMotion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
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

  @override
  void dispose() {
    _buttonMotion.dispose();
    super.dispose();
  }

  void _handleBoardStroke(PlayBoardStroke stroke) {
    if (!widget.interactive) {
      return;
    }
    widget.onBoardStroke?.call(stroke);
    _answerPromptFromBoard();
  }

  void _handleBoardSticker(PlayBoardSticker sticker) {
    if (!widget.interactive) {
      return;
    }
    widget.onBoardSticker?.call(sticker);
    _answerPromptFromBoard();
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
    if (!widget.interactive) {
      return;
    }
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

  void _answerPromptFromBoard() {
    if (!widget.interactive || !widget.session.isPrompting) {
      return;
    }
    widget.onAnswer(PlaySession.childTouchKey);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    if (!session.hasPlaySurface) {
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
        onTap: widget.interactive && session.hasPrompt && !session.hasBoard
            ? _handleSurfaceTap
            : null,
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
              if (session.hasBoard)
                Positioned.fill(
                  child: _PlayBoardSurface(
                    strokes: session.boardStrokes,
                    stickers: session.boardStickers,
                    actorId: widget.actorId,
                    enabled:
                        widget.interactive &&
                        (widget.onBoardStroke != null ||
                            widget.onBoardSticker != null),
                    onStrokeAdded: _handleBoardStroke,
                    onStickerChanged: _handleBoardSticker,
                    colorValue: 0xFF197A6E,
                    showStickerTray: widget.interactive,
                    fullBleed: true,
                  ),
                )
              else
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

                      if (session.hasBoard && !session.hasPrompt) {
                        return const SizedBox.shrink();
                      }

                      if (session.hasBoard) {
                        if (session.isPrompting) {
                          return Align(
                            alignment: Alignment.topCenter,
                            child: _BoardPromptCallout(
                              session: session,
                              label: targetLabel,
                              accent: accent,
                              compact: compact,
                              animation: _buttonMotion,
                              burstIndex: _tapBurst,
                              onTap: _handleSurfaceTap,
                            ),
                          );
                        }

                        return Align(
                          alignment: Alignment.topLeft,
                          child: IgnorePointer(
                            child: _BoardPromptBadge(
                              session: session,
                              label: targetLabel,
                              accent: accent,
                              answered: answered,
                            ),
                          ),
                        );
                      }

                      return Align(
                        alignment: Alignment.center,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PlayfulBabyButtonMotion(
                                enabled: widget.playfulButton,
                                animation: _buttonMotion,
                                accent: accent,
                                child: _BabyMomentVisual(
                                  session: session,
                                  label: targetLabel,
                                  accent: accent,
                                  size: visualSize,
                                  answered: answered,
                                  burstIndex: _tapBurst,
                                ),
                              ),
                              SizedBox(height: session.hasBoard ? 12 : 22),
                              Text(
                                answered
                                    ? strings.playWallBabyJoined
                                    : strings.playWallMoment(
                                        session.activity,
                                        targetLabel,
                                      ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: session.hasBoard
                                      ? Colors.white
                                      : const Color(0xFF221B16),
                                  fontSize: widget.overlay
                                      ? (compact ? 28 : 34)
                                      : session.hasBoard
                                      ? (compact ? 28 : 36)
                                      : (compact ? 36 : 52),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                  shadows: session.hasBoard
                                      ? const [
                                          Shadow(
                                            color: Color(0x99000000),
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              if (session.isPrompting && !session.hasBoard) ...[
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

class _BoardPromptCallout extends StatelessWidget {
  const _BoardPromptCallout({
    required this.session,
    required this.label,
    required this.accent,
    required this.compact,
    required this.animation,
    required this.burstIndex,
    required this.onTap,
  });

  final PlaySession session;
  final String label;
  final Color accent;
  final bool compact;
  final Animation<double> animation;
  final int burstIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final visualSize = compact ? 118.0 : 148.0;

    return Material(
      color: const Color(0xF7FFFFFF),
      elevation: 18,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accent, width: 3),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 270 : 330),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayfulBabyButtonMotion(
                  enabled: true,
                  animation: animation,
                  accent: accent,
                  child: _BabyMomentVisual(
                    session: session,
                    label: label,
                    accent: accent,
                    size: visualSize,
                    answered: false,
                    burstIndex: burstIndex,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  strings.playWallMoment(session.activity, label),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF221B16),
                    fontSize: compact ? 24 : 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.playWallTapHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF221B16).withValues(alpha: 0.58),
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w900,
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

class _BoardPromptBadge extends StatelessWidget {
  const _BoardPromptBadge({
    required this.session,
    required this.label,
    required this.accent,
    required this.answered,
  });

  final PlaySession session;
  final String label;
  final Color accent;
  final bool answered;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Material(
      color: const Color(0xEFFFFFFF),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: accent, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconFor(session.activity, session.targetKey), color: accent),
            const SizedBox(width: 8),
            Text(
              answered
                  ? strings.playWallBabyJoined
                  : strings.playWallMoment(session.activity, label),
              style: const TextStyle(
                color: Color(0xFF221B16),
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RelativePlayroomPanel extends StatelessWidget {
  const RelativePlayroomPanel({
    super.key,
    required this.enabled,
    required this.session,
    required this.actorId,
    required this.onSendPrompt,
    required this.onBoardStroke,
    required this.onBoardSticker,
    required this.onClearBoard,
    required this.onClear,
    this.boardHeight,
  });

  final bool enabled;
  final PlaySession session;
  final String actorId;
  final void Function(PlayActivity activity, String targetKey) onSendPrompt;
  final ValueChanged<PlayBoardStroke> onBoardStroke;
  final ValueChanged<PlayBoardSticker> onBoardSticker;
  final VoidCallback onClearBoard;
  final VoidCallback onClear;
  final double? boardHeight;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;
    final promptOptions = PlayActivityCatalog.promptOptions;

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
            if (session.hasPrompt || session.hasBoard)
              IconButton(
                tooltip: strings.clearPlay,
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _RelativeBoardPanel(
          enabled: enabled,
          actorId: actorId,
          strokes: session.boardStrokes,
          stickers: session.boardStickers,
          height: boardHeight,
          onStrokeAdded: onBoardStroke,
          onStickerChanged: onBoardSticker,
          onClear: onClearBoard,
        ),
        const SizedBox(height: 14),
        if (session.hasBoard) ...[
          _CompactMomentStrip(
            enabled: enabled,
            options: promptOptions,
            onSelected: onSendPrompt,
          ),
          const SizedBox(height: 14),
        ] else ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in promptOptions)
                _RelativeMomentButton(
                  keyValue: option.key,
                  label: strings.playTargetLabel(option.key),
                  activity: option.activity,
                  enabled: enabled,
                  onPressed: () => onSendPrompt(option.activity, option.key),
                ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        _PlayroomStatus(session: session),
      ],
    );
  }
}

class _CompactMomentStrip extends StatelessWidget {
  const _CompactMomentStrip({
    required this.enabled,
    required this.options,
    required this.onSelected,
  });

  final bool enabled;
  final List<PlayPromptOption> options;
  final void Function(PlayActivity activity, String key) onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final color = _colorForKey(option.key);

          return Tooltip(
            message: strings.playTargetLabel(option.key),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: color.withValues(alpha: 0.14),
                foregroundColor: color,
                disabledBackgroundColor: const Color(0xFFE8DED5),
                disabledForegroundColor: const Color(0xFF8A7C71),
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: color.withValues(alpha: 0.32)),
                ),
              ),
              onPressed: enabled
                  ? () {
                      unawaited(
                        PlaySoundEffects.playMoment(
                          option.activity,
                          option.key,
                        ),
                      );
                      onSelected(option.activity, option.key);
                    }
                  : null,
              child: Icon(_iconFor(option.activity, option.key), size: 22),
            ),
          );
        },
      ),
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

class _RelativeBoardPanel extends StatelessWidget {
  const _RelativeBoardPanel({
    required this.enabled,
    required this.actorId,
    required this.strokes,
    required this.stickers,
    required this.height,
    required this.onStrokeAdded,
    required this.onStickerChanged,
    required this.onClear,
  });

  final bool enabled;
  final String actorId;
  final List<PlayBoardStroke> strokes;
  final List<PlayBoardSticker> stickers;
  final double? height;
  final ValueChanged<PlayBoardStroke> onStrokeAdded;
  final ValueChanged<PlayBoardSticker> onStickerChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF4967B1)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                strings.magicBoard,
                style: const TextStyle(
                  color: Color(0xFF221B16),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (strokes.isNotEmpty || stickers.isNotEmpty)
              IconButton(
                tooltip: strings.clearBoard,
                onPressed: enabled ? onClear : null,
                icon: const Icon(Icons.cleaning_services_rounded),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: height ?? 260,
          child: _PlayBoardSurface(
            strokes: strokes,
            stickers: stickers,
            actorId: actorId,
            enabled: enabled,
            onStrokeAdded: onStrokeAdded,
            onStickerChanged: onStickerChanged,
            colorValue: 0xFFE85D43,
            showStickerTray: true,
          ),
        ),
      ],
    );
  }
}

class _PlayBoardSurface extends StatefulWidget {
  const _PlayBoardSurface({
    required this.strokes,
    required this.stickers,
    required this.actorId,
    required this.enabled,
    required this.onStrokeAdded,
    required this.onStickerChanged,
    required this.colorValue,
    this.showStickerTray = false,
    this.fullBleed = false,
  });

  final List<PlayBoardStroke> strokes;
  final List<PlayBoardSticker> stickers;
  final String actorId;
  final bool enabled;
  final ValueChanged<PlayBoardStroke> onStrokeAdded;
  final ValueChanged<PlayBoardSticker> onStickerChanged;
  final int colorValue;
  final bool showStickerTray;
  final bool fullBleed;

  @override
  State<_PlayBoardSurface> createState() => _PlayBoardSurfaceState();
}

class _PlayBoardSurfaceState extends State<_PlayBoardSurface> {
  static const _minimumPointDistance = 0.009;
  static const _stickerKeys = ['dog', 'cat', 'cow'];
  static const _stickerSize = 74.0;

  final _boardKey = GlobalKey();
  final _latestStickerDragPositions = <_StickerDragPayload, Offset>{};
  List<PlayBoardPoint> _draftPoints = const [];

  void _beginStroke(Offset localPosition, Size size) {
    if (!widget.enabled) {
      return;
    }
    setState(() => _draftPoints = [_pointFor(localPosition, size)]);
  }

  void _appendStrokePoint(Offset localPosition, Size size) {
    if (!widget.enabled || _draftPoints.isEmpty) {
      return;
    }

    final nextPoint = _pointFor(localPosition, size);
    final lastPoint = _draftPoints.last;
    final distance = math.sqrt(
      math.pow(nextPoint.x - lastPoint.x, 2) +
          math.pow(nextPoint.y - lastPoint.y, 2),
    );
    if (distance < _minimumPointDistance) {
      return;
    }

    setState(() => _draftPoints = [..._draftPoints, nextPoint]);
  }

  void _commitDraft() {
    if (!widget.enabled || _draftPoints.isEmpty) {
      setState(() => _draftPoints = const []);
      return;
    }

    final now = DateTime.now();
    final stroke = PlayBoardStroke(
      id: 'stroke-${now.microsecondsSinceEpoch}',
      actorId: widget.actorId,
      colorValue: widget.colorValue,
      points: _draftPoints,
      createdAt: now,
    );

    setState(() => _draftPoints = const []);
    widget.onStrokeAdded(stroke);
  }

  void _commitStickerDragEnd(
    _StickerDragPayload payload,
    DraggableDetails details,
    double feedbackSize,
  ) {
    if (!widget.enabled) {
      return;
    }

    final dropCenter =
        _latestStickerDragPositions.remove(payload) ??
        details.offset + Offset(feedbackSize / 2, feedbackSize / 2);
    _commitStickerAtGlobal(payload, dropCenter);
  }

  void _trackStickerDrag(
    _StickerDragPayload payload,
    DragUpdateDetails details,
  ) {
    if (!widget.enabled) {
      return;
    }
    _latestStickerDragPositions[payload] = details.globalPosition;
  }

  void _commitStickerAtGlobal(
    _StickerDragPayload payload,
    Offset globalPosition,
  ) {
    final context = _boardKey.currentContext;
    if (context == null) {
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return;
    }

    final local = box.globalToLocal(globalPosition);
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx > box.size.width ||
        local.dy > box.size.height) {
      return;
    }

    _commitStickerAt(payload, local, box.size);
  }

  void _commitStickerAt(_StickerDragPayload payload, Offset local, Size size) {
    final point = _pointFor(local, size);
    final now = DateTime.now();
    widget.onStickerChanged(
      PlayBoardSticker(
        id: payload.id ?? 'sticker-${now.microsecondsSinceEpoch}',
        actorId: widget.actorId,
        key: payload.key,
        x: point.x,
        y: point.y,
        colorValue: _stickerColorFor(payload.key).toARGB32(),
        createdAt: payload.createdAt ?? now,
      ),
    );
  }

  void _addStickerFromTap(String key, Size size) {
    if (!widget.enabled) {
      return;
    }

    final count = widget.stickers.length;
    final x = 0.32 + (count % 3) * 0.18;
    final y = 0.34 + ((count ~/ 3) % 3) * 0.18;
    _commitStickerAt(
      _StickerDragPayload(key: key),
      Offset(x * size.width, y * size.height),
      size,
    );
  }

  void _commitTap(Offset localPosition, Size size) {
    if (!widget.enabled) {
      return;
    }

    final now = DateTime.now();
    widget.onStrokeAdded(
      PlayBoardStroke(
        id: 'stroke-${now.microsecondsSinceEpoch}',
        actorId: widget.actorId,
        colorValue: widget.colorValue,
        points: [_pointFor(localPosition, size)],
        createdAt: now,
      ),
    );
  }

  PlayBoardPoint _pointFor(Offset localPosition, Size size) {
    final width = math.max(size.width, 1);
    final height = math.max(size.height, 1);
    return PlayBoardPoint(
      x: (localPosition.dx / width).clamp(0.0, 1.0).toDouble(),
      y: (localPosition.dy / height).clamp(0.0, 1.0).toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.precise
              : SystemMouseCursors.basic,
          child: ClipRRect(
            key: _boardKey,
            borderRadius: BorderRadius.circular(widget.fullBleed ? 0 : 8),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF2),
                borderRadius: BorderRadius.circular(widget.fullBleed ? 0 : 8),
                border: widget.fullBleed
                    ? null
                    : Border.all(color: const Color(0xFFE3D8CD)),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: widget.enabled
                          ? (details) => _commitTap(details.localPosition, size)
                          : null,
                      onPanStart: widget.enabled
                          ? (details) =>
                                _beginStroke(details.localPosition, size)
                          : null,
                      onPanUpdate: widget.enabled
                          ? (details) =>
                                _appendStrokePoint(details.localPosition, size)
                          : null,
                      onPanEnd: widget.enabled ? (_) => _commitDraft() : null,
                      onPanCancel: widget.enabled ? _commitDraft : null,
                      child: CustomPaint(
                        painter: _PlayBoardPainter(
                          strokes: widget.strokes,
                          stickers: widget.stickers,
                          draftPoints: _draftPoints,
                          draftColorValue: widget.colorValue,
                          fullBleed: widget.fullBleed,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                  for (final sticker in widget.stickers)
                    _PositionedBoardSticker(
                      sticker: sticker,
                      boardSize: size,
                      enabled: widget.enabled,
                      onDragUpdate: _trackStickerDrag,
                      onDragEnd: _commitStickerDragEnd,
                    ),
                  if (widget.showStickerTray)
                    Positioned(
                      left: widget.fullBleed ? 22 : 12,
                      right: widget.fullBleed ? 22 : 12,
                      bottom: widget.fullBleed ? 22 : 12,
                      child: _StickerTray(
                        enabled: widget.enabled,
                        keys: _stickerKeys,
                        onStickerTap: (key) => _addStickerFromTap(key, size),
                        onStickerDragUpdate: _trackStickerDrag,
                        onStickerDragEnd: _commitStickerDragEnd,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StickerDragPayload {
  const _StickerDragPayload({required this.key, this.id, this.createdAt});

  final String key;
  final String? id;
  final DateTime? createdAt;
}

typedef _StickerDragEndCallback =
    void Function(
      _StickerDragPayload payload,
      DraggableDetails details,
      double feedbackSize,
    );
typedef _StickerDragUpdateCallback =
    void Function(_StickerDragPayload payload, DragUpdateDetails details);

class _StickerTray extends StatelessWidget {
  const _StickerTray({
    required this.enabled,
    required this.keys,
    required this.onStickerTap,
    required this.onStickerDragUpdate,
    required this.onStickerDragEnd,
  });

  final bool enabled;
  final List<String> keys;
  final ValueChanged<String> onStickerTap;
  final _StickerDragUpdateCallback onStickerDragUpdate;
  final _StickerDragEndCallback onStickerDragEnd;

  @override
  Widget build(BuildContext context) {
    const childSize = 58.0;
    const feedbackSize = 78.0;

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.56,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final key in keys)
              _StickerTrayItem(
                keyValue: key,
                childSize: childSize,
                feedbackSize: feedbackSize,
                onTap: () => onStickerTap(key),
                onDragUpdate: onStickerDragUpdate,
                onDragEnd: onStickerDragEnd,
              ),
          ],
        ),
      ),
    );
  }
}

class _StickerTrayItem extends StatelessWidget {
  const _StickerTrayItem({
    required this.keyValue,
    required this.childSize,
    required this.feedbackSize,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final String keyValue;
  final double childSize;
  final double feedbackSize;
  final VoidCallback onTap;
  final _StickerDragUpdateCallback onDragUpdate;
  final _StickerDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final payload = _StickerDragPayload(key: keyValue);

    return Draggable<_StickerDragPayload>(
      data: payload,
      onDragUpdate: (details) => onDragUpdate(payload, details),
      onDragEnd: (details) => onDragEnd(payload, details, feedbackSize),
      feedback: Material(
        color: Colors.transparent,
        child: _AnimalSticker(keyValue: keyValue, size: feedbackSize),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _AnimalSticker(keyValue: keyValue, size: childSize),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: _AnimalSticker(keyValue: keyValue, size: childSize),
      ),
    );
  }
}

class _PositionedBoardSticker extends StatelessWidget {
  const _PositionedBoardSticker({
    required this.sticker,
    required this.boardSize,
    required this.enabled,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final PlayBoardSticker sticker;
  final Size boardSize;
  final bool enabled;
  final _StickerDragUpdateCallback onDragUpdate;
  final _StickerDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final size = _PlayBoardSurfaceState._stickerSize;
    final feedbackSize = size + 8;
    final left = (sticker.x * boardSize.width - size / 2).clamp(
      0.0,
      math.max(0, boardSize.width - size),
    );
    final top = (sticker.y * boardSize.height - size / 2).clamp(
      0.0,
      math.max(0, boardSize.height - size),
    );
    final child = _AnimalSticker(keyValue: sticker.key, size: size);
    final payload = _StickerDragPayload(
      id: sticker.id,
      key: sticker.key,
      createdAt: sticker.createdAt,
    );

    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: enabled
          ? Draggable<_StickerDragPayload>(
              data: payload,
              onDragUpdate: (details) => onDragUpdate(payload, details),
              onDragEnd: (details) => onDragEnd(payload, details, feedbackSize),
              feedback: Material(
                color: Colors.transparent,
                child: _AnimalSticker(
                  keyValue: sticker.key,
                  size: feedbackSize,
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.24, child: child),
              child: child,
            )
          : child,
    );
  }
}

class _AnimalSticker extends StatelessWidget {
  const _AnimalSticker({required this.keyValue, required this.size});

  final String keyValue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _stickerColorFor(keyValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.09),
        child: CustomPaint(
          painter: _AnimalStickerPainter(keyValue: keyValue, accent: color),
        ),
      ),
    );
  }
}

class _AnimalStickerPainter extends CustomPainter {
  const _AnimalStickerPainter({required this.keyValue, required this.accent});

  final String keyValue;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    switch (keyValue) {
      case 'cat':
        _drawCat(canvas, size);
      case 'cow':
        _drawCow(canvas, size);
      case 'dog':
      default:
        _drawDog(canvas, size);
    }
  }

  void _drawDog(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.36;
    final earPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF73533E);
    final facePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFC96F);
    final muzzlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFE4B3);
    final detailPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF332822);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.045
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF332822);

    _drawTiltedOval(
      canvas,
      Offset(size.width * 0.25, size.height * 0.42),
      Size(size.width * 0.24, size.height * 0.38),
      -0.42,
      earPaint,
    );
    _drawTiltedOval(
      canvas,
      Offset(size.width * 0.75, size.height * 0.42),
      Size(size.width * 0.24, size.height * 0.38),
      0.42,
      earPaint,
    );
    canvas.drawCircle(center, radius, facePaint);
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.43),
      radius * 0.12,
      detailPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.43),
      radius * 0.12,
      detailPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.62),
        width: size.width * 0.34,
        height: size.height * 0.24,
      ),
      muzzlePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.56),
        width: size.width * 0.13,
        height: size.height * 0.1,
      ),
      detailPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.61),
      Offset(size.width * 0.5, size.height * 0.68),
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.43, size.height * 0.67),
        width: size.width * 0.18,
        height: size.height * 0.13,
      ),
      0.05,
      math.pi * 0.72,
      false,
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.57, size.height * 0.67),
        width: size.width * 0.18,
        height: size.height * 0.13,
      ),
      math.pi * 0.22,
      math.pi * 0.72,
      false,
      linePaint,
    );
  }

  void _drawCat(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.36;
    final facePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFA05E);
    final earPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFE85D43);
    final innerEarPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFD0C0);
    final detailPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF332822);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.035
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF332822);

    _drawTriangle(canvas, [
      Offset(size.width * 0.23, size.height * 0.33),
      Offset(size.width * 0.38, size.height * 0.08),
      Offset(size.width * 0.49, size.height * 0.36),
    ], earPaint);
    _drawTriangle(canvas, [
      Offset(size.width * 0.51, size.height * 0.36),
      Offset(size.width * 0.62, size.height * 0.08),
      Offset(size.width * 0.77, size.height * 0.33),
    ], earPaint);
    _drawTriangle(canvas, [
      Offset(size.width * 0.33, size.height * 0.28),
      Offset(size.width * 0.38, size.height * 0.17),
      Offset(size.width * 0.44, size.height * 0.3),
    ], innerEarPaint);
    _drawTriangle(canvas, [
      Offset(size.width * 0.56, size.height * 0.3),
      Offset(size.width * 0.62, size.height * 0.17),
      Offset(size.width * 0.67, size.height * 0.28),
    ], innerEarPaint);
    canvas.drawCircle(center, radius, facePaint);
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.45),
      radius * 0.1,
      detailPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.62, size.height * 0.45),
      radius * 0.1,
      detailPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.58),
        width: size.width * 0.11,
        height: size.height * 0.08,
      ),
      Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFE1D7),
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.59),
      Offset(size.width * 0.14, size.height * 0.53),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.35, size.height * 0.65),
      Offset(size.width * 0.14, size.height * 0.68),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.59),
      Offset(size.width * 0.86, size.height * 0.53),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.65, size.height * 0.65),
      Offset(size.width * 0.86, size.height * 0.68),
      linePaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.63),
        width: size.width * 0.24,
        height: size.height * 0.16,
      ),
      0.08,
      math.pi - 0.16,
      false,
      linePaint,
    );
  }

  void _drawCow(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.35;
    final hornPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFDFA4);
    final earPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF4967B1);
    final facePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFF8EB);
    final spotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF332822);
    final muzzlePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFC6C6);
    final detailPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF332822);

    _drawTriangle(canvas, [
      Offset(size.width * 0.36, size.height * 0.2),
      Offset(size.width * 0.31, size.height * 0.03),
      Offset(size.width * 0.46, size.height * 0.16),
    ], hornPaint);
    _drawTriangle(canvas, [
      Offset(size.width * 0.54, size.height * 0.16),
      Offset(size.width * 0.69, size.height * 0.03),
      Offset(size.width * 0.64, size.height * 0.2),
    ], hornPaint);
    _drawTiltedOval(
      canvas,
      Offset(size.width * 0.24, size.height * 0.4),
      Size(size.width * 0.22, size.height * 0.25),
      -0.34,
      earPaint,
    );
    _drawTiltedOval(
      canvas,
      Offset(size.width * 0.76, size.height * 0.4),
      Size(size.width * 0.22, size.height * 0.25),
      0.34,
      earPaint,
    );
    canvas.drawCircle(center, radius, facePaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.4, size.height * 0.34),
        width: size.width * 0.25,
        height: size.height * 0.2,
      ),
      spotPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.66, size.height * 0.47),
        width: size.width * 0.2,
        height: size.height * 0.16,
      ),
      spotPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.47),
      radius * 0.1,
      detailPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.47),
      radius * 0.1,
      detailPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.66),
        width: size.width * 0.4,
        height: size.height * 0.22,
      ),
      muzzlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.43, size.height * 0.65),
      radius * 0.07,
      detailPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.57, size.height * 0.65),
      radius * 0.07,
      detailPaint,
    );
  }

  void _drawTiltedOval(
    Canvas canvas,
    Offset center,
    Size size,
    double rotation,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: size.width,
        height: size.height,
      ),
      paint,
    );
    canvas.restore();
  }

  void _drawTriangle(Canvas canvas, List<Offset> points, Paint paint) {
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimalStickerPainter oldDelegate) {
    return oldDelegate.keyValue != keyValue || oldDelegate.accent != accent;
  }
}

class _PlayBoardPainter extends CustomPainter {
  const _PlayBoardPainter({
    required this.strokes,
    required this.stickers,
    required this.draftPoints,
    required this.draftColorValue,
    required this.fullBleed,
  });

  final List<PlayBoardStroke> strokes;
  final List<PlayBoardSticker> stickers;
  final List<PlayBoardPoint> draftPoints;
  final int draftColorValue;
  final bool fullBleed;

  @override
  void paint(Canvas canvas, Size size) {
    _drawBoardTexture(canvas, size);

    if (strokes.isEmpty && stickers.isEmpty && draftPoints.isEmpty) {
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0xFFFFB545).withValues(alpha: 0.14);
      _drawStar(
        canvas,
        size.center(Offset.zero),
        size.shortestSide * 0.16,
        0,
        paint,
      );
    }

    for (final stroke in strokes) {
      _drawStroke(canvas, size, stroke.points, Color(stroke.colorValue));
    }

    if (draftPoints.isNotEmpty) {
      _drawStroke(canvas, size, draftPoints, Color(draftColorValue));
    }
  }

  void _drawBoardTexture(Canvas canvas, Size size) {
    final background = Paint()
      ..style = PaintingStyle.fill
      ..color = fullBleed ? const Color(0xFFFFF7EC) : const Color(0xFFFFFBF2);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(
        0xFFE3D8CD,
      ).withValues(alpha: fullBleed ? 0.28 : 0.5);
    final step = fullBleed ? 56.0 : 34.0;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawStroke(
    Canvas canvas,
    Size size,
    List<PlayBoardPoint> points,
    Color color,
  ) {
    if (points.isEmpty) {
      return;
    }

    final offsets = [
      for (final point in points)
        Offset(point.x * size.width, point.y * size.height),
    ];
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = fullBleed ? 16 : 10
      ..color = color.withValues(alpha: 0.86);

    if (offsets.length == 1) {
      final dotPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: 0.88);
      canvas.drawCircle(offsets.single, fullBleed ? 18 : 12, dotPaint);
      _drawStar(canvas, offsets.single, fullBleed ? 28 : 20, 0.2, dotPaint);
      return;
    }

    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, strokePaint);

    final starPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFB545).withValues(alpha: 0.92);
    for (var index = 0; index < offsets.length; index += 8) {
      _drawStar(
        canvas,
        offsets[index],
        fullBleed ? 13 : 9,
        index * 0.37,
        starPaint,
      );
    }
    _drawStar(canvas, offsets.last, fullBleed ? 24 : 16, 0.4, starPaint);
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
  bool shouldRepaint(covariant _PlayBoardPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.stickers != stickers ||
        oldDelegate.draftPoints != draftPoints ||
        oldDelegate.draftColorValue != draftColorValue ||
        oldDelegate.fullBleed != fullBleed;
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

class _PlayfulBabyButtonMotion extends StatelessWidget {
  const _PlayfulBabyButtonMotion({
    required this.enabled,
    required this.animation,
    required this.accent,
    required this.child,
  });

  final bool enabled;
  final Animation<double> animation;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final phase = animation.value * math.pi * 2;
        final scale = 1 + math.sin(phase) * 0.035;
        final angle = math.sin(phase * 0.8) * 0.018;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Transform.scale(
                scale: 1.22 + math.sin(phase * 1.4) * 0.04,
                child: CustomPaint(
                  painter: _TapOrbitPainter(phase: phase, accent: accent),
                ),
              ),
            ),
            Transform.rotate(
              angle: angle,
              child: Transform.scale(scale: scale, child: child),
            ),
          ],
        );
      },
      child: child,
    );
  }
}

class _TapOrbitPainter extends CustomPainter {
  const _TapOrbitPainter({required this.phase, required this.accent});

  final double phase;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final shortestSide = math.min(size.width, size.height);
    final paint = Paint()..style = PaintingStyle.fill;

    for (var index = 0; index < 9; index += 1) {
      final angle = phase * 0.65 + index * math.pi * 2 / 9;
      final radius = shortestSide * (0.42 + (index.isEven ? 0.08 : 0.03));
      final bob = math.sin(phase * 1.6 + index) * shortestSide * 0.025;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + bob);
      final alpha = 0.34 + math.sin(phase + index) * 0.12;
      paint.color = (index % 3 == 0 ? accent : const Color(0xFFFFB545))
          .withValues(alpha: alpha.clamp(0.16, 0.46));

      if (index % 4 == 0) {
        _drawTinyStar(canvas, point, 8 + index % 3 * 2, phase + index, paint);
      } else {
        canvas.drawCircle(point, 7 + index % 3 * 2, paint);
      }
    }
  }

  void _drawTinyStar(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Paint paint,
  ) {
    final path = Path();
    for (var index = 0; index < 10; index += 1) {
      final pointRadius = index.isEven ? radius : radius * 0.52;
      final angle = rotation + index * math.pi / 5;
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
  bool shouldRepaint(covariant _TapOrbitPainter oldDelegate) {
    return oldDelegate.phase != phase || oldDelegate.accent != accent;
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
  PlayActivity.bubbles => Icons.bubble_chart_rounded,
  PlayActivity.clapAlong => Icons.waving_hand_rounded,
  PlayActivity.animalSounds => Icons.pets_rounded,
};

IconData _iconFor(PlayActivity activity, String key) {
  return switch (key) {
    'boom' => Icons.radio_button_checked_rounded,
    'ding' => Icons.notifications_rounded,
    'whoosh' => Icons.air_rounded,
    'hello' => Icons.waving_hand_rounded,
    'smile' => Icons.sentiment_very_satisfied_rounded,
    'bubbles' => Icons.bubble_chart_rounded,
    'clap' => Icons.front_hand_rounded,
    'dog' || 'cat' || 'cow' => Icons.pets_rounded,
    _ => _activityIcon(activity),
  };
}

Color _colorForKey(String key) => switch (key) {
  'boom' => const Color(0xFFE85D43),
  'ding' => const Color(0xFFFFB545),
  'whoosh' => const Color(0xFF4967B1),
  'hello' => const Color(0xFF197A6E),
  'smile' => const Color(0xFFFFB545),
  'bubbles' => const Color(0xFF4967B1),
  'clap' => const Color(0xFFE85D43),
  'dog' => const Color(0xFF197A6E),
  'cat' => const Color(0xFFE85D43),
  'cow' => const Color(0xFF4967B1),
  _ => const Color(0xFFE85D43),
};

Color _stickerColorFor(String key) => switch (key) {
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
