import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

class ScannerBeep {
  static final AudioPlayer _player = AudioPlayer();

  static void playError() {
    _vibrate();
    _player.play(BytesSource(_buildWav(
      frequency: 880,
      durationSecs: 2.0,
      sampleRate: 22050,
    )));
  }

  static Future<void> _vibrate() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 2000);
    }
  }

  static Uint8List _buildWav({
    required double frequency,
    required double durationSecs,
    required int sampleRate,
  }) {
    final numSamples = (sampleRate * durationSecs).round();
    final data = ByteData(44 + numSamples * 2);

    final header = [
      0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0,
      0x57, 0x41, 0x56, 0x45,
      0x66, 0x6D, 0x74, 0x20, 16, 0, 0, 0,
      1, 0, 1, 0,
    ];
    for (var i = 0; i < header.length; i++) data.setUint8(i, header[i]);
    data.setUint32(4, 36 + numSamples * 2, Endian.little);
    data.setUint32(24, sampleRate, Endian.little);
    data.setUint32(28, sampleRate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    data.setUint8(36, 0x64); data.setUint8(37, 0x61);
    data.setUint8(38, 0x74); data.setUint8(39, 0x61);
    data.setUint32(40, numSamples * 2, Endian.little);

    final attack = (numSamples * 0.03).round();
    final release = (numSamples * 0.05).round();

    for (var i = 0; i < numSamples; i++) {
      double env;
      if (i < attack) {
        env = i / attack;
      } else if (i >= numSamples - release) {
        env = (numSamples - i) / release;
      } else {
        env = 1.0;
      }
      final sample = (32767 * env * sin(2 * pi * frequency * i / sampleRate))
          .round()
          .clamp(-32768, 32767);
      data.setInt16(44 + i * 2, sample, Endian.little);
    }

    return data.buffer.asUint8List();
  }
}