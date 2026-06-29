import 'package:family_hearth/src/domain/family_contact.dart';
import 'package:family_hearth/src/domain/schedule_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScheduleWindow', () {
    test('contains times inside a same-day window', () {
      const window = ScheduleWindow(
        id: 'morning',
        label: 'Morning',
        startMinute: 9 * 60,
        endMinute: 11 * 60,
        allowedContactIds: {'grandma'},
      );

      expect(window.contains(DateTime(2026, 6, 29, 9, 30)), isTrue);
      expect(window.contains(DateTime(2026, 6, 29, 11)), isFalse);
    });

    test('contains times inside an overnight window', () {
      const window = ScheduleWindow(
        id: 'evening',
        label: 'Evening',
        startMinute: 21 * 60,
        endMinute: 7 * 60,
        allowedContactIds: {'grandpa'},
      );

      expect(window.contains(DateTime(2026, 6, 29, 22)), isTrue);
      expect(window.contains(DateTime(2026, 6, 30, 6, 30)), isTrue);
      expect(window.contains(DateTime(2026, 6, 30, 12)), isFalse);
    });

    test(
      'filters active contacts by trust, manual allow, and schedule ids',
      () {
        const grandma = FamilyContact(
          id: 'grandma',
          displayName: 'Grandma',
          relationship: 'Grandma',
          avatarText: 'GM',
          accentColorValue: 0xFFE85D43,
        );
        const aunt = FamilyContact(
          id: 'aunt',
          displayName: 'Aunt',
          relationship: 'Aunt',
          avatarText: 'AA',
          accentColorValue: 0xFF197A6E,
          isManuallyAllowed: false,
        );
        const window = ScheduleWindow(
          id: 'morning',
          label: 'Morning',
          startMinute: 9 * 60,
          endMinute: 11 * 60,
          allowedContactIds: {'grandma', 'aunt'},
        );

        final active = window.activeContacts([
          grandma,
          aunt,
        ], DateTime(2026, 6, 29, 9, 15));

        expect(active.map((contact) => contact.id), ['grandma']);
      },
    );
  });
}
