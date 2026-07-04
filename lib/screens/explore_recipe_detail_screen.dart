import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../constants/app_constants.dart';
import '../models/explore_recipe.dart';
import '../services/explore_recipe_service.dart';
import '../services/firebase_service.dart';

class ExploreRecipeDetailScreen extends StatefulWidget {
  final ExploreRecipe recipe;
  final VoidCallback? onSavedToggled;

  const ExploreRecipeDetailScreen({
    super.key,
    required this.recipe,
    this.onSavedToggled,
  });

  @override
  State<ExploreRecipeDetailScreen> createState() => _ExploreRecipeDetailScreenState();
}

class _ExploreRecipeDetailScreenState extends State<ExploreRecipeDetailScreen> {
  final _service = ExploreRecipeService();
  final _reviewController = TextEditingController();
  YoutubePlayerController? _ytController;

  List<ExploreReview> _reviews = [];
  double _userRating = 0;
  bool _loadingReviews = true;
  bool _submitting = false;
  bool _showPlayer = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    final reviews = await _service.fetchReviews(widget.recipe.id);
    if (mounted) setState(() { _reviews = reviews; _loadingReviews = false; });
  }

  void _initPlayer() {
    if (widget.recipe.youtubeVideoId == null) return;
    _ytController = YoutubePlayerController(
      initialVideoId: widget.recipe.youtubeVideoId!,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
    setState(() => _showPlayer = true);
  }

  Future<void> _openYouTube() async {
    final videoId = widget.recipe.youtubeVideoId;
    if (videoId == null) return;
    final uri = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first')),
      );
      return;
    }
    if (!FirebaseService().isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to submit a review')),
      );
      return;
    }
    setState(() => _submitting = true);
    await _service.submitReview(
      recipeId: widget.recipe.id,
      rating: _userRating,
      reviewText: _reviewController.text.trim(),
    );
    _reviewController.clear();
    await _loadReviews();
    if (mounted) setState(() { _submitting = false; _userRating = 0; });
  }

  Future<void> _toggleSaved() async {
    if (!FirebaseService().isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to save recipes')),
      );
      return;
    }
    await _service.toggleSaved(widget.recipe);
    widget.onSavedToggled?.call();
    setState(() {});
  }

  @override
  void dispose() {
    _ytController?.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(recipe),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.mediumPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetaRow(recipe),
                  const SizedBox(height: AppConstants.mediumPadding),
                  if (_showPlayer && _ytController != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
                      child: YoutubePlayer(controller: _ytController!, showVideoProgressIndicator: true),
                    ),
                    const SizedBox(height: AppConstants.mediumPadding),
                  ],
                  _buildVideoButton(recipe),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildSection('Ingredients', _buildIngredients(recipe)),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildSection('Rate & Review', _buildRatingForm()),
                  const SizedBox(height: AppConstants.largePadding),
                  _buildSection('Reviews (${_reviews.length})', _buildReviewsList()),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ExploreRecipe recipe) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(
            recipe.isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: _toggleSaved,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          recipe.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Theme.of(context).primaryColor,
                child: const Icon(Icons.restaurant, size: 60, color: Colors.white),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(ExploreRecipe recipe) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(Icons.timer, '${recipe.cookingTime} min'),
        _chip(Icons.local_fire_department, '${recipe.calories} kcal'),
        _chip(Icons.star, recipe.avgRating.toStringAsFixed(1), color: Colors.amber),
        if (recipe.cuisine != null) _chip(Icons.public, recipe.cuisine!),
      ],
    );
  }

  Widget _chip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.largeRadius),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Theme.of(context).primaryColor),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildVideoButton(ExploreRecipe recipe) {
    if (recipe.youtubeVideoId == null) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showPlayer ? null : _initPlayer,
            icon: const Icon(Icons.play_circle_fill),
            label: Text(_showPlayer ? 'Playing...' : 'Watch Video'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _openYouTube,
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('YouTube'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppConstants.smallPadding),
        child,
      ],
    );
  }

  Widget _buildIngredients(ExploreRecipe recipe) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipe.ingredients.map((ing) => Chip(
        label: Text(ing, style: const TextStyle(fontSize: 12)),
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
        side: BorderSide.none,
      )).toList(),
    );
  }

  Widget _buildRatingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _userRating = i + 1.0),
            child: Icon(
              i < _userRating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 32,
            ),
          )),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        TextField(
          controller: _reviewController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Write your review (optional)...',
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitReview,
            child: _submitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Review'),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList() {
    if (_loadingReviews) return const Center(child: CircularProgressIndicator());
    if (_reviews.isEmpty) {
      return Text('No reviews yet. Be the first!',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey));
    }
    return Column(
      children: _reviews.map((r) => _ReviewTile(review: r)).toList(),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ExploreReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      padding: const EdgeInsets.all(AppConstants.mediumPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppConstants.mediumRadius),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < review.rating ? Icons.star : Icons.star_border,
                        size: 12,
                        color: Colors.amber,
                      )),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
          if (review.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.text, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
