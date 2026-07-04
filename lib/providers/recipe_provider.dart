import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/recipe_request.dart';
import '../models/grocery_item.dart';
import '../models/meal_plan.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

class RecipeProvider with ChangeNotifier {
  final AIService _aiService = AIService();
  final StorageService _storageService = StorageService();

  List<Recipe> _recipes = [];
  List<Recipe> _favoriteRecipes = [];
  Recipe? _currentRecipe;
  bool _isLoading = false;
  String? _error;
  List<GroceryItem> _groceryList = [];
  MealPlan _mealPlan = MealPlan.empty();

  List<Recipe> get recipes => _recipes;
  List<Recipe> get favoriteRecipes => _favoriteRecipes;
  Recipe? get currentRecipe => _currentRecipe;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<GroceryItem> get groceryList => _groceryList;
  MealPlan get mealPlan => _mealPlan;

  void loadRecipes() {
    _recipes = _storageService.getAllRecipes();
    _favoriteRecipes = _storageService.getFavoriteRecipes();
    _groceryList = _storageService.getGroceryList();
    _mealPlan = _storageService.getMealPlan();
    notifyListeners();
  }

  Future<void> generateRecipe(RecipeRequest request) async {
    _setLoading(true);
    _error = null;
    try {
      final languageCode = StorageService().selectedLanguage;
      final recipe = await _aiService.generateRecipe(request, languageCode);
      if (recipe != null) {
        _currentRecipe = recipe;
        await _storageService.saveRecipe(recipe);
        loadRecipes();
      } else {
        _error = 'Failed to generate recipe. Please try again.';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateRecipeFromImage(String imagePath) async {
    _setLoading(true);
    _error = null;
    try {
      final recipe = await _aiService.generateRecipeFromImage(imagePath);
      if (recipe != null) {
        _currentRecipe = recipe;
        await _storageService.saveRecipe(recipe);
        loadRecipes();
      } else {
        _error = 'Failed to generate recipe from image.';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> improveRecipe(Recipe recipe, String improvement) async {
    _setLoading(true);
    _error = null;
    try {
      final improvedRecipe = await _aiService.improveRecipe(recipe, improvement);
      if (improvedRecipe != null) {
        _currentRecipe = improvedRecipe;
        await _storageService.saveRecipe(improvedRecipe);
        loadRecipes();
      } else {
        _error = 'Failed to improve recipe. Please try again.';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>?> analyzeNutrition(Recipe recipe) async {
    return await _aiService.analyzeNutrition(recipe);
  }

  Future<List<String>> getIngredientSubstitutes(String ingredient, Recipe recipe) async {
    return await _aiService.getIngredientSubstitutes(ingredient, recipe);
  }

  Future<List<String>> detectAllergens(Recipe recipe) async {
    final allergens = await _aiService.detectAllergens(recipe);
    final updated = recipe.copyWith(allergens: allergens);
    await _storageService.saveRecipe(updated);
    loadRecipes();
    return allergens;
  }

  Future<void> rateRecipe(String id, double rating, String? review) async {
    await _storageService.rateRecipe(id, rating, review);
    loadRecipes();
  }

  Future<void> saveRecipe(Recipe recipe) async {
    await _storageService.saveRecipe(recipe);
    loadRecipes();
  }

  Future<void> deleteRecipe(String id) async {
    await _storageService.deleteRecipe(id);
    if (_currentRecipe?.id == id) _currentRecipe = null;
    loadRecipes();
  }

  Future<void> toggleFavorite(String id) async {
    await _storageService.toggleFavorite(id);
    loadRecipes();
  }

  List<Recipe> searchRecipes(String query) {
    if (query.isEmpty) return _recipes;
    return _storageService.searchRecipes(query);
  }

  void setCurrentRecipe(Recipe? recipe) {
    _currentRecipe = recipe;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Grocery List
  Future<void> addIngredientsToGrocery(List<String> ingredients) async {
    await _storageService.addGroceryItems(ingredients);
    _groceryList = _storageService.getGroceryList();
    notifyListeners();
  }

  Future<void> toggleGroceryItem(String id) async {
    final item = _groceryList.firstWhere((i) => i.id == id);
    item.isChecked = !item.isChecked;
    await _storageService.saveGroceryList(_groceryList);
    notifyListeners();
  }

  Future<void> removeGroceryItem(String id) async {
    _groceryList.removeWhere((i) => i.id == id);
    await _storageService.saveGroceryList(_groceryList);
    notifyListeners();
  }

  Future<void> clearCheckedGroceryItems() async {
    _groceryList.removeWhere((i) => i.isChecked);
    await _storageService.saveGroceryList(_groceryList);
    notifyListeners();
  }

  // Meal Plan
  Future<void> updateMealPlan(String day, String meal, String? recipeId) async {
    _mealPlan = _mealPlan.copyWithMeal(day, meal, recipeId);
    await _storageService.saveMealPlan(_mealPlan);
    notifyListeners();
  }

  // Filters
  List<Recipe> filterRecipes({String? cuisine, String? difficulty, List<String>? tags, int? maxPrepTime}) {
    return _recipes.where((recipe) {
      if (cuisine != null && recipe.cuisine != cuisine) return false;
      if (difficulty != null && recipe.difficulty != difficulty) return false;
      if (maxPrepTime != null && recipe.prepTime > maxPrepTime) return false;
      if (tags != null && tags.isNotEmpty) {
        final recipeTags = recipe.tags ?? [];
        if (!tags.any((tag) => recipeTags.contains(tag))) return false;
      }
      return true;
    }).toList();
  }

  Map<String, List<Recipe>> getRecipesByCuisine() {
    final Map<String, List<Recipe>> cuisineMap = {};
    for (final recipe in _recipes) {
      cuisineMap.putIfAbsent(recipe.cuisine ?? 'Other', () => []).add(recipe);
    }
    return cuisineMap;
  }

  List<Recipe> getRecentRecipes({int limit = 10}) {
    final sorted = List<Recipe>.from(_recipes)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
