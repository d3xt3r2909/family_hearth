import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.AudioContext? _context;

Future<void> playPlatformTone(String tone) async {
  final context = _context ??= web.AudioContext();

  try {
    await context.resume().toDart;
  } on Object {
    return;
  }

  switch (tone) {
    case 'boom':
      _tone(context, frequency: 92, duration: 0.24, volume: 0.42);
      _tone(context, frequency: 58, duration: 0.22, volume: 0.24, delay: 0.06);
    case 'ding':
      _tone(
        context,
        frequency: 880,
        duration: 0.18,
        volume: 0.22,
        wave: 'sine',
      );
      _tone(
        context,
        frequency: 1320,
        duration: 0.16,
        volume: 0.12,
        delay: 0.06,
      );
    case 'whoosh':
      _slide(context, from: 220, to: 720, duration: 0.28, volume: 0.18);
    case 'peekaboo':
      _tone(context, frequency: 440, duration: 0.1, volume: 0.18);
      _tone(context, frequency: 660, duration: 0.16, volume: 0.22, delay: 0.11);
    case 'hello':
      _tone(context, frequency: 520, duration: 0.12, volume: 0.18);
      _tone(context, frequency: 700, duration: 0.18, volume: 0.20, delay: 0.12);
    case 'sparkle':
      _tone(context, frequency: 990, duration: 0.08, volume: 0.12);
      _tone(
        context,
        frequency: 1480,
        duration: 0.10,
        volume: 0.10,
        delay: 0.08,
      );
    case 'bubble':
      _slide(context, from: 360, to: 760, duration: 0.14, volume: 0.15);
    case 'bubbleHigh':
      _slide(context, from: 520, to: 1040, duration: 0.14, volume: 0.12);
    case 'clap':
      _tone(
        context,
        frequency: 260,
        duration: 0.035,
        volume: 0.30,
        wave: 'square',
      );
      _tone(
        context,
        frequency: 420,
        duration: 0.025,
        volume: 0.20,
        wave: 'square',
        delay: 0.035,
      );
    case 'pop':
      _slide(context, from: 180, to: 780, duration: 0.09, volume: 0.20);
    case 'dog':
      _tone(context, frequency: 180, duration: 0.09, volume: 0.26);
      _tone(context, frequency: 150, duration: 0.12, volume: 0.24, delay: 0.12);
    case 'cat':
      _slide(context, from: 760, to: 420, duration: 0.28, volume: 0.18);
    case 'cow':
      _tone(context, frequency: 132, duration: 0.34, volume: 0.24);
      _tone(context, frequency: 104, duration: 0.24, volume: 0.18, delay: 0.20);
    default:
      _tone(context, frequency: 620, duration: 0.12, volume: 0.16);
  }
}

void _tone(
  web.AudioContext context, {
  required num frequency,
  required num duration,
  required num volume,
  String wave = 'triangle',
  num delay = 0,
}) {
  final now = context.currentTime + delay;
  final oscillator = context.createOscillator();
  final gain = context.createGain();

  oscillator.type = wave;
  oscillator.frequency.setValueAtTime(frequency, now);
  gain.gain.setValueAtTime(0.0001, now);
  gain.gain.exponentialRampToValueAtTime(volume, now + 0.012);
  gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

  oscillator.connect(gain);
  gain.connect(context.destination);
  oscillator.start(now);
  oscillator.stop(now + duration + 0.03);
}

void _slide(
  web.AudioContext context, {
  required num from,
  required num to,
  required num duration,
  required num volume,
  num delay = 0,
}) {
  final now = context.currentTime + delay;
  final oscillator = context.createOscillator();
  final gain = context.createGain();

  oscillator.type = 'sine';
  oscillator.frequency.setValueAtTime(from, now);
  oscillator.frequency.exponentialRampToValueAtTime(to, now + duration);
  gain.gain.setValueAtTime(0.0001, now);
  gain.gain.exponentialRampToValueAtTime(volume, now + 0.01);
  gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

  oscillator.connect(gain);
  gain.connect(context.destination);
  oscillator.start(now);
  oscillator.stop(now + duration + 0.03);
}
