import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/explore_recipe.dart';

class ExploreRecipeService {
  static final ExploreRecipeService _instance = ExploreRecipeService._internal();
  factory ExploreRecipeService() => _instance;
  ExploreRecipeService._internal();

  FirebaseFirestore? get _db {
    try { return FirebaseFirestore.instance; } catch (_) { return null; }
  }
  FirebaseAuth? get _auth {
    try { return FirebaseAuth.instance; } catch (_) { return null; }
  }

  String? get _uid => _auth?.currentUser?.uid;

  CollectionReference? get _recipesCol => _db?.collection('explore_recipes');

  // ── Fetch all explore recipes ─────────────────────────────────────────────

  Future<List<ExploreRecipe>> fetchRecipes() async {
    final db = _db;
    final col = _recipesCol;
    if (db == null || col == null) {
      return _localSampleRecipes();
    }
    try {
      final snap = await col.orderBy('avgRating', descending: true).get();
      final recipes = snap.docs
          .map((d) => ExploreRecipe.fromFirestore(d.data() as Map<String, dynamic>, d.id))
          .toList();

      if (_uid != null) {
        final savedSnap = await db
            .collection('users')
            .doc(_uid)
            .collection('saved_explore_recipes')
            .get();
        final savedIds = savedSnap.docs.map((d) => d.id).toSet();
        for (final r in recipes) {
          r.isSaved = savedIds.contains(r.id);
        }
      }

      if (recipes.isEmpty) {
        await _seedSampleRecipes();
        return fetchRecipes();
      }

      return recipes;
    } catch (e) {
      debugPrint('ExploreRecipeService.fetchRecipes error: $e');
      return _localSampleRecipes();
    }
  }

  // ── Fetch reviews for a recipe ────────────────────────────────────────────

