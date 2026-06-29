enum FamilyStatsEventKind {
  tileTapped,
  callStartedByChild,
  callStartedByParent,
  callStartedByFamily,
  callCompleted,
  callRejected,
  callExpired,
}

class FamilyStatsEntry {
  const FamilyStatsEntry({
    required this.id,
    required this.contactId,
    required this.kind,
    required this.occurredAt,
    this.durationSeconds = 0,
  });

  final String id;
  final String contactId;
  final FamilyStatsEventKind kind;
  final DateTime occurredAt;
  final int durationSeconds;

  Map<String, Object?> toJson() => {
    'contactId': contactId,
    'kind': kind.name,
    'occurredAt': occurredAt.toIso8601String(),
    'durationSeconds': durationSeconds,
  };

  static FamilyStatsEntry fromJson(String id, Map<String, Object?> json) {
    return FamilyStatsEntry(
      id: id,
      contactId: json['contactId'] as String? ?? '',
      kind: FamilyStatsEventKind.values.firstWhere(
        (kind) => kind.name == json['kind'],
        orElse: () => FamilyStatsEventKind.tileTapped,
      ),
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
    );
  }
}

class ContactStatsSummary {
  const ContactStatsSummary({
    required this.contactId,
    this.taps = 0,
    this.attemptedCalls = 0,
    this.completedCalls = 0,
    this.totalSeconds = 0,
  });

  final String contactId;
  final int taps;
  final int attemptedCalls;
  final int completedCalls;
  final int totalSeconds;

  int get playfulScore => taps + attemptedCalls * 2 + completedCalls * 5;

  ContactStatsSummary copyWith({
    int? taps,
    int? attemptedCalls,
    int? completedCalls,
    int? totalSeconds,
  }) {
    return ContactStatsSummary(
      contactId: contactId,
      taps: taps ?? this.taps,
      attemptedCalls: attemptedCalls ?? this.attemptedCalls,
      completedCalls: completedCalls ?? this.completedCalls,
      totalSeconds: totalSeconds ?? this.totalSeconds,
    );
  }
}

class FamilyStatsSummary {
  const FamilyStatsSummary({required this.byContact});

  final Map<String, ContactStatsSummary> byContact;

  String? get favoriteContactId {
    if (byContact.isEmpty) {
      return null;
    }

    final sorted = byContact.values.toList()
      ..sort((a, b) => b.playfulScore.compareTo(a.playfulScore));
    return sorted.first.contactId;
  }
}

class FamilyStatsEngine {
  const FamilyStatsEngine._();

  static FamilyStatsSummary summarize(List<FamilyStatsEntry> events) {
    final summaries = <String, ContactStatsSummary>{};

    ContactStatsSummary currentFor(String contactId) {
      return summaries.putIfAbsent(
        contactId,
        () => ContactStatsSummary(contactId: contactId),
      );
    }

    for (final event in events) {
      final current = currentFor(event.contactId);
      summaries[event.contactId] = switch (event.kind) {
        FamilyStatsEventKind.tileTapped => current.copyWith(
          taps: current.taps + 1,
        ),
        FamilyStatsEventKind.callStartedByChild ||
        FamilyStatsEventKind.callStartedByParent ||
        FamilyStatsEventKind.callStartedByFamily => current.copyWith(
          attemptedCalls: current.attemptedCalls + 1,
        ),
        FamilyStatsEventKind.callCompleted => current.copyWith(
          completedCalls: current.completedCalls + 1,
          totalSeconds: current.totalSeconds + event.durationSeconds,
        ),
        FamilyStatsEventKind.callRejected ||
        FamilyStatsEventKind.callExpired => current,
      };
    }

    return FamilyStatsSummary(byContact: Map.unmodifiable(summaries));
  }
}
