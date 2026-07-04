import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/recipe_provider.dart';
import '../models/recipe.dart';
import '../widgets/recipe_card.dart';
import '../utils/theme.dart';

class RecipeHistoryScreen extends StatefulWidget {
  const RecipeHistoryScreen({super.key});

  @override
  State<RecipeHistoryScreen> createState() => _RecipeHistoryScreenState();
}

class _RecipeHistoryScreenState extends State<RecipeHistoryScreen> {
  String _query = '';
  String? _filterDifficulty;
  String? _filterCuisine;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(context),
          _buildFilters(context),
          Expanded(
            child: Consumer<RecipeProvider>(
              builder: (context, provider, _) {
                List<Recipe> recipes = _query.isEmpty
                    ? provider.getRecentRecipes(limit: 200)
                    : provider.searchRecipes(_query);
                if (_filterDifficulty != null) {
                  recipes = recipes.where((r) => r.difficulty == _filterDifficulty).toList();
                }
                if (_filterCuisine != null) {
                  recipes = recipes.where((r) => r.cuisine == _filterCuisine).toList();
                }
                if (recipes.isEmpty) return _buildEmpty(context);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: recipes.length,
                  itemBuilder: (ctx, i) => Dismissible(
                    key: Key(recipes[i].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                    ),
                    onDismissed: (_) => provider.deleteRecipe(recipes[i].id),
                    child: RecipeCard(recipe: recipes[i])
                        .animate(delay: Duration(milliseconds: i * 40))
                        .fadeIn()
                        .slideX(begin: 0.08),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2196F3), Color(0xFF03A9F4)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.history_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Recipe History',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search history...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          _filterChip(context, 'All', null, _filterDifficulty == null && _filterCuisine == null,
              () => setState(() { _filterDifficulty = null; _filterCuisine = null; })),
          const SizedBox(width: 8),
          _filterChip(context, 'Easy', 'difficulty', _filterDifficulty == 'Easy',
              () => setState(() => _filterDifficulty = _filterDifficulty == 'Easy' ? null : 'Easy')),
          const SizedBox(width: 8),
          _filterChip(context, 'Medium', 'difficulty', _filterDifficulty == 'Medium',
              () => setState(() => _filterDifficulty = _filterDifficulty == 'Medium' ? null : 'Medium')),
          const SizedBox(width: 8),
          _filterChip(context, 'Hard', 'difficulty', _filterDifficulty == 'Hard',
              () => setState(() => _filterDifficulty = _filterDifficulty == 'Hard' ? null : 'Hard')),
          const SizedBox(width: 8),
          _filterChip(context, '⭐ Favorites', 'fav', false,
              () => setState(() {})),
        ],
      ),
    );
  }

  Widget _filterChip(BuildContext context, String label, String? type, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppTheme.primary : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey)),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, size: 56, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          Text('No History Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text('Generated recipes will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