  Future<List<ExploreReview>> fetchReviews(String recipeId) async {
    final col = _recipesCol;
    if (col == null) return [];
    try {
      final snap = await col
          .doc(recipeId)
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => ExploreReview.fromFirestore(d.data(), d.id))
          .toList();
    } catch (e) {
      debugPrint('fetchReviews error: $e');
      return [];
    }
  }

  // ── Submit rating + review ────────────────────────────────────────────────

  Future<void> submitReview({
    required String recipeId,
    required double rating,
    required String reviewText,
  }) async {
    if (_uid == null || _recipesCol == null) return;
    try {
      final user = _auth!.currentUser!;
      final reviewRef = _recipesCol!.doc(recipeId).collection('reviews').doc(_uid);

      await reviewRef.set(ExploreReview(
        id: _uid!,
        userId: _uid!,
        userName: user.displayName ?? user.email ?? 'Anonymous',
        text: reviewText,
        rating: rating,
        createdAt: DateTime.now(),
      ).toFirestore());

      final allReviews = await _recipesCol!.doc(recipeId).collection('reviews').get();
      final ratings = allReviews.docs
          .map((d) => (d.data()['rating'] as num).toDouble())
          .toList();
      final avg = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;

      await _recipesCol!.doc(recipeId).update({
        'avgRating': avg,
        'ratingCount': ratings.length,
      });
    } catch (e) {
      debugPrint('submitReview error: $e');
    }
  }

  // ── Save / unsave favorite ────────────────────────────────────────────────

  Future<void> toggleSaved(ExploreRecipe recipe) async {
    if (_uid == null || _db == null) return;
    try {
      final ref = _db!
          .collection('users')
          .doc(_uid)
          .collection('saved_explore_recipes')
          .doc(recipe.id);

      if (recipe.isSaved) {
        await ref.delete();
      } else {
        await ref.set(recipe.toFirestore());
      }
      recipe.isSaved = !recipe.isSaved;
    } catch (e) {
      debugPrint('toggleSaved error: $e');
    }
  }

  // ── Seed sample data ──────────────────────────────────────────────────────

  Future<void> _seedSampleRecipes() async {
    final col = _recipesCol;
    final db = _db;
    if (col == null || db == null) return;
    final samples = [
      {
        'title': 'Spaghetti Carbonara',
        'imageUrl': 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=600',
        'ingredients': ['Spaghetti', 'Eggs', 'Pancetta', 'Parmesan', 'Black Pepper'],
        'cookingTime': 25,
        'calories': 520,
        'avgRating': 4.7,
        'ratingCount': 128,
        'youtubeVideoId': '3AAdKl1UYZs',
        'cuisine': 'Italian',
      },
      {
        'title': 'Chicken Tikka Masala',
        'imageUrl': 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600',
        'ingredients': ['Chicken', 'Tomatoes', 'Cream', 'Garam Masala', 'Ginger', 'Garlic'],
        'cookingTime': 45,
        'calories': 480,
        'avgRating': 4.8,
        'ratingCount': 215,
        'youtubeVideoId': 'a03U45jFxOI',
        'cuisine': 'Indian',
      },
      {
        'title': 'Avocado Toast',
        'imageUrl': 'https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=600',
        'ingredients': ['Sourdough Bread', 'Avocado', 'Lemon', 'Red Pepper Flakes', 'Salt'],
        'cookingTime': 10,
        'calories': 290,
        'avgRating': 4.3,
        'ratingCount': 87,
        'youtubeVideoId': 'PKnkGMnBJow',
        'cuisine': 'American',
      },
      {
        'title': 'Beef Tacos',
        'imageUrl': 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600',
        'ingredients': ['Ground Beef', 'Taco Shells', 'Cheese', 'Lettuce', 'Salsa', 'Sour Cream'],
        'cookingTime': 20,
        'calories': 410,
        'avgRating': 4.5,
        'ratingCount': 163,
        'youtubeVideoId': 'yMfOyJeIz8c',
        'cuisine': 'Mexican',
      },
      {
        'title': 'Miso Ramen',
        'imageUrl': 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
        'ingredients': ['Ramen Noodles', 'Miso Paste', 'Pork Belly', 'Soft Egg', 'Nori', 'Green Onion'],
        'cookingTime': 60,
        'calories': 550,
        'avgRating': 4.9,
        'ratingCount': 302,
        'youtubeVideoId': 'GcXEHoMRJBc',
        'cuisine': 'Japanese',
      },
      {
        'title': 'Greek Salad',
        'imageUrl': 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=600',
        'ingredients': ['Cucumber', 'Tomatoes', 'Feta Cheese', 'Olives', 'Red Onion', 'Olive Oil'],
        'cookingTime': 10,
        'calories': 220,
        'avgRating': 4.4,
        'ratingCount': 95,
        'youtubeVideoId': 'Iy2ZFBbMFMQ',
        'cuisine': 'Greek',
      },
    ];

    final batch = db.batch();
    for (final s in samples) {
      batch.set(col.doc(), s);
    }
    await batch.commit();
  }

  List<ExploreRecipe> _localSampleRecipes() {
    return [
      ExploreRecipe(id: '1', title: 'Spaghetti Carbonara',
        imageUrl: 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=600',
        ingredients: ['Spaghetti', 'Eggs', 'Pancetta', 'Parmesan', 'Black Pepper'],
        cookingTime: 25, calories: 520, avgRating: 4.7, ratingCount: 128,
        youtubeVideoId: '3AAdKl1UYZs', cuisine: 'Italian'),
      ExploreRecipe(id: '2', title: 'Chicken Tikka Masala',
        imageUrl: 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=600',
        ingredients: ['Chicken', 'Tomatoes', 'Cream', 'Garam Masala', 'Ginger', 'Garlic'],
        cookingTime: 45, calories: 480, avgRating: 4.8, ratingCount: 215,
        youtubeVideoId: 'a03U45jFxOI', cuisine: 'Indian'),
      ExploreRecipe(id: '3', title: 'Avocado Toast',
        imageUrl: 'https://images.unsplash.com/photo-1541519227354-08fa5d50c820?w=600',
        ingredients: ['Sourdough Bread', 'Avocado', 'Lemon', 'Red Pepper Flakes', 'Salt'],
        cookingTime: 10, calories: 290, avgRating: 4.3, ratingCount: 87,
        youtubeVideoId: 'PKnkGMnBJow', cuisine: 'American'),
      ExploreRecipe(id: '4', title: 'Beef Tacos',
        imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=600',
        ingredients: ['Ground Beef', 'Taco Shells', 'Cheese', 'Lettuce', 'Salsa'],
        cookingTime: 20, calories: 410, avgRating: 4.5, ratingCount: 163,
        youtubeVideoId: 'yMfOyJeIz8c', cuisine: 'Mexican'),
      ExploreRecipe(id: '5', title: 'Miso Ramen',
        imageUrl: 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600',
        ingredients: ['Ramen Noodles', 'Miso Paste', 'Pork Belly', 'Soft Egg', 'Nori'],
        cookingTime: 60, calories: 550, avgRating: 4.9, ratingCount: 302,
        youtubeVideoId: 'GcXEHoMRJBc', cuisine: 'Japanese'),
      ExploreRecipe(id: '6', title: 'Greek Salad',
        imageUrl: 'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=600',
        ingredients: ['Cucumber', 'Tomatoes', 'Feta Cheese', 'Olives', 'Red Onion'],
        cookingTime: 10, calories: 220, avgRating: 4.4, ratingCount: 95,
        youtubeVideoId: 'Iy2ZFBbMFMQ', cuisine: 'Greek'),
    ];
  }
}
