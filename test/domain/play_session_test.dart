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
              .withBoardSticker(
                PlayBoardSticker(
                  id: 'sticker-1',
                  actorId: 'child',
                  key: 'cat',
                  x: 0.72,
                  y: 0.18,
                  colorValue: 0xFF4967B1,
                  createdAt: DateTime.parse('2026-06-29T10:01:00.000'),
                ),
                actorId: 'child',
              )
              .answeredBy(PlaySession.childTouchKey);

      final restored = PlaySession.fromJson('play-1', session.toJson());

      expect(restored.activity, PlayActivity.animalSounds);
      expect(restored.status, PlaySessionStatus.answered);
      expect(restored.targetKey, 'dog');
      expect(restored.hasBoard, isTrue);
      expect(restored.boardStrokes.single.points.last.x, 0.4);
      expect(restored.boardStickers.single.key, 'cat');
      expect(restored.boardStickers.single.x, 0.72);
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

    test('keeps shared board stickers bounded and movable', () {
      var session = PlaySession.idle(id: 'play-1', familyId: 'family');

      for (
        var index = 0;
        index < PlayActivityCatalog.maxBoardStickers + 3;
        index += 1
      ) {
        session = session.withBoardSticker(
          PlayBoardSticker(
            id: 'sticker-$index',
            actorId: 'grandma',
            key: index.isEven ? 'dog' : 'cow',
            x: 0.1,
            y: 0.2,
            colorValue: 0xFFE85D43,
            createdAt: DateTime(2026, 6, 29),
          ),
          actorId: 'grandma',
        );
      }

      session = session.withBoardSticker(
        PlayBoardSticker(
          id: 'sticker-3',
          actorId: 'child',
          key: 'cat',
          x: 0.8,
          y: 0.7,
          colorValue: 0xFF4967B1,
          createdAt: DateTime(2026, 6, 29, 10),
        ),
        actorId: 'child',
      );

      expect(
        session.boardStickers,
        hasLength(PlayActivityCatalog.maxBoardStickers),
      );
      expect(session.boardStickers.first.id, 'sticker-4');
      expect(session.boardStickers.last.id, 'sticker-3');
      expect(session.boardStickers.last.x, 0.8);
    });
  });
}
