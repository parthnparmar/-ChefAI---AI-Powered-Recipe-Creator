import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';
import '../models/explore_recipe.dart';

class TheMealDBService {
  static final TheMealDBService _instance = TheMealDBService._internal();
  factory TheMealDBService() => _instance;
  TheMealDBService._internal();

  static const String _baseUrl = 'https://www.themealdb.com/api/json/v1/1';

  // ── Search meals by keyword ───────────────────────────────────────────────
  Future<List<Recipe>> searchMeals(String query) async {
    try {
      final url = Uri.parse('$_baseUrl/search.php?s=${Uri.encodeComponent(query)}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null) {
          return meals.map((m) => _parseMealToRecipe(m)).toList();
        }
      }
    } catch (e) {
      print('TheMealDBService.searchMeals error: $e');
    }
    return [];
  }

  // ── Filter meals by ingredient ────────────────────────────────────────────
  Future<List<ExploreRecipe>> filterByIngredient(String ingredient) async {
    try {
      final url = Uri.parse('$_baseUrl/filter.php?i=${Uri.encodeComponent(ingredient)}');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null) {
          return meals.map((m) => ExploreRecipe(
            id: m['idMeal'] ?? '',
            title: m['strMeal'] ?? '',
            imageUrl: m['strMealThumb'] ?? '',
            ingredients: [ingredient],
            cookingTime: 25,
            calories: 380,
            cuisine: 'International',
            instructions: const [],
          )).toList();
        }
      }
    } catch (e) {
      print('TheMealDBService.filterByIngredient error: $e');
    }
    return [];
  }

  // ── Fetch meal details by ID ──────────────────────────────────────────────
  Future<Recipe?> getMealDetails(String id) async {
    try {
      final url = Uri.parse('$_baseUrl/lookup.php?i=$id');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return _parseMealToRecipe(meals.first);
        }
      }
    } catch (e) {
      print('TheMealDBService.getMealDetails error: $e');
    }
    return null;
  }

  // ── Get a random meal (for Daily Featured Recipe) ──────────────────────────
  Future<Recipe?> getRandomMeal() async {
    try {
      final url = Uri.parse('$_baseUrl/random.php');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final meals = data['meals'] as List?;
        if (meals != null && meals.isNotEmpty) {
          return _parseMealToRecipe(meals.first);
        }
      }
    } catch (e) {
      print('TheMealDBService.getRandomMeal error: $e');
    }
    return null;
  }

  // ── Fetch all categories ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final url = Uri.parse('$_baseUrl/categories.php');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final categories = data['categories'] as List?;
        if (categories != null) {
          return categories.map((c) => {
            'id': c['idCategory'],
            'name': c['strCategory'],
            'thumbnail': c['strCategoryThumb'],
            'description': c['strCategoryDescription'],
          }).toList();
        }
      }
    } catch (e) {
      print('TheMealDBService.getCategories error: $e');
    }
    return [];
  }

  // ── Parse a MealDB JSON map to a Recipe model ──────────────────────────────
  Recipe _parseMealToRecipe(Map<String, dynamic> meal) {
    // 1. Extract ingredients and measures
    final List<String> ingredients = [];
    for (int i = 1; i <= 20; i++) {
      final ing = meal['strIngredient$i'] as String?;
      final measure = meal['strMeasure$i'] as String?;
      if (ing != null && ing.trim().isNotEmpty) {
        final cleanIng = ing.trim();
        final cleanMeasure = measure != null ? measure.trim() : '';
        if (cleanMeasure.isNotEmpty) {
          ingredients.add('$cleanMeasure $cleanIng');
        } else {
          ingredients.add(cleanIng);
        }
      }
    }

    // 2. Parse step-by-step instructions
    final rawInstructions = meal['strInstructions'] as String? ?? '';
    List<String> instructions = rawInstructions
        .split(RegExp(r'\r\n|\r|\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && s.length > 3)
        .toList();

    if (instructions.isEmpty && rawInstructions.isNotEmpty) {
      instructions = [rawInstructions];
    }

    // 3. Extract YouTube Video ID
    String? ytId;
    final ytUrl = meal['strYoutube'] as String?;
    if (ytUrl != null && ytUrl.isNotEmpty) {
      try {
        final uri = Uri.tryParse(ytUrl);
        if (uri != null) {
          if (uri.host.contains('youtube.com')) {
            ytId = uri.queryParameters['v'];
          } else if (uri.host.contains('youtu.be')) {
            ytId = uri.pathSegments.firstOrNull;
          }
        }
      } catch (_) {}
    }

    final title = meal['strMeal'] ?? 'Untitled Meal';
    final category = meal['strCategory'] as String?;
    final area = meal['strArea'] as String?;

    // 4. Estimate prep/cook times, difficulty based on steps
    final stepsCount = instructions.length;
    final prepTime = 10 + (stepsCount * 2);
    final cookTime = 15 + (stepsCount * 3);
    
    String difficulty = 'Medium';
    if (stepsCount > 10) {
      difficulty = 'Hard';
    } else if (stepsCount < 5) {
      difficulty = 'Easy';
    }

    // 5. Generate mock nutrition profile
    final isVeg = category == 'Vegetarian' || category == 'Vegan';
    final isDessert = category == 'Dessert';
    
    final calories = isDessert ? 450 + (stepsCount * 20) : 320 + (stepsCount * 25);
    final protein = isVeg ? 6 + stepsCount : (isDessert ? 4 : 20 + stepsCount);
    final carbs = isDessert ? 50 + stepsCount : 20 + (stepsCount * 2);
    final fat = isDessert ? 18 + stepsCount : 8 + stepsCount;
    final fiber = isVeg ? 4 + (stepsCount / 2).round() : 1 + (stepsCount / 4).round();
    final sugar = isDessert ? 25 + stepsCount : 2 + (stepsCount / 3).round();

    final List<String> tags = [];
    if (category != null) tags.add(category);
    if (meal['strTags'] != null && meal['strTags'].toString().isNotEmpty) {
      tags.addAll(meal['strTags'].toString().split(',').map((t) => t.trim()));
    }

    return Recipe(
      id: meal['idMeal']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      ingredients: ingredients,
      instructions: instructions,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: 4,
      difficulty: difficulty,
      cuisine: area,
      tags: tags,
      imageUrl: meal['strMealThumb'],
      nutrition: {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sugar': sugar,
      },
    );
  }

  // ── Helper to convert a Recipe to ExploreRecipe ──────────────────────────
  ExploreRecipe recipeToExploreRecipe(Recipe r) {
    return ExploreRecipe(
      id: r.id,
      title: r.title,
      imageUrl: r.imageUrl ?? '',
      ingredients: r.ingredients,
      cookingTime: r.cookTime,
      calories: r.nutrition?['calories'] ?? 350,
      cuisine: r.cuisine ?? 'International',
      youtubeVideoId: null, // Custom parsed if needed
      instructions: r.instructions,
    );
  }
}
