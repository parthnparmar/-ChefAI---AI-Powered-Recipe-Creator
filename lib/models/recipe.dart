import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'recipe.g.dart';

@HiveType(typeId: 0)
class Recipe extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<String> ingredients;

  @HiveField(3)
  final List<String> instructions;

  @HiveField(4)
  final int prepTime;

  @HiveField(5)
  final int cookTime;

  @HiveField(6)
  final int servings;

  @HiveField(7)
  final String difficulty;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  bool isFavorite;

  @HiveField(10)
  final String? cuisine;

  @HiveField(11)
  final List<String>? tags;

  @HiveField(12)
  final String? imageUrl;

  // New fields
  @HiveField(13)
  final Map<String, dynamic>? nutrition; // {calories, protein, carbs, fat}

  @HiveField(14)
  double rating;

  @HiveField(15)
  final List<String>? reviews;

  @HiveField(16)
  final List<String>? allergens;

  @HiveField(17)
  final String? localImagePath; // for camera/gallery images

  Recipe({
    String? id,
    required this.title,
    required this.ingredients,
    required this.instructions,
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.difficulty = 'Medium',
    DateTime? createdAt,
    this.isFavorite = false,
    this.cuisine,
    this.tags,
    this.imageUrl,
    this.nutrition,
    this.rating = 0.0,
    this.reviews,
    this.allergens,
    this.localImagePath,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Recipe copyWith({
    String? title,
    List<String>? ingredients,
    List<String>? instructions,
    int? prepTime,
    int? cookTime,
    int? servings,
    String? difficulty,
    bool? isFavorite,
    String? cuisine,
    List<String>? tags,
    String? imageUrl,
    Map<String, dynamic>? nutrition,
    double? rating,
    List<String>? reviews,
    List<String>? allergens,
    String? localImagePath,
  }) {
    return Recipe(
      id: id,
      title: title ?? this.title,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      servings: servings ?? this.servings,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      cuisine: cuisine ?? this.cuisine,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      nutrition: nutrition ?? this.nutrition,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      allergens: allergens ?? this.allergens,
      localImagePath: localImagePath ?? this.localImagePath,
    );
  }

  int get totalTime => prepTime + cookTime;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'ingredients': ingredients,
      'instructions': instructions,
      'prepTime': prepTime,
      'cookTime': cookTime,
      'servings': servings,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
      'cuisine': cuisine,
      'tags': tags,
      'imageUrl': imageUrl,
      'nutrition': nutrition,
      'rating': rating,
      'reviews': reviews,
      'allergens': allergens,
      'localImagePath': localImagePath,
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      prepTime: json['prepTime'] ?? 0,
      cookTime: json['cookTime'] ?? 0,
      servings: json['servings'] ?? 1,
      difficulty: json['difficulty'] ?? 'Medium',
      createdAt: DateTime.parse(json['createdAt']),
      isFavorite: json['isFavorite'] ?? false,
      cuisine: json['cuisine'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      imageUrl: json['imageUrl'],
      nutrition: json['nutrition'] != null
          ? Map<String, dynamic>.from(json['nutrition'])
          : null,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] != null ? List<String>.from(json['reviews']) : null,
      allergens: json['allergens'] != null ? List<String>.from(json['allergens']) : null,
      localImagePath: json['localImagePath'],
    );
  }
}
