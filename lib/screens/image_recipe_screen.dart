import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/recipe_provider.dart';
import '../widgets/loading_widget.dart';
import 'recipe_detail_screen.dart';

class ImageRecipeScreen extends StatefulWidget {
  const ImageRecipeScreen({super.key});

  @override
  State<ImageRecipeScreen> createState() => _ImageRecipeScreenState();
}

class _ImageRecipeScreenState extends State<ImageRecipeScreen> {
  File? _image;
  final _picker = ImagePicker();

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    final provider = context.read<RecipeProvider>();
    await provider.generateRecipeFromImage(_image!.path);
    if (provider.currentRecipe != null && mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(
          recipe: provider.currentRecipe!,
          isNewRecipe: true,
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image to Recipe')),
      body: Consumer<RecipeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const AiThinkingWidget(message: 'Analyzing image with AI...');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Image preview
                GestureDetector(
                  onTap: () => _showPickerSheet(),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 260,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          width: 2,
                          style: BorderStyle.solid),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          ).animate().fadeIn().scale()
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 60,
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text('Tap to select food image',
                                  style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Source buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_image != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _analyze,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Recipe from Image'),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.3),

                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Take a photo of ingredients or a dish and AI will create a recipe for you!',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
