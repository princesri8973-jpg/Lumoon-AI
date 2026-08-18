import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  bool get isListening => _speechToText.isListening;

  Future<bool> startListening({
    required Function(String text) onResult,
    required Function() onListeningStopped,
  }) async {
    final isAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (status == "done" || status == "notListening") {
          onListeningStopped();
        }
      },
      onError: (error) {
        onListeningStopped();
      },
    );

    if (!isAvailable) {
      return false;
    }

    await _speechToText.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: "en_IN",
      partialResults: true,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );

    return true;
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}