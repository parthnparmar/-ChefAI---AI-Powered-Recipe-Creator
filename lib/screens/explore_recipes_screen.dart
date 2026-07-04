import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/explore_recipe.dart';
import '../services/explore_recipe_service.dart';
import '../utils/theme.dart';
import 'explore_recipe_detail_screen.dart';

class ExploreRecipesScreen extends StatefulWidget {
  const ExploreRecipesScreen({super.key});

  @override
  State<ExploreRecipesScreen> createState() => _ExploreRecipesScreenState();
}

class _ExploreRecipesScreenState extends State<ExploreRecipesScreen> {
  final _service = ExploreRecipeService();
  final _searchController = TextEditingController();

  List<ExploreRecipe> _recipes = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  String? _selectedCuisine;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() { _loading = true; _error = null; });
    try {
      final recipes = await _service.fetchRecipes();
      if (mounted) setState(() { _recipes = recipes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<ExploreRecipe> get _filtered {
    var list = _recipes;
    if (_selectedCuisine != null) list = list.where((r) => r.cuisine == _selectedCuisine).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
        r.title.toLowerCase().contains(q) ||
        (r.cuisine?.toLowerCase().contains(q) ?? false) ||
        r.ingredients.any((i) => i.toLowerCase().contains(q))).toList();
    }
    return list;
  }

  List<String> get _cuisines => _recipes.map((r) => r.cuisine).whereType<String>().toSet().toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(context),
          _buildSearchBar(context),
          if (_cuisines.isNotEmpty) _buildCuisineFilter(context),
          Expanded(child: _buildBody(context)),
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
              gradient: const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.explore_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Text('Explore Recipes',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          IconButton(
            onPressed: _loadRecipes,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Search recipes, cuisines, ingredients...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }

  Widget _buildCuisineFilter(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _cuisineChip(context, null, 'All'),
          ..._cuisines.map((c) => _cuisineChip(context, c, c)),
        ],
      ),
    );
  }

  Widget _cuisineChip(BuildContext context, String? value, String label) {
    final selected = _selectedCuisine == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCuisine = value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
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

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }
    if (_error != null) {
      return _buildFirebaseError(context);
    }
    if (_filtered.isEmpty) {
      return _buildEmpty(context);
    }
    return RefreshIndicator(
      onRefresh: _loadRecipes,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (ctx, i) => _ExploreCard(
          recipe: _filtered[i],
          onTap: () => Navigator.push(ctx, MaterialPageRoute(
            builder: (_) => ExploreRecipeDetailScreen(
              recipe: _filtered[i],
              onSavedToggled: () => setState(() {}),
            ),
          )),
          onSave: () async {
            await _service.toggleSaved(_filtered[i]);
            setState(() {});
          },
        ).animate(delay: Duration(milliseconds: i * 50)).fadeIn().slideY(begin: 0.05),
      ),
    );
  }

  Widget _buildFirebaseError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.orange),
            ),
            const SizedBox(height: 20),
            Text('Explore Unavailable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(
              'Firebase is not configured. Please set up Firebase to explore community recipes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRecipes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No recipes found', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final ExploreRecipe recipe;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _ExploreCard({required this.recipe, required this.onTap, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.07),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.network(
                recipe.imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 36),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (recipe.cuisine != null)
                      Text(recipe.cuisine!,
                          style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        _mini(Icons.timer_rounded, '${recipe.cookingTime}m', Colors.blue),
                        _mini(Icons.local_fire_department_rounded, '${recipe.calories}', Colors.orange),
                        _mini(Icons.star_rounded, recipe.avgRating.toStringAsFixed(1), Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: onSave,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: recipe.isSaved ? AppTheme.primary.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    recipe.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: recipe.isSaved ? AppTheme.primary : Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
