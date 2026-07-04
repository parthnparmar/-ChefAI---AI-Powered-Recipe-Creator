// API Configuration
// Replace with your actual OpenAI API key
class ApiConfig {
  static const String openAIApiKey = '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';
  
  // You can also load from environment variables or secure storage
  // static String get openAIApiKey => 
  //     const String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  
  // Validate API key
  static bool get isApiKeyValid => 
      openAIApiKey.isNotEmpty && 
      openAIApiKey != 'YOUR_OPENAI_API_KEY_HERE' &&
      openAIApiKey.startsWith('sk-');
}