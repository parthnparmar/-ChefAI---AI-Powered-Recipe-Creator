import '../models/recipe.dart';
import '../models/recipe_request.dart';

class DemoService {
  static Recipe generateDemoRecipe(RecipeRequest request, [String? languageCode]) {
    final ingredients = request.ingredients;
    final dishType = request.dishType?.toLowerCase() ?? '';
    final cuisine = request.cuisine ?? 'International';
    final mainIngredient = ingredients.isNotEmpty ? ingredients.first.toLowerCase() : 'chicken';

    // Detect recipe type from ingredients or dish type
    final recipe = _matchRecipe(mainIngredient, dishType, cuisine, ingredients, request);
    return recipe;
  }

  static Recipe _matchRecipe(String main, String dishType, String cuisine,
      List<String> userIngredients, RecipeRequest request) {
    // Dessert detection
    if (dishType == 'dessert' || _isDesert(main, userIngredients)) {
      return _dessertRecipe(main, userIngredients, request);
    }
    // Pizza detection
    if (main.contains('pizza') || userIngredients.any((i) => i.toLowerCase().contains('pizza'))) {
      return _pizzaRecipe(userIngredients, request);
    }
    // Biryani detection
    if (main.contains('biryani') || userIngredients.any((i) => i.toLowerCase().contains('biryani'))) {
      return _biryaniRecipe(userIngredients, request);
    }
    // Pasta detection
    if (main.contains('pasta') || main.contains('spaghetti') || main.contains('noodle')) {
      return _pastaRecipe(userIngredients, request);
    }
    // Chicken
    if (main.contains('chicken')) {
      return _chickenRecipe(userIngredients, request, cuisine);
    }
    // Vegetarian / vegetables
    if (_isVegetarian(userIngredients)) {
      return _vegRecipe(userIngredients, request, cuisine);
    }
    // Default
    return _genericRecipe(main, userIngredients, request, cuisine);
  }

  static bool _isDesert(String main, List<String> ingredients) {
    final dessertKeywords = ['cake', 'cookie', 'brownie', 'chocolate', 'sugar', 'cream', 'ice cream', 'pudding', 'dessert', 'sweet', 'candy', 'muffin', 'cupcake'];
    return dessertKeywords.any((k) => main.contains(k) || ingredients.any((i) => i.toLowerCase().contains(k)));
  }

  static bool _isVegetarian(List<String> ingredients) {
    final meatKeywords = ['chicken', 'beef', 'pork', 'lamb', 'fish', 'shrimp', 'turkey', 'meat'];
    return !ingredients.any((i) => meatKeywords.any((k) => i.toLowerCase().contains(k)));
  }

  static Recipe _dessertRecipe(String main, List<String> userIngredients, RecipeRequest request) {
    final title = _capitalize(main).contains('Cake') || _capitalize(main).contains('Cookie')
        ? '${_capitalize(main)}'
        : 'Chocolate Lava Cake';
    return Recipe(
      title: title,
      ingredients: [
        '2 cups all-purpose flour',
        '1½ cups sugar',
        '½ cup butter, softened',
        '2 eggs',
        '1 cup milk',
        '½ cup cocoa powder',
        '1 tsp vanilla extract',
        '1 tsp baking powder',
        'Pinch of salt',
        ...userIngredients.where((i) => _isDesert(i.toLowerCase(), [])).take(2),
      ],
      instructions: [
        'Preheat oven to 180°C (350°F). Grease a baking pan.',
        'Cream butter and sugar together until light and fluffy.',
        'Beat in eggs one at a time, then add vanilla extract.',
        'Sift together flour, cocoa powder, baking powder, and salt.',
        'Gradually fold dry ingredients into the wet mixture, alternating with milk.',
        'Pour batter into prepared pan and smooth the top.',
        'Bake for 30-35 minutes until a toothpick inserted comes out clean.',
        'Let cool for 10 minutes before serving. Dust with powdered sugar.',
      ],
      prepTime: 20,
      cookTime: 35,
      servings: request.servings ?? 8,
      difficulty: 'Medium',
      cuisine: 'International',
      tags: ['Dessert', 'Baking', 'Sweet'],
      nutrition: {'calories': 320, 'protein': 5, 'carbs': 48, 'fat': 14},
      imageUrl: 'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=800',
    );
  }

