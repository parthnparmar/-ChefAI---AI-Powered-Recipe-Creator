import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/recipe_provider.dart';
import '../widgets/recipe_card.dart';
import '../utils/theme.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFFF5722)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Favorites',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                final favs = provider.favoriteRecipes;
                if (favs.isEmpty) return _buildEmpty(context);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: favs.length,
                  itemBuilder: (ctx, i) => RecipeCard(recipe: favs[i])
                      .animate(delay: Duration(milliseconds: i * 60))
                      .fadeIn()
                      .slideX(begin: 0.08),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_border_rounded, size: 56, color: Colors.pink),
            ),
            const SizedBox(height: 24),
            Text('No Favorites Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Tap the heart icon on any recipe to save it here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
