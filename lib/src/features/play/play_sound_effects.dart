import 'dart:async';

import '../../domain/play_session.dart';
import 'play_sound_effects_platform_stub.dart'
    if (dart.library.html) 'play_sound_effects_platform_web.dart';

class PlaySoundEffects {
  const PlaySoundEffects._();

  static Future<void> playMoment(PlayActivity activity, String key) async {
    for (final tone in _tonesFor(activity, key)) {
      await playPlatformTone(tone);
      await Future<void>.delayed(const Duration(milliseconds: 54));
    }
  }

  static Future<void> playBabyTouch(PlayActivity activity, String key) async {
    await playPlatformTone('pop');
    await Future<void>.delayed(const Duration(milliseconds: 72));
    await playMoment(activity, key);
  }

  static List<String> _tonesFor(PlayActivity activity, String key) {
    return switch (key) {
      'boom' => const ['boom'],
      'ding' => const ['ding'],
      'whoosh' => const ['whoosh'],
      'peekaboo' => const ['peekaboo'],
      'hello' => const ['hello'],
      'smile' => const ['sparkle'],
      'bubbles' => const ['bubble', 'bubbleHigh'],
      'stars' => const ['sparkle', 'ding'],
      'rainbow' => const ['bubble', 'sparkle', 'ding'],
      'clap' => const ['clap', 'clap'],
      'wave' => const ['whoosh', 'sparkle'],
      'dance' => const ['pop', 'ding', 'pop'],
      'dog' => const ['dog'],
      'cat' => const ['cat'],
      'cow' => const ['cow'],
      _ => switch (activity) {
        PlayActivity.babyBeats => const ['boom'],
        PlayActivity.peekaboo => const ['peekaboo'],
        PlayActivity.bubbles => const ['bubble'],
        PlayActivity.clapAlong => const ['clap'],
        PlayActivity.animalSounds => const ['dog'],
      },
    };
  }
}
