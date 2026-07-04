import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;
  bool get isInitialized => _isInitialized;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => print('Speech recognition error: $val'),
        onStatus: (val) => print('Speech recognition status: $val'),
      );
      return _isInitialized;
    } catch (e) {
      print('Speech recognition init failed: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return;
    }
    await _speech.listen(
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          onResult(val.recognizedWords);
        }
      },
      localeId: localeId,
      listenMode: stt.ListenMode.search,
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }

  Future<List<String>> get availableLocales async {
    if (!_isInitialized) await initialize();
    if (_isInitialized) {
      final locales = await _speech.locales();
      return locales.map((l) => l.localeId).toList();
    }
    return [];
  }

  Future<bool> get hasPermission async {
    return _speech.hasPermission;
  }
}