  static Recipe _pizzaRecipe(List<String> userIngredients, RecipeRequest request) {
    return Recipe(
      title: 'Classic Margherita Pizza',
      ingredients: [
        '2¼ tsp active dry yeast',
        '1 cup warm water',
        '3 cups all-purpose flour',
        '2 tbsp olive oil',
        '1 tsp salt',
        '1 cup tomato sauce',
        '2 cups mozzarella cheese, shredded',
        'Fresh basil leaves',
        '2 cloves garlic, minced',
        '1 tsp dried oregano',
        ...userIngredients.where((i) => !['pizza'].contains(i.toLowerCase())).take(3),
      ],
      instructions: [
        'Dissolve yeast in warm water and let sit for 5 minutes until foamy.',
        'Mix flour and salt, then add yeast mixture and olive oil.',
        'Knead dough for 8-10 minutes until smooth and elastic.',
        'Let dough rise in a warm place for 1 hour until doubled.',
        'Preheat oven to 230°C (450°F) with a pizza stone or baking sheet.',
        'Roll out dough into a 12-inch circle on a floured surface.',
        'Spread tomato sauce evenly, leaving a 1-inch border.',
        'Top with mozzarella cheese and minced garlic.',
        'Bake for 12-15 minutes until crust is golden and cheese is bubbly.',
        'Garnish with fresh basil and a drizzle of olive oil before serving.',
      ],
      prepTime: 20,
      cookTime: 15,
      servings: request.servings ?? 4,
      difficulty: request.difficulty ?? 'Medium',
      cuisine: 'Italian',
      tags: ['Pizza', 'Italian', 'Baked'],
      nutrition: {'calories': 285, 'protein': 12, 'carbs': 38, 'fat': 10},
      imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800',
    );
  }

  static Recipe _biryaniRecipe(List<String> userIngredients, RecipeRequest request) {
    return Recipe(
      title: 'Chicken Biryani',
      ingredients: [
        '500g basmati rice, soaked 30 min',
        '750g chicken, cut into pieces',
        '2 large onions, thinly sliced',
        '2 tomatoes, chopped',
        '½ cup yogurt',
        '4 tbsp ghee or oil',
        '2 tsp biryani masala',
        '1 tsp turmeric powder',
        '1 tsp red chili powder',
        '1 tsp cumin seeds',
        '4 cardamom pods',
        '2 bay leaves',
        '1 cinnamon stick',
        'Fresh mint and coriander leaves',
        'Saffron soaked in warm milk',
        'Salt to taste',
      ],
      instructions: [
        'Marinate chicken with yogurt, biryani masala, turmeric, chili powder, and salt for 1 hour.',
        'Fry sliced onions in ghee until golden brown and crispy. Set aside half for garnish.',
        'In the same pan, add whole spices (cardamom, bay leaves, cinnamon, cumin).',
        'Add marinated chicken and cook on high heat for 5 minutes, then simmer for 15 minutes.',
        'Parboil rice with salt and whole spices until 70% cooked. Drain.',
        'Layer half the rice over the chicken, then add fried onions, mint, and coriander.',
        'Add remaining rice and drizzle saffron milk on top.',
        'Seal the pot with foil and cook on low heat (dum) for 25-30 minutes.',
        'Gently mix before serving. Garnish with remaining fried onions and fresh herbs.',
      ],
      prepTime: 30,
      cookTime: 60,
      servings: request.servings ?? 6,
      difficulty: 'Hard',
      cuisine: 'Indian',
      tags: ['Biryani', 'Indian', 'Rice', 'Chicken'],
      nutrition: {'calories': 520, 'protein': 32, 'carbs': 65, 'fat': 14},
      imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=800',
    );
  }

  static Recipe _pastaRecipe(List<String> userIngredients, RecipeRequest request) {
    return Recipe(
      title: 'Creamy Pasta Primavera',
      ingredients: [
        '400g pasta (penne or spaghetti)',
        '2 tbsp olive oil',
        '4 cloves garlic, minced',
        '1 cup heavy cream',
        '½ cup Parmesan cheese, grated',
        '1 cup cherry tomatoes, halved',
        '1 zucchini, sliced',
        '1 bell pepper, diced',
        '1 cup spinach',
        'Salt and black pepper to taste',
        'Fresh basil for garnish',
        ...userIngredients.where((i) => !['pasta', 'noodle', 'spaghetti'].contains(i.toLowerCase())).take(2),
      ],
      instructions: [
        'Cook pasta in salted boiling water until al dente. Reserve 1 cup pasta water.',
        'Heat olive oil in a large pan over medium heat.',
        'Sauté garlic for 1 minute until fragrant.',
        'Add bell pepper and zucchini, cook for 4-5 minutes.',
        'Add cherry tomatoes and cook for 2 more minutes.',
        'Pour in heavy cream and bring to a gentle simmer.',
        'Add spinach and stir until wilted.',
        'Toss in cooked pasta with Parmesan cheese.',
        'Add pasta water as needed to achieve desired consistency.',
        'Season with salt and pepper. Garnish with fresh basil.',
      ],
      prepTime: 10,
      cookTime: 20,
      servings: request.servings ?? 4,
      difficulty: request.difficulty ?? 'Easy',
      cuisine: 'Italian',
      tags: ['Pasta', 'Italian', 'Vegetarian', 'Quick'],
      nutrition: {'calories': 420, 'protein': 14, 'carbs': 58, 'fat': 16},
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
    );
  }

