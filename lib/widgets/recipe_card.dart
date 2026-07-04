import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import '../utils/theme.dart';
import '../screens/recipe_detail_screen.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;

  const RecipeCard({super.key, required this.recipe, this.onTap});

  String get _imageUrl {
    if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) return recipe.imageUrl!;
    final q = Uri.encodeComponent(recipe.title.split(' ').take(3).join(' '));
    return 'https://source.unsplash.com/featured/800x600/?$q,food';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap ?? () => Navigator.push(context, MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildImage(context),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(recipe.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Consumer<RecipeProvider>(
                        builder: (ctx, prov, _) => GestureDetector(
                          onTap: () => prov.toggleFavorite(recipe.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: recipe.isFavorite ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              recipe.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: recipe.isFavorite ? Colors.red : Colors.grey,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(context, Icons.timer_rounded, '${recipe.totalTime}m', AppTheme.primary),
                      _chip(context, Icons.people_rounded, '${recipe.servings}', const Color(0xFF4CAF50)),
                      _chip(context, Icons.bar_chart_rounded, recipe.difficulty, const Color(0xFF2196F3)),
                      if (recipe.cuisine != null)
                        _chip(context, Icons.public_rounded, recipe.cuisine!, const Color(0xFF9C27B0)),
                    ],
                  ),
                  if (recipe.nutrition != null) ...[
                    const SizedBox(height: 8),
                    _chip(context, Icons.local_fire_department_rounded,
                        '${recipe.nutrition!['calories'] ?? 0} kcal', Colors.orange),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final height = MediaQuery.of(context).size.width * 0.42;
    Widget img;
    if (recipe.localImagePath != null) {
      img = Image.file(File(recipe.localImagePath!), height: height, width: double.infinity, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(context, height));
    } else {
      img = Image.network(_imageUrl, height: height, width: double.infinity, fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null ? child : _shimmer(context, height),
          errorBuilder: (_, __, ___) => _placeholder(context, height));
    }
    return Stack(
      children: [
        ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(20)), child: img),
        if (recipe.rating > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text(recipe.rating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _shimmer(BuildContext context, double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _placeholder(BuildContext context, double height) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primary, AppTheme.secondary]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(child: Image.asset('assets/images/logo.png', width: 60, height: 60, fit: BoxFit.contain)),
    );
  }
}
