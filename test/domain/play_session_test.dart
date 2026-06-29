import 'package:family_hearth/src/domain/play_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaySession', () {
    test('creates a prompt with activity options', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.findShape,
        targetKey: 'star',
        createdBy: 'grandma',
      );

      expect(session.isPrompting, isTrue);
      expect(session.options, ['circle', 'star', 'triangle']);
      expect(session.childResponseKey, isNull);
    });

    test('marks a matching child answer as correct', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.colorPop,
        targetKey: 'red',
        createdBy: 'aunt',
      ).answeredBy('red');

      expect(session.isAnswered, isTrue);
      expect(session.childResponseKey, 'red');
      expect(session.childResponseCorrect, isTrue);
    });

    test('round trips through json', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.peekabooBox,
        targetKey: 'box2',
        createdBy: 'grandpa',
      ).answeredBy('box1');

      final restored = PlaySession.fromJson('play-1', session.toJson());

      expect(restored.activity, PlayActivity.peekabooBox);
      expect(restored.status, PlaySessionStatus.answered);
      expect(restored.targetKey, 'box2');
      expect(restored.childResponseKey, 'box1');
      expect(restored.childResponseCorrect, isFalse);
    });
  });
}
