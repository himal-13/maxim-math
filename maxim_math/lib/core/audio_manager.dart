import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

class _Tone {
  final double frequency;
  final double duration;
  final bool isBuzzer;
  _Tone(this.frequency, this.duration, {this.isBuzzer = false});
}

class AudioManager {
  static bool _initialized = false;
  static final Map<String, File> _soundFiles = {};

  static Future<void> load() async {
    if (_initialized) return;

    try {
      final tempDir = Directory.systemTemp;

      _soundFiles['correct'] = await _writeWavFile(
        '${tempDir.path}/mm_correct.wav',
        _generateCorrectTones(),
      );

      _soundFiles['wrong'] = await _writeWavFile(
        '${tempDir.path}/mm_wrong.wav',
        _generateWrongTones(),
      );

      _soundFiles['coin'] = await _writeWavFile(
        '${tempDir.path}/mm_coin.wav',
        _generateCoinTones(),
      );

      _soundFiles['levelup'] = await _writeWavFile(
        '${tempDir.path}/mm_levelup.wav',
        _generateLevelUpTones(),
      );

      _soundFiles['gameover'] = await _writeWavFile(
        '${tempDir.path}/mm_gameover.wav',
        _generateGameOverTones(),
      );

      _soundFiles['streak'] = await _writeWavFile(
        '${tempDir.path}/mm_streak.wav',
        _generateStreakTones(),
      );

      _initialized = true;
    } catch (e) {
      print('Failed to initialize audio manager: $e');
    }
  }

  static Future<File> _writeWavFile(String path, List<int> bytes) async {
    final file = File(path);
    if (!await file.exists()) {
      await file.writeAsBytes(bytes);
    }
    return file;
  }

  static void _playSound(String name) {
    final file = _soundFiles[name];
    if (file != null) {
      _runPlayCommand(file.path);
    }
  }

  static void _runPlayCommand(String filePath) {
    try {
      Process.run('paplay', [filePath]).then((result) {
        if (result.exitCode != 0) {
          Process.run('aplay', [filePath]);
        }
      });
    } catch (_) {
      try {
        Process.run('aplay', [filePath]);
      } catch (_) {}
    }
  }

  static void playCorrect() => _playSound('correct');
  static void playWrong() => _playSound('wrong');
  static void playCoin() => _playSound('coin');
  static void playLevelUp() => _playSound('levelup');
  static void playGameOver() => _playSound('gameover');
  static void playStreak() => _playSound('streak');

  // WAV Synthesizer Tones
  static List<int> _generateCorrectTones() {
    return _synthesizeSequence([
      _Tone(523.25, 0.08), // C5
      _Tone(659.25, 0.14), // E5
    ]);
  }

  static List<int> _generateWrongTones() {
    return _synthesizeSequence([
      _Tone(135.0, 0.22, isBuzzer: true), // Low buzzer buzz
    ]);
  }

  static List<int> _generateCoinTones() {
    return _synthesizeSequence([
      _Tone(987.77, 0.06), // B5
      _Tone(1318.51, 0.16), // E6
    ]);
  }

  static List<int> _generateLevelUpTones() {
    return _synthesizeSequence([
      _Tone(261.63, 0.07), // C4
      _Tone(329.63, 0.07), // E4
      _Tone(392.00, 0.07), // G4
      _Tone(523.25, 0.20), // C5
    ]);
  }

  static List<int> _generateGameOverTones() {
    return _synthesizeSequence([
      _Tone(392.00, 0.12), // G4
      _Tone(349.23, 0.12), // F4
      _Tone(311.13, 0.12), // Eb4
      _Tone(233.08, 0.32, isBuzzer: true), // Bb3 buzzer
    ]);
  }

  static List<int> _generateStreakTones() {
    return _synthesizeSequence([
      _Tone(659.25, 0.06), // E5
      _Tone(783.99, 0.06), // G5
      _Tone(1046.50, 0.18), // C6
    ]);
  }

  static List<int> _synthesizeSequence(
    List<_Tone> tones, {
    int sampleRate = 22050,
  }) {
    int totalSamples = 0;
    for (final tone in tones) {
      totalSamples += (sampleRate * tone.duration).toInt();
    }

    final dataSize = totalSamples * 2;
    final fileSize = 44 + dataSize;

    final header = ByteData(44);
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileSize - 8, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6d); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // space
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = Uint8List(fileSize);
    wavBytes.setRange(0, 44, header.buffer.asUint8List());

    final dataView = ByteData.view(wavBytes.buffer, 44, dataSize);
    int sampleOffset = 0;

    for (final tone in tones) {
      final toneSamples = (sampleRate * tone.duration).toInt();
      for (int i = 0; i < toneSamples; i++) {
        final t = i / sampleRate;
        double envelope = 1.0;
        if (t < 0.005) {
          envelope = t / 0.005;
        } else if (t > tone.duration - 0.015) {
          envelope = (tone.duration - t) / 0.015;
        }

        double waveValue;
        if (tone.isBuzzer) {
          final double valSine = math.sin(2 * math.pi * tone.frequency * t);
          final double valSquare = valSine >= 0 ? 1.0 : -1.0;
          waveValue = 0.7 * valSquare + 0.3 * valSine;
        } else {
          waveValue = math.sin(2 * math.pi * tone.frequency * t);
        }

        final sample = (waveValue * 32767 * envelope * 0.35).toInt().clamp(
          -32768,
          32767,
        );
        dataView.setInt16((sampleOffset + i) * 2, sample, Endian.little);
      }
      sampleOffset += toneSamples;
    }

    return wavBytes;
  }
}
