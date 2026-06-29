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
    if (activity != PlayActivity.animalSounds) {
      await playPlatformTone('tap');
      await Future<void>.delayed(const Duration(milliseconds: 72));
    }

    await playMoment(activity, key);
  }

  static List<String> _tonesFor(PlayActivity activity, String key) {
    return switch (key) {
      'boom' => const ['boom'],
      'ding' => const ['chime'],
      'whoosh' => const ['whoosh'],
      'bubbles' => const ['bubble'],
      'clap' => const ['clap'],
      'dog' => const ['dog'],
      'cat' => const ['cat'],
      'cow' => const ['cow'],
      _ => switch (activity) {
        PlayActivity.babyBeats => const ['boom'],
        PlayActivity.bubbles => const ['bubble'],
        PlayActivity.clapAlong => const ['clap'],
        PlayActivity.animalSounds => const ['dog'],
      },
    };
  }
}
