import 'package:dio/dio.dart';
import '../config/api_config.dart';

class CurlTestService {
  static final Dio _dio = Dio();

  static Future<void> testOpenAIConnection() async {
    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${ApiConfig.openAIApiKey}',
          },
        ),
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'developer',
              'content': 'You are a helpful assistant.',
            },
            {
              'role': 'user',
              'content': 'Hello!',
            },
          ],
        },
      );
      
      print('OpenAI API Test Success: ${response.data}');
    } catch (e) {
      print('OpenAI API Test Error: $e');
    }
  }
}