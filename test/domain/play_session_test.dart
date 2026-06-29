import 'package:family_hearth/src/domain/play_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaySession', () {
    test('creates a baby moment with activity options', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.bubbles,
        targetKey: 'bubbles',
        createdBy: 'grandma',
      );

      expect(session.isPrompting, isTrue);
      expect(session.options, ['bubbles', 'stars', 'rainbow']);
      expect(session.childResponseKey, isNull);
    });

    test('records a baby touch without right or wrong', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.babyBeats,
        targetKey: 'boom',
        createdBy: 'aunt',
      ).answeredBy(PlaySession.childTouchKey);

      expect(session.isAnswered, isTrue);
      expect(session.childResponseKey, PlaySession.childTouchKey);
      expect(session.childResponseCorrect, isNull);
    });

    test('round trips through json', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.animalSounds,
        targetKey: 'dog',
        createdBy: 'grandpa',
      ).answeredBy(PlaySession.childTouchKey);

      final restored = PlaySession.fromJson('play-1', session.toJson());

      expect(restored.activity, PlayActivity.animalSounds);
      expect(restored.status, PlaySessionStatus.answered);
      expect(restored.targetKey, 'dog');
      expect(restored.childResponseKey, PlaySession.childTouchKey);
      expect(restored.childResponseCorrect, isNull);
    });
  });
}
