import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_constants.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  final double size;

  const LoadingWidget({super.key, this.message, this.size = 40.0});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            ),
          ).animate(onPlay: (c) => c.repeat()).rotate(duration: 1.seconds),
          if (message != null) ...[
            const SizedBox(height: AppConstants.mediumPadding),
            Shimmer.fromColors(
              baseColor: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey,
              highlightColor: Theme.of(context).primaryColor,
              child: Text(message!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            ),
          ],
        ],
      ),
    );
  }
}

/// Shimmer placeholder for recipe cards while loading
class RecipeCardShimmer extends StatelessWidget {
  const RecipeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 160, decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            )),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 18, width: 200, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: 140, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(height: 14, width: double.infinity, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated AI thinking indicator
class AiThinkingWidget extends StatelessWidget {
  final String message;
  const AiThinkingWidget({super.key, this.message = 'AI is thinking...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(begin: 0, end: -12, duration: 600.ms, delay: Duration(milliseconds: i * 150), curve: Curves.easeInOut)
                  .then()
                  .moveY(begin: -12, end: 0, duration: 600.ms, curve: Curves.easeInOut);
            }),
          ),
          const SizedBox(height: 20),
          Text(message, style: Theme.of(context).textTheme.bodyLarge)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 800.ms),
        ],
      ),
    );
  }
}
