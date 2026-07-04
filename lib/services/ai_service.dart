import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/recipe.dart';
import '../models/recipe_request.dart';
import '../services/storage_service.dart';
import '../services/demo_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  // Get active model setting: "OpenAI" or "Gemini"
  String get activeModel => _storage.getSetting<String>('aiModel', defaultValue: 'OpenAI') ?? 'OpenAI';

  // Get custom API keys
  String get openAIApiKey {
    final customKey = _storage.getSetting<String>('openAIApiKey') ?? '';
    return customKey.isNotEmpty ? customKey : ApiConfig.openAIApiKey;
  }

  String get geminiApiKey {
    return _storage.getSetting<String>('geminiApiKey') ?? '';
  }

  bool get isModelConfigured {
    if (activeModel == 'OpenAI') {
      final key = openAIApiKey;
      return key.isNotEmpty && key != 'YOUR_OPENAI_API_KEY_HERE' && key.startsWith('sk-');
    } else {
      return geminiApiKey.isNotEmpty;
    }
  }

  // ── Core Recipe Generation ────────────────────────────────────────────────
  Future<Recipe?> generateRecipe(RecipeRequest request, [String? languageCode]) async {
    if (!isModelConfigured) {
      await Future.delayed(const Duration(seconds: 2));
      return DemoService.generateDemoRecipe(request, languageCode);
    }

    final prompt = request.toPrompt(languageCode);

    try {
      if (activeModel == 'OpenAI') {
        return await _callOpenAI(prompt, systemPrompt: 'You are a professional chef. Always respond with valid JSON only.');
      } else {
        return await _callGemini(prompt, systemPrompt: 'You are a professional chef. You must generate valid culinary recipes. Ensure title, ingredients, cuisine, and instructions are completely consistent. Respond with JSON only.');
      }
    } catch (e) {
      print('AIService.generateRecipe error: $e');
      return DemoService.generateDemoRecipe(request, languageCode);
    }
  }

  // ── Image-based Recipe Generation ─────────────────────────────────────────
  Future<Recipe?> generateRecipeFromImage(String imagePath) async {
    // If not configured, return demo recipe from image
    if (!isModelConfigured) {
      await Future.delayed(const Duration(seconds: 2));
      return DemoService.generateDemoRecipeFromImage();
    }

    // Direct multi-modal call for image description
    // For simplicity, if OpenAI is configured, we can use GPT-4o-mini vision, else we use Gemini 1.5 Flash vision.
    // For demo/offline fallback, or if keys are empty:
    return DemoService.generateDemoRecipeFromImage();
  }

  // ── Improve Recipe ────────────────────────────────────────────────────────
  Future<Recipe?> improveRecipe(Recipe recipe, String improvement) async {
    final prompt = '''
Improve this recipe: "$improvement"
Current recipe details:
Title: ${recipe.title}
Ingredients: ${recipe.ingredients.join(', ')}
Instructions: ${recipe.instructions.join(' ')}
Servings: ${recipe.servings}
Difficulty: ${recipe.difficulty}
Cuisine: ${recipe.cuisine ?? 'International'}

You must make the requested changes. Respond with valid JSON in this exact structure:
{"title":"Recipe Name","ingredients":["ingredient 1"],"instructions":["step 1"],"prepTime":15,"cookTime":30,"servings":${recipe.servings},"difficulty":"${recipe.difficulty}","cuisine":"${recipe.cuisine ?? ''}","tags":[],"nutrition":{"calories":0,"protein":0,"carbs":0,"fat":0},"allergens":[]}
''';

    if (!isModelConfigured) {
      await Future.delayed(const Duration(seconds: 1));
      return recipe.copyWith(title: '${recipe.title} (Improved - $improvement)');
    }

    try {
      final Recipe? result;
      if (activeModel == 'OpenAI') {
        result = await _callOpenAI(prompt, systemPrompt: 'You are a professional chef. Always respond with valid JSON only.');
      } else {
        result = await _callGemini(prompt, systemPrompt: 'You are a professional chef. Respond with valid JSON only.');
      }

      if (result != null) {
        return recipe.copyWith(
          title: result.title.isNotEmpty ? result.title : recipe.title,
          ingredients: result.ingredients.isNotEmpty ? result.ingredients : recipe.ingredients,
          instructions: result.instructions.isNotEmpty ? result.instructions : recipe.instructions,
          prepTime: result.prepTime > 0 ? result.prepTime : recipe.prepTime,
          cookTime: result.cookTime > 0 ? result.cookTime : recipe.cookTime,
          servings: result.servings > 0 ? result.servings : recipe.servings,
          difficulty: result.difficulty,
          cuisine: result.cuisine,
          tags: result.tags,
          nutrition: result.nutrition,
          allergens: result.allergens,
        );
      }
    } catch (e) {
      print('AIService.improveRecipe error: $e');
    }
    return null;
  }

  // ── Analyze Nutrition ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> analyzeNutrition(Recipe recipe) async {
    final prompt = '''
Analyze the complete nutritional values for this recipe:
Title: ${recipe.title}
Ingredients: ${recipe.ingredients.join(', ')}
Servings: ${recipe.servings}

Estimate the values per serving. Respond with a valid JSON object ONLY:
{"calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0}
''';

    if (!isModelConfigured) {
      return {'calories': 420, 'protein': 22, 'carbs': 52, 'fat': 12, 'fiber': 4, 'sugar': 6};
    }

    try {
      final content = await _callRawText(prompt, systemPrompt: 'You are a nutritionist. Always respond with valid JSON only.');
      if (content != null) {
        return Map<String, dynamic>.from(jsonDecode(_cleanJsonResponse(content)));
      }
    } catch (e) {
      print('AIService.analyzeNutrition error: $e');
    }
    return null;
  }

  // ── Ingredient Substitutes ───────────────────────────────────────────────
  Future<List<String>> getIngredientSubstitutes(String ingredient, Recipe recipe) async {
    final prompt = '''
Suggest 3-5 cooking substitutes for the ingredient "$ingredient" in the recipe "${recipe.title}".
Respond with a valid JSON array only:
["substitute 1", "substitute 2", "substitute 3"]
''';

    if (!isModelConfigured) {
      return ['Alternative 1 for $ingredient', 'Alternative 2 for $ingredient'];
    }

    try {
      final content = await _callRawText(prompt, systemPrompt: 'You are a chef. Always respond with a valid JSON string array only.');
      if (content != null) {
        return List<String>.from(jsonDecode(_cleanJsonResponse(content)));
      }
    } catch (e) {
      print('AIService.getIngredientSubstitutes error: $e');
    }
    return [];
  }

  // ── Allergen Detection ────────────────────────────────────────────────────
  Future<List<String>> detectAllergens(Recipe recipe) async {
    final prompt = '''
Identify common food allergens present in these ingredients: ${recipe.ingredients.join(', ')}.
Check for: Gluten, Dairy, Eggs, Nuts, Soy, Shellfish, Fish, Sesame.
Respond with a valid JSON array only:
["allergen 1", "allergen 2"]
If no allergens are found, respond with an empty list: []
''';

    if (!isModelConfigured) {
      return ['Gluten', 'Dairy'];
    }

    try {
      final content = await _callRawText(prompt, systemPrompt: 'You are a food safety expert. Always respond with a valid JSON string array only.');
      if (content != null) {
        return List<String>.from(jsonDecode(_cleanJsonResponse(content)));
      }
    } catch (e) {
      print('AIService.detectAllergens error: $e');
    }
    return [];
  }

  // ── Internals: OpenAI HTTP client ────────────────────────────────────────
  Future<Recipe?> _callOpenAI(String prompt, {required String systemPrompt}) async {
    final response = await _dio.post(
      'https://api.openai.com/v1/chat/completions',
      options: Options(headers: {
        'Authorization': 'Bearer $openAIApiKey',
        'Content-Type': 'application/json',
      }),
      data: {
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1500,
        'temperature': 0.7,
      },
    );

    if (response.statusCode == 200) {
      final content = response.data['choices'][0]['message']['content'] as String;
      final cleaned = _cleanJsonResponse(content);
      final recipeData = jsonDecode(cleaned);
      return _recipeFromJson(recipeData);
    }
    return null;
  }

  // ── Internals: Gemini HTTP client ─────────────────────────────────────────
  Future<Recipe?> _callGemini(String prompt, {required String systemPrompt}) async {
    final response = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
      options: Options(headers: {
        'Content-Type': 'application/json',
      }),
      data: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$systemPrompt\n\nUser request:\n$prompt'}
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.7,
          'maxOutputTokens': 1500,
        }
      },
    );

    if (response.statusCode == 200) {
      final content = response.data['candidates'][0]['content']['parts'][0]['text'] as String;
      final cleaned = _cleanJsonResponse(content);
      final recipeData = jsonDecode(cleaned);
      return _recipeFromJson(recipeData);
    }
    return null;
  }

  // ── Helper: Call Raw Text (for lists and maps) ───────────────────────────
  Future<String?> _callRawText(String prompt, {required String systemPrompt}) async {
    if (activeModel == 'OpenAI') {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer $openAIApiKey',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
        },
      );
      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'] as String;
      }
    } else {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$geminiApiKey',
        options: Options(headers: {
          'Content-Type': 'application/json',
        }),
        data: {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': '$systemPrompt\n\n$prompt'}
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'maxOutputTokens': 400,
          }
        },
      );
      if (response.statusCode == 200) {
        return response.data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
    }
    return null;
  }

  // ── Helper: JSON parsing ──────────────────────────────────────────────────
  Recipe _recipeFromJson(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled Recipe';
    final query = Uri.encodeComponent('$title,food');
    final imageUrl = (data['imageUrl'] as String?)?.isNotEmpty == true
        ? data['imageUrl'] as String
        : 'https://source.unsplash.com/featured/800x400/?$query';
        
    return Recipe(
      title: title,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      prepTime: data['prepTime'] ?? 15,
      cookTime: data['cookTime'] ?? 25,
      servings: data['servings'] ?? 4,
      difficulty: data['difficulty'] ?? 'Medium',
      cuisine: data['cuisine'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      imageUrl: imageUrl,
      nutrition: data['nutrition'] != null ? Map<String, dynamic>.from(data['nutrition']) : null,
      allergens: data['allergens'] != null ? List<String>.from(data['allergens']) : null,
    );
  }

  // Clean JSON response (strip markdown blocks if returned)
  String _cleanJsonResponse(String content) {
    content = content.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '');
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      content = content.substring(jsonStart, jsonEnd + 1);
    } else {
      final arrayStart = content.indexOf('[');
      final arrayEnd = content.lastIndexOf(']');
      if (arrayStart != -1 && arrayEnd != -1 && arrayEnd > arrayStart) {
        content = content.substring(arrayStart, arrayEnd + 1);
      }
    }
    return content.trim();
  }
}
