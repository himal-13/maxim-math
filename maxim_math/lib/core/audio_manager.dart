import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

class _Tone {
  final double frequency;
  final double duration;
  final double volume;

  _Tone(this.frequency, this.duration, {required this.volume});
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
    await file.writeAsBytes(bytes);
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

  // WAV Synthesizer Tones (44.1kHz, Stereo, 70% Sine + 30% Triangle)
  static List<int> _generateCorrectTones() {
    return _synthesizeSequence([
      _Tone(523.25, 0.10, volume: 0.40), // C5
      _Tone(659.25, 0.15, volume: 0.40), // E5
    ]);
  }

  static List<int> _generateWrongTones() {
    return _synthesizeSequence([
      _Tone(349.23, 0.12, volume: 0.35), // F4
      _Tone(293.66, 0.18, volume: 0.35), // D4
    ]);
  }

  static List<int> _generateCoinTones() {
    return _synthesizeSequence([
      _Tone(987.77, 0.08, volume: 0.45), // B5
      _Tone(1318.51, 0.12, volume: 0.45), // E6
    ]);
  }

  static List<int> _generateLevelUpTones() {
    return _synthesizeSequence([
      _Tone(261.63, 0.10, volume: 0.50), // C4
      _Tone(329.63, 0.10, volume: 0.50), // E4
      _Tone(392.00, 0.10, volume: 0.50), // G4
      _Tone(523.25, 0.20, volume: 0.50), // C5
    ]);
  }

  static List<int> _generateGameOverTones() {
    return _synthesizeSequence([
      _Tone(392.00, 0.12, volume: 0.35), // G4
      _Tone(349.23, 0.12, volume: 0.35), // F4
      _Tone(311.13, 0.12, volume: 0.35), // Eb4
      _Tone(233.08, 0.24, volume: 0.35), // Bb3
    ]);
  }

  static List<int> _generateStreakTones() {
    return _synthesizeSequence([
      _Tone(659.25, 0.08, volume: 0.50), // E5
      _Tone(783.99, 0.08, volume: 0.50), // G5
      _Tone(1046.50, 0.14, volume: 0.50), // C6
    ]);
  }

  static double _triangleWave(double t, double freq) {
    final period = 1.0 / freq;
    final relativeT = t % period;
    final ratio = relativeT / period;
    if (ratio < 0.25) {
      return ratio * 4.0;
    } else if (ratio < 0.75) {
      return 2.0 - ratio * 4.0;
    } else {
      return ratio * 4.0 - 4.0;
    }
  }

  static List<int> _synthesizeSequence(
    List<_Tone> tones, {
    int sampleRate = 44100,
  }) {
    int totalSamples = 0;
    for (final tone in tones) {
      totalSamples += (sampleRate * tone.duration).toInt();
    }

    final dataSize = totalSamples * 4;
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
    header.setUint16(20, 1, Endian.little); // Format: PCM
    header.setUint16(22, 2, Endian.little); // Stereo (2 channels)
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 4, Endian.little); // ByteRate
    header.setUint16(32, 4, Endian.little); // BlockAlign
    header.setUint16(34, 16, Endian.little); // BitsPerSample
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
          envelope = t / 0.005; // 5ms fade-in
        } else if (t > tone.duration - 0.010) {
          envelope = (tone.duration - t) / 0.010; // 10ms fade-out
        }
        if (envelope < 0) envelope = 0;

        final sineVal = math.sin(2 * math.pi * tone.frequency * t);
        final triVal = _triangleWave(t, tone.frequency);
        final waveValue = 0.7 * sineVal + 0.3 * triVal;

        final sample = (waveValue * 32767 * envelope * tone.volume).toInt().clamp(
          -32768,
          32767,
        );

        // Write Left Channel
        dataView.setInt16((sampleOffset + i) * 4, sample, Endian.little);
        // Write Right Channel
        dataView.setInt16((sampleOffset + i) * 4 + 2, sample, Endian.little);
      }
      sampleOffset += toneSamples;
    }

    return wavBytes;
  }
}
