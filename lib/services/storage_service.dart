import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../models/recipe.dart';
import '../models/grocery_item.dart';
import '../models/meal_plan.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Box<Recipe>? _recipesBox;
  Box? _settingsBox;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RecipeAdapter());
    }
    _recipesBox = await Hive.openBox<Recipe>(AppConstants.recipesBoxName);
    _settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    _prefs = await SharedPreferences.getInstance();
  }

  // Recipe operations
  Future<void> saveRecipe(Recipe recipe) async => await _recipesBox?.put(recipe.id, recipe);
  Future<void> deleteRecipe(String id) async => await _recipesBox?.delete(id);
  List<Recipe> getAllRecipes() => _recipesBox?.values.toList() ?? [];
  List<Recipe> getFavoriteRecipes() => _recipesBox?.values.where((r) => r.isFavorite).toList() ?? [];
  Recipe? getRecipe(String id) => _recipesBox?.get(id);

  Future<void> toggleFavorite(String id) async {
    final recipe = _recipesBox?.get(id);
    if (recipe != null) {
      recipe.isFavorite = !recipe.isFavorite;
      await recipe.save();
    }
  }

  Future<void> rateRecipe(String id, double rating, String? review) async {
    final recipe = _recipesBox?.get(id);
    if (recipe != null) {
      final reviews = List<String>.from(recipe.reviews ?? []);
      if (review != null && review.isNotEmpty) reviews.add(review);
      final updated = recipe.copyWith(rating: rating, reviews: reviews);
      await _recipesBox?.put(id, updated);
    }
  }

  List<Recipe> searchRecipes(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllRecipes().where((recipe) {
      return recipe.title.toLowerCase().contains(lowercaseQuery) ||
          recipe.ingredients.any((i) => i.toLowerCase().contains(lowercaseQuery)) ||
          (recipe.cuisine?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (recipe.tags?.any((t) => t.toLowerCase().contains(lowercaseQuery)) ?? false);
    }).toList();
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async => await _settingsBox?.put(key, value);
  T? getSetting<T>(String key, {T? defaultValue}) => _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  bool get isDarkMode => getSetting('isDarkMode', defaultValue: false) ?? false;
  Future<void> setDarkMode(bool value) async => await saveSetting('isDarkMode', value);
  String get selectedLanguage => getSetting('selectedLanguage', defaultValue: 'en') ?? 'en';
  Future<void> setSelectedLanguage(String language) async => await saveSetting('selectedLanguage', language);

  // Grocery List
  List<GroceryItem> getGroceryList() {
    final json = _prefs?.getString('grocery_list');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => GroceryItem.fromJson(e)).toList();
  }

  Future<void> saveGroceryList(List<GroceryItem> items) async {
    final json = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs?.setString('grocery_list', json);
  }

  Future<void> addGroceryItems(List<String> ingredients) async {
    final existing = getGroceryList();
    final existingNames = existing.map((e) => e.name.toLowerCase()).toSet();
    for (final ingredient in ingredients) {
      if (!existingNames.contains(ingredient.toLowerCase())) {
        existing.add(GroceryItem(
          id: DateTime.now().millisecondsSinceEpoch.toString() + ingredient,
          name: ingredient,
        ));
      }
    }
    await saveGroceryList(existing);
  }

  // Meal Plan
  MealPlan getMealPlan() {
    final json = _prefs?.getString('meal_plan');
    if (json == null) return MealPlan.empty();
    try {
      return MealPlan.fromJson(jsonDecode(json));
    } catch (_) {
      return MealPlan.empty();
    }
  }

  Future<void> saveMealPlan(MealPlan plan) async {
    await _prefs?.setString('meal_plan', jsonEncode(plan.toJson()));
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _recipesBox?.clear();
    await _settingsBox?.clear();
    await _prefs?.clear();
  }

  Map<String, dynamic> exportData() {
    return {
      'recipes': getAllRecipes().map((r) => r.toJson()).toList(),
      'settings': _settingsBox?.toMap() ?? {},
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      await clearAllData();
      if (data['recipes'] != null) {
        for (final json in (data['recipes'] as List)) {
          await saveRecipe(Recipe.fromJson(json));
        }
      }
      if (data['settings'] != null) {
        for (final entry in (data['settings'] as Map<String, dynamic>).entries) {
          await saveSetting(entry.key, entry.value);
        }
      }
      return true;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }
}
