import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../models/recipe.dart';
import '../models/recipe_request.dart';
import '../config/api_config.dart';
import 'demo_service.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  final Dio _dio = Dio();

  Future<Recipe?> generateRecipe(RecipeRequest request, [String? languageCode]) async {
    try {
      if (!ApiConfig.isApiKeyValid) {
        await Future.delayed(const Duration(seconds: 2));
        return DemoService.generateDemoRecipe(request, languageCode);
      }
      final response = await _dio.post(
        '${AppConstants.openAIBaseUrl}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': AppConstants.gptModel,
          'messages': [
            {'role': 'system', 'content': 'You are a professional chef. Always respond with valid JSON only.'},
            {'role': 'user', 'content': request.toPrompt(languageCode)},
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final recipeData = jsonDecode(_cleanJsonResponse(content));
        return _recipeFromJson(recipeData);
      }
    } catch (e) {
      print('Error generating recipe: $e');
      await Future.delayed(const Duration(seconds: 1));
      return DemoService.generateDemoRecipe(request, languageCode);
    }
    return null;
  }

  Future<Recipe?> generateRecipeFromImage(String imagePath) async {
    try {
      if (!ApiConfig.isApiKeyValid) {
        await Future.delayed(const Duration(seconds: 2));
        return DemoService.generateDemoRecipeFromImage();
      }
      final imageBytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await _dio.post(
        '${AppConstants.openAIBaseUrl}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': 'gpt-4o',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Identify the food/ingredients in this image and create a detailed recipe. Respond with valid JSON only:\n{"title":"","ingredients":[],"instructions":[],"prepTime":0,"cookTime":0,"servings":4,"difficulty":"Medium","cuisine":"","tags":[],"nutrition":{"calories":0,"protein":0,"carbs":0,"fat":0},"allergens":[]}'
                },
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                }
              ]
            }
          ],
          'max_tokens': 1500,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final recipeData = jsonDecode(_cleanJsonResponse(content));
        return _recipeFromJson(recipeData, localImagePath: imagePath);
      }
    } catch (e) {
      print('Error generating recipe from image: $e');
      return DemoService.generateDemoRecipeFromImage();
    }
    return null;
  }

  Future<Recipe?> improveRecipe(Recipe recipe, String improvement) async {
    try {
      final prompt = '''
Improve this recipe: "$improvement"
Current: ${recipe.title}, Ingredients: ${recipe.ingredients.join(', ')}
Instructions: ${recipe.instructions.join(' ')}
Respond with valid JSON only:
{"title":"","ingredients":[],"instructions":[],"prepTime":0,"cookTime":0,"servings":${recipe.servings},"difficulty":"${recipe.difficulty}","cuisine":"${recipe.cuisine ?? ''}","tags":[],"nutrition":{"calories":0,"protein":0,"carbs":0,"fat":0},"allergens":[]}''';

      if (!ApiConfig.isApiKeyValid) {
        await Future.delayed(const Duration(seconds: 1));
        return recipe.copyWith(title: '${recipe.title} (Improved - $improvement)');
      }

      final response = await _dio.post(
        '${AppConstants.openAIBaseUrl}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': AppConstants.gptModel,
          'messages': [
            {'role': 'system', 'content': 'You are a professional chef. Always respond with valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final recipeData = jsonDecode(_cleanJsonResponse(content));
        return recipe.copyWith(
          title: recipeData['title'] ?? recipe.title,
          ingredients: recipeData['ingredients'] != null ? List<String>.from(recipeData['ingredients']) : recipe.ingredients,
          instructions: recipeData['instructions'] != null ? List<String>.from(recipeData['instructions']) : recipe.instructions,
          prepTime: recipeData['prepTime'] ?? recipe.prepTime,
          cookTime: recipeData['cookTime'] ?? recipe.cookTime,
          servings: recipeData['servings'] ?? recipe.servings,
          difficulty: recipeData['difficulty'] ?? recipe.difficulty,
          cuisine: recipeData['cuisine'] ?? recipe.cuisine,
          tags: recipeData['tags'] != null ? List<String>.from(recipeData['tags']) : recipe.tags,
          nutrition: recipeData['nutrition'] != null ? Map<String, dynamic>.from(recipeData['nutrition']) : recipe.nutrition,
          allergens: recipeData['allergens'] != null ? List<String>.from(recipeData['allergens']) : recipe.allergens,
        );
      }
    } catch (e) {
      print('Error improving recipe: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> analyzeNutrition(Recipe recipe) async {
    try {
      if (!ApiConfig.isApiKeyValid) {
        return {'calories': 450, 'protein': 25, 'carbs': 55, 'fat': 15};
      }
      final prompt = 'Analyze nutrition for this recipe: ${recipe.title}\nIngredients: ${recipe.ingredients.join(', ')}\nServings: ${recipe.servings}\nRespond with JSON only: {"calories":0,"protein":0,"carbs":0,"fat":0,"fiber":0,"sugar":0}';

      final response = await _dio.post(
        '${AppConstants.openAIBaseUrl}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': AppConstants.gptModel,
          'messages': [
            {'role': 'system', 'content': 'You are a nutritionist. Respond with valid JSON only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 300,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        return Map<String, dynamic>.from(jsonDecode(_cleanJsonResponse(content)));
      }
    } catch (e) {
      print('Error analyzing nutrition: $e');
    }
    return null;
  }

  Future<List<String>> getIngredientSubstitutes(String ingredient, Recipe recipe) async {
    try {
      if (!ApiConfig.isApiKeyValid) {
        return ['Option 1 for $ingredient', 'Option 2 for $ingredient', 'Option 3 for $ingredient'];
      }
      final prompt = 'Suggest 3-5 substitutes for "$ingredient" in the recipe "${recipe.title}". Respond with JSON array only: ["substitute1","substitute2"]';

      final response = await _dio.post(
        '${AppConstants.openAIBaseUrl}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': AppConstants.gptModel,
          'messages': [
            {'role': 'system', 'content': 'You are a chef. Respond with valid JSON array only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 200,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final cleaned = content.trim().replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '');
        return List<String>.from(jsonDecode(cleaned));
      }
    } catch (e) {
      print('Error getting substitutes: $e');
    }
    return [];
  }

  Future<List<String>> detectAllergens(Recipe recipe) async {
    try {
      if (!ApiConfig.isApiKeyValid) {
        return ['Gluten', 'Dairy'];
      }
      final prompt = 'Detect allergens in: ${recipe.ingredients.join(', ')}. Common allergens: gluten, dairy, nuts, eggs, soy, shellfish, fish. Respond with JSON array only: ["allergen1"]';

      final response = await _dio.post(
        '${AppConstants.openAIBaseUrl}/chat/completions',
        options: Options(headers: {
          'Authorization': 'Bearer ${AppConstants.openAIApiKey}',
          'Content-Type': 'application/json',
        }),
        data: {
          'model': AppConstants.gptModel,
          'messages': [
            {'role': 'system', 'content': 'You are a food safety expert. Respond with valid JSON array only.'},
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 150,
        },
      );

      if (response.statusCode == 200) {
        final content = response.data['choices'][0]['message']['content'];
        final cleaned = content.trim().replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '');
        return List<String>.from(jsonDecode(cleaned));
      }
    } catch (e) {
      print('Error detecting allergens: $e');
    }
    return [];
  }

  Recipe _recipeFromJson(Map<String, dynamic> data, {String? localImagePath}) {
    final title = data['title'] ?? 'Untitled Recipe';
    final imageQuery = Uri.encodeComponent('${(title as String).split(' ').take(3).join(' ')},food');
    final imageUrl = (data['imageUrl'] as String?)?.isNotEmpty == true
        ? data['imageUrl'] as String
        : 'https://source.unsplash.com/featured/800x400/?$imageQuery';
    return Recipe(
      title: title,
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      prepTime: data['prepTime'] ?? 0,
      cookTime: data['cookTime'] ?? 0,
      servings: data['servings'] ?? 1,
      difficulty: data['difficulty'] ?? 'Medium',
      cuisine: data['cuisine'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : null,
      imageUrl: imageUrl,
      nutrition: data['nutrition'] != null ? Map<String, dynamic>.from(data['nutrition']) : null,
      allergens: data['allergens'] != null ? List<String>.from(data['allergens']) : null,
      localImagePath: localImagePath,
    );
  }

  String _cleanJsonResponse(String content) {
    content = content.replaceAll(RegExp(r'```json\s*'), '').replaceAll(RegExp(r'```\s*'), '');
    final jsonStart = content.indexOf('{');
    final jsonEnd = content.lastIndexOf('}');
    if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
      content = content.substring(jsonStart, jsonEnd + 1);
    }
    return content.trim();
  }
}
