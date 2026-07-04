import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> initialize() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _isPlaying = false);
  }

  Future<void> speak(String text) async {
    if (_isPlaying) await stop();
    _isPlaying = true;
    await _tts.speak(text);
  }

  Future<void> speakRecipe(String title, List<String> ingredients, List<String> instructions) async {
    final buffer = StringBuffer();
    buffer.write('Recipe: $title. ');
    buffer.write('Ingredients: ${ingredients.join(', ')}. ');
    buffer.write('Instructions: ');
    for (int i = 0; i < instructions.length; i++) {
      buffer.write('Step ${i + 1}: ${instructions[i]}. ');
    }
    await speak(buffer.toString());
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _tts.stop();
  }

  Future<void> setLanguage(String languageCode) async {
    final langMap = {
      'en': 'en-US',
      'hi': 'hi-IN',
      'gu': 'gu-IN',
      'mr': 'mr-IN',
      'ta': 'ta-IN',
      'te': 'te-IN',
      'kn': 'kn-IN',
      'ml': 'ml-IN',
    };
    await _tts.setLanguage(langMap[languageCode] ?? 'en-US');
  }
}
