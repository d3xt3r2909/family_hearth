import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

web.AudioContext? _context;
final _noiseRandom = math.Random();

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
      _dogBark(context);
    case 'cat':
      _catMeow(context);
    case 'cow':
      _cowMoo(context);
    default:
      _tone(context, frequency: 620, duration: 0.12, volume: 0.16);
  }
}

void _dogBark(web.AudioContext context) {
  _noiseBurst(context, duration: 0.075, volume: 0.28, frequency: 720, q: 2.8);
  _slide(
    context,
    from: 250,
    to: 92,
    duration: 0.13,
    volume: 0.30,
    wave: 'sawtooth',
  );
  _noiseBurst(
    context,
    delay: 0.14,
    duration: 0.065,
    volume: 0.22,
    frequency: 620,
    q: 2.4,
  );
  _slide(
    context,
    from: 205,
    to: 82,
    duration: 0.12,
    volume: 0.24,
    delay: 0.14,
    wave: 'square',
  );
}

void _catMeow(web.AudioContext context) {
  _noiseBurst(context, duration: 0.08, volume: 0.05, frequency: 1800, q: 1.2);
  _slide(
    context,
    from: 560,
    to: 980,
    duration: 0.16,
    volume: 0.14,
    wave: 'triangle',
  );
  _slide(
    context,
    from: 980,
    to: 430,
    duration: 0.32,
    volume: 0.18,
    delay: 0.12,
    wave: 'sine',
  );
}

void _cowMoo(web.AudioContext context) {
  _noiseBurst(
    context,
    duration: 0.42,
    volume: 0.055,
    frequency: 240,
    q: 0.7,
    filterType: 'lowpass',
  );
  _slide(
    context,
    from: 126,
    to: 82,
    duration: 0.58,
    volume: 0.22,
    wave: 'sawtooth',
  );
  _slide(
    context,
    from: 94,
    to: 72,
    duration: 0.34,
    volume: 0.14,
    delay: 0.24,
    wave: 'triangle',
  );
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
  String wave = 'sine',
}) {
  final now = context.currentTime + delay;
  final oscillator = context.createOscillator();
  final gain = context.createGain();

  oscillator.type = wave;
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

void _noiseBurst(
  web.AudioContext context, {
  required num duration,
  required num volume,
  required num frequency,
  required num q,
  num delay = 0,
  String filterType = 'bandpass',
}) {
  final now = context.currentTime + delay;
  final source = context.createBufferSource();
  final filter = context.createBiquadFilter();
  final gain = context.createGain();

  source.buffer = _noiseBuffer(context, duration);
  filter.type = filterType;
  filter.frequency.setValueAtTime(frequency, now);
  filter.Q.setValueAtTime(q, now);
  gain.gain.setValueAtTime(0.0001, now);
  gain.gain.exponentialRampToValueAtTime(volume, now + 0.006);
  gain.gain.exponentialRampToValueAtTime(0.0001, now + duration);

  source.connect(filter);
  filter.connect(gain);
  gain.connect(context.destination);
  source.start(now);
  source.stop(now + duration + 0.02);
}

web.AudioBuffer _noiseBuffer(web.AudioContext context, num duration) {
  final length = math.max(1, (context.sampleRate * duration).ceil());
  final buffer = context.createBuffer(1, length, context.sampleRate);
  final Float32List samples = buffer.getChannelData(0).toDart;
  var previous = 0.0;

  for (var index = 0; index < samples.length; index += 1) {
    final progress = index / samples.length;
    final white = _noiseRandom.nextDouble() * 2 - 1;
    previous = previous * 0.62 + white * 0.38;
    samples[index] = previous * (1 - progress * progress);
  }

  return buffer;
}
