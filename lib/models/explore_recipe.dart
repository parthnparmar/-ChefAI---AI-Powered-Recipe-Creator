class ExploreRecipe {
  final String id;
  final String title;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> instructions; // Added for cooking instructions
  final int cookingTime;
  final int calories;
  final double avgRating;
  final int ratingCount;
  final String? youtubeVideoId;
  final String? cuisine;
  final List<ExploreReview> reviews;
  bool isSaved;

  ExploreRecipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.ingredients,
    this.instructions = const [],
    required this.cookingTime,
    required this.calories,
    this.avgRating = 0.0,
    this.ratingCount = 0,
    this.youtubeVideoId,
    this.cuisine,
    this.reviews = const [],
    this.isSaved = false,
  });

  factory ExploreRecipe.fromFirestore(Map<String, dynamic> data, String id) {
    return ExploreRecipe(
      id: id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: List<String>.from(data['instructions'] ?? []),
      cookingTime: data['cookingTime'] ?? 0,
      calories: data['calories'] ?? 0,
      avgRating: (data['avgRating'] ?? 0.0).toDouble(),
      ratingCount: data['ratingCount'] ?? 0,
      youtubeVideoId: data['youtubeVideoId'],
      cuisine: data['cuisine'],
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'imageUrl': imageUrl,
        'ingredients': ingredients,
        'instructions': instructions,
        'cookingTime': cookingTime,
        'calories': calories,
        'avgRating': avgRating,
        'ratingCount': ratingCount,
        'youtubeVideoId': youtubeVideoId,
        'cuisine': cuisine,
      };
}

class ExploreReview {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final double rating;
  final DateTime createdAt;

  ExploreReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.rating,
    required this.createdAt,
  });

  factory ExploreReview.fromFirestore(Map<String, dynamic> data, String id) {
    return ExploreReview(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      text: data['text'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userName': userName,
        'text': text,
        'rating': rating,
        'createdAt': createdAt.toIso8601String(),
      };
}
