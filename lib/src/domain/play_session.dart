enum PlayActivity { babyBeats, bubbles, clapAlong, animalSounds }

enum PlaySessionStatus { idle, prompting, answered }

class PlayPromptOption {
  const PlayPromptOption({required this.activity, required this.key});

  final PlayActivity activity;
  final String key;
}

class PlayBoardPoint {
  const PlayBoardPoint({required this.x, required this.y});

  final double x;
  final double y;

  Map<String, Object?> toJson() => {'x': x, 'y': y};

  static PlayBoardPoint fromJson(Map<String, Object?> json) {
    return PlayBoardPoint(x: _unitValue(json['x']), y: _unitValue(json['y']));
  }
}

class PlayBoardStroke {
  const PlayBoardStroke({
    required this.id,
    required this.actorId,
    required this.colorValue,
    required this.points,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final int colorValue;
  final List<PlayBoardPoint> points;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'actorId': actorId,
    'colorValue': colorValue,
    'points': points.map((point) => point.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  static PlayBoardStroke fromJson(Map<String, Object?> json) {
    return PlayBoardStroke(
      id: json['id'] as String? ?? '',
      actorId: json['actorId'] as String? ?? '',
      colorValue: _intValue(json['colorValue'], 0xFFE85D43),
      points:
          (json['points'] as List?)
              ?.whereType<Map>()
              .map(
                (point) =>
                    PlayBoardPoint.fromJson(Map<String, Object?>.from(point)),
              )
              .toList(growable: false) ??
          const [],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PlayActivityCatalog {
  const PlayActivityCatalog._();

  static const maxBoardStrokes = 42;
  static const beatKeys = ['boom', 'ding', 'whoosh'];
  static const bubbleKeys = ['bubbles'];
  static const clapKeys = ['clap'];
  static const animalKeys = ['dog', 'cat', 'cow'];
  static const promptOptions = [
    PlayPromptOption(activity: PlayActivity.babyBeats, key: 'boom'),
    PlayPromptOption(activity: PlayActivity.babyBeats, key: 'ding'),
    PlayPromptOption(activity: PlayActivity.babyBeats, key: 'whoosh'),
    PlayPromptOption(activity: PlayActivity.bubbles, key: 'bubbles'),
    PlayPromptOption(activity: PlayActivity.clapAlong, key: 'clap'),
    PlayPromptOption(activity: PlayActivity.animalSounds, key: 'dog'),
    PlayPromptOption(activity: PlayActivity.animalSounds, key: 'cat'),
    PlayPromptOption(activity: PlayActivity.animalSounds, key: 'cow'),
  ];

  static List<String> optionsFor(PlayActivity activity) => switch (activity) {
    PlayActivity.babyBeats => beatKeys,
    PlayActivity.bubbles => bubbleKeys,
    PlayActivity.clapAlong => clapKeys,
    PlayActivity.animalSounds => animalKeys,
  };
}

class PlaySession {
  const PlaySession({
    required this.id,
    required this.familyId,
    required this.activity,
    required this.status,
    required this.targetKey,
    required this.options,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.boardStrokes = const [],
    this.childResponseKey,
    this.childResponseCorrect,
  });

  static const childTouchKey = 'babyTouch';

  final String id;
  final String familyId;
  final PlayActivity activity;
  final PlaySessionStatus status;
  final String targetKey;
  final List<String> options;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PlayBoardStroke> boardStrokes;
  final String? childResponseKey;
  final bool? childResponseCorrect;

  bool get hasPrompt =>
      status != PlaySessionStatus.idle && targetKey.trim().isNotEmpty;

  bool get hasBoard => boardStrokes.isNotEmpty;

  bool get hasPlaySurface => hasPrompt || hasBoard;

  bool get isPrompting => status == PlaySessionStatus.prompting && hasPrompt;

  bool get isAnswered => status == PlaySessionStatus.answered && hasPrompt;

  factory PlaySession.idle({
    required String id,
    required String familyId,
    String createdBy = '',
  }) {
    final now = DateTime.now();
    return PlaySession(
      id: id,
      familyId: familyId,
      activity: PlayActivity.babyBeats,
      status: PlaySessionStatus.idle,
      targetKey: '',
      options: const [],
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory PlaySession.prompt({
    required String id,
    required String familyId,
    required PlayActivity activity,
    required String targetKey,
    required String createdBy,
    List<PlayBoardStroke> boardStrokes = const [],
  }) {
    final now = DateTime.now();
    return PlaySession(
      id: id,
      familyId: familyId,
      activity: activity,
      status: PlaySessionStatus.prompting,
      targetKey: targetKey,
      options: PlayActivityCatalog.optionsFor(activity),
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      boardStrokes: boardStrokes,
    );
  }

  PlaySession copyWith({
    PlayActivity? activity,
    PlaySessionStatus? status,
    String? targetKey,
    List<String>? options,
    String? createdBy,
    DateTime? updatedAt,
    List<PlayBoardStroke>? boardStrokes,
    String? childResponseKey,
    bool? childResponseCorrect,
  }) {
    return PlaySession(
      id: id,
      familyId: familyId,
      activity: activity ?? this.activity,
      status: status ?? this.status,
      targetKey: targetKey ?? this.targetKey,
      options: options ?? this.options,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      boardStrokes: boardStrokes ?? this.boardStrokes,
      childResponseKey: childResponseKey ?? this.childResponseKey,
      childResponseCorrect: childResponseCorrect ?? this.childResponseCorrect,
    );
  }

  PlaySession withBoardStroke(
    PlayBoardStroke stroke, {
    required String actorId,
  }) {
    final nextStrokes = [...boardStrokes, stroke];
    final trimmedStrokes =
        nextStrokes.length > PlayActivityCatalog.maxBoardStrokes
        ? nextStrokes.sublist(
            nextStrokes.length - PlayActivityCatalog.maxBoardStrokes,
          )
        : nextStrokes;

    return copyWith(
      createdBy: actorId,
      updatedAt: DateTime.now(),
      boardStrokes: trimmedStrokes,
    );
  }

  PlaySession withoutBoard({required String actorId}) {
    return copyWith(
      createdBy: actorId,
      updatedAt: DateTime.now(),
      boardStrokes: const [],
    );
  }

  PlaySession answeredBy(String responseKey) {
    return PlaySession(
      id: id,
      familyId: familyId,
      activity: activity,
      status: PlaySessionStatus.answered,
      targetKey: targetKey,
      options: options,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      boardStrokes: boardStrokes,
      childResponseKey: responseKey,
      childResponseCorrect: null,
    );
  }

  Map<String, Object?> toJson() => {
    'familyId': familyId,
    'activity': activity.name,
    'status': status.name,
    'targetKey': targetKey,
    'options': options,
    'createdBy': createdBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'boardStrokes': boardStrokes.map((stroke) => stroke.toJson()).toList(),
    'childResponseKey': childResponseKey,
    'childResponseCorrect': childResponseCorrect,
  };

  static PlaySession fromJson(String id, Map<String, Object?> json) {
    return PlaySession(
      id: id,
      familyId: json['familyId'] as String? ?? '',
      activity: PlayActivity.values.firstWhere(
        (activity) => activity.name == json['activity'],
        orElse: () => PlayActivity.babyBeats,
      ),
      status: PlaySessionStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => PlaySessionStatus.idle,
      ),
      targetKey: json['targetKey'] as String? ?? '',
      options:
          (json['options'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      createdBy: json['createdBy'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      boardStrokes:
          (json['boardStrokes'] as List?)
              ?.whereType<Map>()
              .map(
                (stroke) =>
                    PlayBoardStroke.fromJson(Map<String, Object?>.from(stroke)),
              )
              .toList(growable: false) ??
          const [],
      childResponseKey: json['childResponseKey'] as String?,
      childResponseCorrect: json['childResponseCorrect'] as bool?,
    );
  }
}

double _unitValue(Object? value) {
  if (value is num) {
    return value.toDouble().clamp(0, 1);
  }
  return 0;
}

int _intValue(Object? value, int fallback) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}