  static Recipe _chickenRecipe(List<String> userIngredients, RecipeRequest request, String cuisine) {
    return Recipe(
      title: 'Herb-Roasted Chicken',
      ingredients: [
        '1 whole chicken (1.5 kg) or 4 chicken breasts',
        '3 tbsp olive oil',
        '4 cloves garlic, minced',
        '1 lemon, zested and juiced',
        '2 tsp dried rosemary',
        '2 tsp dried thyme',
        '1 tsp paprika',
        'Salt and black pepper to taste',
        ...userIngredients.where((i) => !['chicken'].contains(i.toLowerCase())).take(4),
      ],
      instructions: [
        'Preheat oven to 200°C (400°F).',
        'Mix olive oil, garlic, lemon zest, lemon juice, rosemary, thyme, and paprika.',
        'Pat chicken dry with paper towels.',
        'Rub the herb mixture all over the chicken, including under the skin.',
        'Season generously with salt and pepper.',
        'Place in a roasting pan and roast for 45-60 minutes until juices run clear.',
        'Let rest for 10 minutes before carving.',
        'Serve with roasted vegetables and pan juices.',
      ],
      prepTime: 15,
      cookTime: 55,
      servings: request.servings ?? 4,
      difficulty: request.difficulty ?? 'Medium',
      cuisine: cuisine,
      tags: ['Chicken', 'Roasted', 'Protein-Rich'],
      nutrition: {'calories': 380, 'protein': 42, 'carbs': 4, 'fat': 22},
      imageUrl: 'https://images.unsplash.com/photo-1598103442097-8b74394b95c3?w=800',
    );
  }

  static Recipe _vegRecipe(List<String> userIngredients, RecipeRequest request, String cuisine) {
    return Recipe(
      title: 'Garden Vegetable Stir-Fry',
      ingredients: [
        ...userIngredients.take(5),
        '3 tbsp soy sauce',
        '2 tbsp sesame oil',
        '3 cloves garlic, minced',
        '1 tbsp fresh ginger, grated',
        '1 tbsp cornstarch',
        '2 tbsp vegetable oil',
        'Salt and pepper to taste',
        'Sesame seeds for garnish',
      ],
      instructions: [
        'Wash and chop all vegetables into bite-sized pieces.',
        'Mix soy sauce, sesame oil, and cornstarch in a small bowl.',
        'Heat vegetable oil in a wok or large pan over high heat.',
        'Add garlic and ginger, stir-fry for 30 seconds.',
        'Add harder vegetables first (carrots, broccoli) and cook for 3 minutes.',
        'Add softer vegetables and stir-fry for 2 more minutes.',
        'Pour sauce over vegetables and toss to coat.',
        'Cook for 1-2 minutes until sauce thickens.',
        'Garnish with sesame seeds and serve over rice or noodles.',
      ],
      prepTime: 15,
      cookTime: 15,
      servings: request.servings ?? 4,
      difficulty: request.difficulty ?? 'Easy',
      cuisine: cuisine,
      tags: ['Vegetarian', 'Healthy', 'Quick', 'Stir-Fry'],
      nutrition: {'calories': 180, 'protein': 6, 'carbs': 22, 'fat': 8},
      imageUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800',
    );
  }

  static Recipe _genericRecipe(String main, List<String> userIngredients, RecipeRequest request, String cuisine) {
    return Recipe(
      title: '${_capitalize(main)} Delight',
      ingredients: [
        ...userIngredients,
        '2 tbsp olive oil',
        '3 cloves garlic, minced',
        '1 onion, diced',
        'Salt and pepper to taste',
        'Fresh herbs for garnish',
      ],
      instructions: [
        'Prepare all ingredients by washing and cutting as needed.',
        'Heat olive oil in a large pan over medium heat.',
        'Sauté onion until translucent, about 3-4 minutes.',
        'Add garlic and cook for 1 minute until fragrant.',
        'Add main ingredients and cook according to their type.',
        'Season with salt and pepper throughout cooking.',
        'Cook until everything is tender and flavors have melded.',
        'Taste and adjust seasoning. Garnish with fresh herbs.',
        'Serve hot and enjoy!',
      ],
      prepTime: 15,
      cookTime: 25,
      servings: request.servings ?? 4,
      difficulty: request.difficulty ?? 'Medium',
      cuisine: cuisine,
      tags: ['Homemade', 'Quick'],
      nutrition: {'calories': 350, 'protein': 20, 'carbs': 30, 'fat': 15},
      imageUrl: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=800',
    );
  }

  static Recipe generateDemoRecipeFromImage() {
    return Recipe(
      title: 'Pasta Primavera',
      ingredients: ['400g pasta', '2 cups mixed vegetables', '3 tbsp olive oil', '4 cloves garlic', '½ cup Parmesan', 'Salt and pepper', 'Fresh basil'],
      instructions: ['Boil pasta until al dente', 'Sauté garlic in olive oil', 'Add vegetables and cook 5 minutes', 'Toss with pasta and Parmesan', 'Season and garnish with basil'],
      prepTime: 10,
      cookTime: 20,
      servings: 4,
      difficulty: 'Easy',
      cuisine: 'Italian',
      tags: ['Pasta', 'Vegetarian', 'Quick'],
      nutrition: {'calories': 380, 'protein': 12, 'carbs': 58, 'fat': 11},
      allergens: ['Gluten', 'Dairy'],
      imageUrl: 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800',
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }
}
