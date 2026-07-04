import 'package:flutter/material.dart';

import '../config/api_config.dart';

class AppConstants {
  // API Configuration
  static String get openAIApiKey => ApiConfig.openAIApiKey;
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String gptModel = 'gpt-4o-mini';
  
  // Hive Box Names
  static const String recipesBoxName = 'recipes';
  static const String settingsBoxName = 'settings';
  
  // Theme Colors (aligned with AppTheme)
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color secondaryColor = Color(0xFFFF8C61);
  static const Color accentColor = Color(0xFFFFC107);
  static const Color backgroundColor = Color(0xFFFFF8F5);
  static const Color surfaceColor = Colors.white;
  static const Color errorColor = Color(0xFFE53E3E);
  
  // Dark Theme Colors
  static const Color darkPrimaryColor = Color(0xFFFF6B35);
  static const Color darkSecondaryColor = Color(0xFFFF8C61);
  static const Color darkBackgroundColor = Color(0xFF0F0F0F);
  static const Color darkSurfaceColor = Color(0xFF1A1A1A);
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Spacing
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;
  
  // Border Radius
  static const double smallRadius = 8.0;
  static const double mediumRadius = 12.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 24.0;
  
  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  // Cuisines
  static const List<String> cuisines = [
    'Italian',
    'Chinese',
    'Indian',
    'Mexican',
    'Japanese',
    'French',
    'Thai',
    'Mediterranean',
    'American',
    'Korean',
    'Vietnamese',
    'Greek',
  ];
  
  // Difficulty Levels
  static const List<String> difficultyLevels = [
    'Easy',
    'Medium',
    'Hard',
  ];
  
  // Dish Types
  static const List<String> dishTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Appetizer',
    'Soup',
    'Salad',
    'Main Course',
    'Side Dish',
  ];
  
  // Dietary Restrictions
  static const List<String> dietaryRestrictions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
    'Low-Carb',
    'Keto',
    'Paleo',
    'Halal',
    'Kosher',
  ];
  
  // Languages
  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिंदी',
    'gu': 'ગુજરાતી',
    'mr': 'मराठी',
    'ta': 'தமிழ்',
    'te': 'తెలుగు',
    'kn': 'ಕನ್ನಡ',
    'ml': 'മലയാളം',
  };
  
  // Recipe placeholder images
  static const List<String> recipeImages = [
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=400',
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400',
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400',
    'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400',
  ];
}