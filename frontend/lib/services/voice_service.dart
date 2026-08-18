import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-IN");
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.15);
    await _flutterTts.setVolume(1.0);

    await setFemaleVoice();
  }

  Future<void> setFemaleVoice() async {
    final voices = await _flutterTts.getVoices;

    const femaleVoiceNames = [
      "female",
      "samantha",
      "zira",
      "aria",
      "jenny",
      "ava",
    ];

    for (final voice in voices) {
      final name = voice["name"].toString().toLowerCase();
      final locale = voice["locale"].toString().toLowerCase();

      final isIndianEnglish = locale.startsWith("en-in");
      final isFemaleVoice = femaleVoiceNames.any(
        (femaleName) => name.contains(femaleName),
      );

      if (isIndianEnglish && isFemaleVoice) {
        await _flutterTts.setVoice({
          "name": voice["name"],
          "locale": voice["locale"],
        });
        return;
      }
    }

    // Female Indian-English voice illa na, available female voice choose pannum.
    for (final voice in voices) {
      final name = voice["name"].toString().toLowerCase();

      final isFemaleVoice = femaleVoiceNames.any(
        (femaleName) => name.contains(femaleName),
      );

      if (isFemaleVoice) {
        await _flutterTts.setVoice({
          "name": voice["name"],
          "locale": voice["locale"],
        });
        return;
      }
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    await stop();
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}