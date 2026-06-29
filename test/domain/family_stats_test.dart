import 'package:family_hearth/src/domain/family_stats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FamilyStatsEngine', () {
    test('summarizes playful tap and call stats by contact', () {
      final summary = FamilyStatsEngine.summarize([
        FamilyStatsEntry(
          id: '1',
          contactId: 'grandma',
          kind: FamilyStatsEventKind.tileTapped,
          occurredAt: DateTime(2026),
        ),
        FamilyStatsEntry(
          id: '2',
          contactId: 'grandma',
          kind: FamilyStatsEventKind.callStartedByChild,
          occurredAt: DateTime(2026),
        ),
        FamilyStatsEntry(
          id: '3',
          contactId: 'grandma',
          kind: FamilyStatsEventKind.callCompleted,
          occurredAt: DateTime(2026),
          durationSeconds: 120,
        ),
        FamilyStatsEntry(
          id: '4',
          contactId: 'aunt',
          kind: FamilyStatsEventKind.tileTapped,
          occurredAt: DateTime(2026),
        ),
        FamilyStatsEntry(
          id: '5',
          contactId: 'aunt',
          kind: FamilyStatsEventKind.callStartedByFamily,
          occurredAt: DateTime(2026),
        ),
      ]);

      expect(summary.byContact['grandma']?.taps, 1);
      expect(summary.byContact['grandma']?.attemptedCalls, 1);
      expect(summary.byContact['grandma']?.completedCalls, 1);
      expect(summary.byContact['grandma']?.totalSeconds, 120);
      expect(summary.byContact['aunt']?.attemptedCalls, 1);
      expect(summary.favoriteContactId, 'grandma');
    });
  });
}
