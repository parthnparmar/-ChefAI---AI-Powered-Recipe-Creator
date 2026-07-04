import 'dart:async';
import 'package:flutter/foundation.dart';

// Firebase imports — guarded so app works without google-services.json
// ignore: depend_on_referenced_packages
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  fb_auth.FirebaseAuth get _auth => fb_auth.FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  bool _available = false;
  bool get isAvailable => _available;

  fb_auth.User? get currentUser => _available ? _auth.currentUser : null;
  bool get isSignedIn => currentUser != null;

  Stream<fb_auth.User?> get authStateChanges =>
      _available ? _auth.authStateChanges() : const Stream.empty();

  Future<void> initialize() async {
    try {
      // Firebase.initializeApp() must be called in main.dart before this
      _available = true;
    } catch (e) {
      _available = false;
      debugPrint('Firebase not available: $e');
    }
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<fb_auth.UserCredential?> signInWithEmail(
      String email, String password) async {
    if (!_available) return null;
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  Future<fb_auth.UserCredential?> signUpWithEmail(
      String email, String password) async {
    if (!_available) return null;
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
  }

  Future<void> signOut() async {
    if (!_available) return;
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_available) return;
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Cloud Sync ────────────────────────────────────────────────────────────

  Future<void> syncRecipe(Recipe recipe) async {
    if (!_available || currentUser == null) return;
    try {
      await _db
          .collection('users')
          .doc(currentUser!.uid)
          .collection('recipes')
          .doc(recipe.id)
          .set(recipe.toJson());
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> deleteCloudRecipe(String recipeId) async {
    if (!_available || currentUser == null) return;
    try {
      await _db
          .collection('users')
          .doc(currentUser!.uid)
          .collection('recipes')
          .doc(recipeId)
          .delete();
    } catch (e) {
      debugPrint('Delete cloud error: $e');
    }
  }

  Future<List<Recipe>> fetchCloudRecipes() async {
    if (!_available || currentUser == null) return [];
    try {
      final snap = await _db
          .collection('users')
          .doc(currentUser!.uid)
          .collection('recipes')
          .get();
      return snap.docs.map((d) => Recipe.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('Fetch error: $e');
      return [];
    }
  }
}
