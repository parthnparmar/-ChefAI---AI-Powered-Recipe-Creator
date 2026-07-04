class RecipeRequest {
  final List<String> ingredients;
  final String? dishType;
  final String? cuisine;
  final String? difficulty;
  final int? servings;
  final List<String>? dietaryRestrictions;
  final int? maxPrepTime;

  RecipeRequest({
    required this.ingredients,
    this.dishType,
    this.cuisine,
    this.difficulty,
    this.servings,
    this.dietaryRestrictions,
    this.maxPrepTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'ingredients': ingredients,
      'dishType': dishType,
      'cuisine': cuisine,
      'difficulty': difficulty,
      'servings': servings,
      'dietaryRestrictions': dietaryRestrictions,
      'maxPrepTime': maxPrepTime,
    };
  }

  String toPrompt([String? languageCode]) {
    final buffer = StringBuffer();
    
    // Language-specific prompts
    final prompts = {
      'hi': 'इन सामग्रियों का उपयोग करके एक विस्तृत रेसिपी बनाएं: ${ingredients.join(", ")}',
      'gu': 'આ સામગ્રીનો ઉપયોગ કરીને વિગતવાર રેસિપી બનાવો: ${ingredients.join(", ")}',
      'mr': 'या साहित्याचा वापर करून तपशीलवार रेसिपी तयार करा: ${ingredients.join(", ")}',
      'ta': 'இந்த பொருட்களைப் பயன்படுத்தி விரிவான செய்முறையை உருவாக்கவும்: ${ingredients.join(", ")}',
    };
    
    buffer.write(prompts[languageCode] ?? 'Create a detailed recipe using these ingredients: ${ingredients.join(", ")}');
    
    if (dishType != null) buffer.write('. Dish type: $dishType');
    if (cuisine != null) buffer.write('. Cuisine: $cuisine');
    if (difficulty != null) buffer.write('. Difficulty: $difficulty');
    if (servings != null) buffer.write('. Servings: $servings');
    if (maxPrepTime != null) buffer.write('. Max prep time: $maxPrepTime minutes');
    if (dietaryRestrictions != null && dietaryRestrictions!.isNotEmpty) {
      buffer.write('. Dietary restrictions: ${dietaryRestrictions!.join(", ")}');
    }
    
    
    final languageInstructions = {
      'hi': '. कृपया इस JSON प्रारूप में उत्तर दें और सभी टेक्स्ट हिंदी में हो:',
      'gu': '. કૃપા કરીને આ JSON ફોર્મેટમાં જવાબ આપો અને બધું ટેક્સ્ટ ગુજરાતીમાં હોય:',
      'mr': '. कृपया या JSON स्वरूपात उत्तर द्या आणि सर्व मजकूर मराठीत असावा:',
      'ta': '. தயவுசெய்து இந்த JSON வடிவத்தில் பதிலளிக்கவும் மற்றும் அனைத்து உரையும் தமிழில் இருக்க வேண்டும்:',
    };
    
    buffer.write(languageInstructions[languageCode] ?? '. Please provide the response in this exact JSON format:');
    
    buffer.write('''
{
  "title": "Recipe Name",
  "ingredients": ["ingredient 1", "ingredient 2"],
  "instructions": ["step 1", "step 2"],
  "prepTime": 15,
  "cookTime": 30,
  "servings": 4,
  "difficulty": "Easy/Medium/Hard",
  "cuisine": "cuisine type",
  "tags": ["tag1", "tag2"]
}''');
    
    return buffer.toString();
  }
}