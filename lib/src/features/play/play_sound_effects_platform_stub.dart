import 'package:flutter/services.dart';

Future<void> playPlatformTone(String tone) {
  return SystemSound.play(SystemSoundType.click);
}
