import '../domain/call_session.dart';
import '../domain/family_contact.dart';
import '../domain/family_stats.dart';
import '../domain/schedule_window.dart';

class DemoFamilyData {
  const DemoFamilyData._();

  static const contacts = [
    FamilyContact(
      id: 'grandma-mira',
      displayName: 'Grandma Mira',
      relationship: 'Grandma',
      avatarText: 'GM',
      accentColorValue: 0xFFE85D43,
    ),
    FamilyContact(
      id: 'grandpa-ivo',
      displayName: 'Grandpa Ivo',
      relationship: 'Grandpa',
      avatarText: 'GI',
      accentColorValue: 0xFF197A6E,
    ),
    FamilyContact(
      id: 'aunt-ana',
      displayName: 'Aunt Ana',
      relationship: 'Aunt',
      avatarText: 'AA',
      accentColorValue: 0xFFFFB545,
    ),
    FamilyContact(
      id: 'uncle-sam',
      displayName: 'Uncle Sam',
      relationship: 'Uncle',
      avatarText: 'US',
      accentColorValue: 0xFF4967B1,
    ),
  ];

  static const schedules = [
    ScheduleWindow(
      id: 'morning-family',
      label: 'Morning family time',
      startMinute: 9 * 60,
      endMinute: 11 * 60,
      allowedContactIds: {'grandma-mira', 'grandpa-ivo'},
    ),
    ScheduleWindow(
      id: 'after-nap',
      label: 'After nap',
      startMinute: 16 * 60,
      endMinute: 18 * 60,
      allowedContactIds: {'aunt-ana', 'grandma-mira'},
    ),
  ];

  static CallSession get initialCall => CallSession.idle();

  static List<FamilyStatsEntry> get statsEvents => [
    FamilyStatsEntry(
      id: 'seed-1',
      contactId: 'grandma-mira',
      kind: FamilyStatsEventKind.tileTapped,
      occurredAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    FamilyStatsEntry(
      id: 'seed-2',
      contactId: 'grandma-mira',
      kind: FamilyStatsEventKind.callCompleted,
      occurredAt: DateTime.now().subtract(const Duration(hours: 3)),
      durationSeconds: 245,
    ),
    FamilyStatsEntry(
      id: 'seed-3',
      contactId: 'aunt-ana',
      kind: FamilyStatsEventKind.tileTapped,
      occurredAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];
}
