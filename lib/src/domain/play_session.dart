enum PlayActivity { babyBeats, peekaboo, bubbles, clapAlong, animalSounds }

enum PlaySessionStatus { idle, prompting, answered }

class PlayActivityCatalog {
  const PlayActivityCatalog._();

  static const beatKeys = ['boom', 'ding', 'whoosh'];
  static const peekabooKeys = ['peekaboo', 'hello', 'smile'];
  static const bubbleKeys = ['bubbles', 'stars', 'rainbow'];
  static const clapKeys = ['clap', 'wave', 'dance'];
  static const animalKeys = ['dog', 'cat', 'cow'];

  static List<String> optionsFor(PlayActivity activity) => switch (activity) {
    PlayActivity.babyBeats => beatKeys,
    PlayActivity.peekaboo => peekabooKeys,
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
  final String? childResponseKey;
  final bool? childResponseCorrect;

  bool get hasPrompt =>
      status != PlaySessionStatus.idle && targetKey.trim().isNotEmpty;

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
      childResponseKey: json['childResponseKey'] as String?,
      childResponseCorrect: json['childResponseCorrect'] as bool?,
    );
  }
}
