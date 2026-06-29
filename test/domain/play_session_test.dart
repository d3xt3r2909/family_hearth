import 'package:family_hearth/src/domain/play_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaySession', () {
    test('exposes one shared play prompt list', () {
      expect(PlayActivityCatalog.promptOptions.map((option) => option.key), [
        'boom',
        'ding',
        'whoosh',
        'bubbles',
        'clap',
        'dog',
        'cat',
        'cow',
      ]);
    });

    test('creates a baby moment with activity options', () {
      final session = PlaySession.prompt(
        id: 'play-1',
        familyId: 'family',
        activity: PlayActivity.bubbles,
        targetKey: 'bubbles',
        createdBy: 'grandma',
      );

      expect(session.isPrompting, isTrue);
      expect(session.options, ['bubbles']);
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
      final session =
          PlaySession.prompt(
                id: 'play-1',
                familyId: 'family',
                activity: PlayActivity.animalSounds,
                targetKey: 'dog',
                createdBy: 'grandpa',
              )
              .withBoardStroke(
                PlayBoardStroke(
                  id: 'stroke-1',
                  actorId: 'grandpa',
                  colorValue: 0xFFE85D43,
                  points: const [
                    PlayBoardPoint(x: 0.2, y: 0.3),
                    PlayBoardPoint(x: 0.4, y: 0.5),
                  ],
                  createdAt: DateTime.parse('2026-06-29T10:00:00.000'),
                ),
                actorId: 'grandpa',
              )
              .answeredBy(PlaySession.childTouchKey);

      final restored = PlaySession.fromJson('play-1', session.toJson());

      expect(restored.activity, PlayActivity.animalSounds);
      expect(restored.status, PlaySessionStatus.answered);
      expect(restored.targetKey, 'dog');
      expect(restored.boardStrokes.single.points.last.x, 0.4);
      expect(restored.childResponseKey, PlaySession.childTouchKey);
      expect(restored.childResponseCorrect, isNull);
    });

    test('keeps the shared board bounded', () {
      var session = PlaySession.idle(id: 'play-1', familyId: 'family');

      for (
        var index = 0;
        index < PlayActivityCatalog.maxBoardStrokes + 3;
        index += 1
      ) {
        session = session.withBoardStroke(
          PlayBoardStroke(
            id: 'stroke-$index',
            actorId: 'child',
            colorValue: 0xFF197A6E,
            points: const [PlayBoardPoint(x: 0.5, y: 0.5)],
            createdAt: DateTime(2026, 6, 29),
          ),
          actorId: 'child',
        );
      }

      expect(
        session.boardStrokes,
        hasLength(PlayActivityCatalog.maxBoardStrokes),
      );
      expect(session.boardStrokes.first.id, 'stroke-3');
    });
  });
}
