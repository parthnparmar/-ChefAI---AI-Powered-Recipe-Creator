import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';
import 'package:provider/provider.dart';

class RatingWidget extends StatefulWidget {
  final Recipe recipe;
  const RatingWidget({super.key, required this.recipe});

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late double _rating;
  final _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _rating = widget.recipe.rating;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Rating & Reviews',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1.0),
                  child: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Write a review (optional)...',
                isDense: true,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await context.read<RecipeProvider>().rateRecipe(
                      widget.recipe.id, _rating, _reviewController.text.trim());
                  _reviewController.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rating saved!')),
                    );
                  }
                },
                child: const Text('Submit Rating'),
              ),
            ),
            if (widget.recipe.reviews != null &&
                widget.recipe.reviews!.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Reviews',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...widget.recipe.reviews!.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(r,
                                style: Theme.of(context).textTheme.bodySmall)),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
