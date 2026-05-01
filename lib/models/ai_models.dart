class ChatRequest {
  final String message;
  final String sessionId;

  ChatRequest({
    required this.message,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'session_id': sessionId,
    };
  }
}

class ChatResponse {
  final bool ok;
  final String kind;
  final String reply;
  final List<Exercise>? exerciseExamples;
  final List<NutritionRecord>? nutritionExamples;
  final List<String>? suggestions;

  ChatResponse({
    required this.ok,
    required this.kind,
    required this.reply,
    this.exerciseExamples,
    this.nutritionExamples,
    this.suggestions,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      ok: json['ok'] ?? false,
      kind: json['kind'] ?? 'chat',
      reply: json['reply'] ?? '',
      exerciseExamples: json['exercise_examples'] != null
          ? (json['exercise_examples'] as List).map((i) => Exercise.fromJson(i)).toList()
          : null,
      nutritionExamples: json['nutrition_examples'] != null
          ? (json['nutrition_examples'] as List).map((i) => NutritionRecord.fromJson(i)).toList()
          : null,
      suggestions: json['suggestions'] != null
          ? List<String>.from(json['suggestions'])
          : null,
    );
  }
}

class Exercise {
  final String name;
  final String? muscles;
  final String? instruction;
  final String? gifUrl;

  Exercise({
    required this.name,
    this.muscles,
    this.instruction,
    this.gifUrl,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? 'Unknown Exercise',
      muscles: json['muscles'],
      instruction: json['instruction'],
      gifUrl: json['gif_url'],
    );
  }

  // We need this to save the exercise to SharedPreferences locally!
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'muscles': muscles,
      'instruction': instruction,
      'gif_url': gifUrl,
    };
  }
}

class NutritionRecord {
  final String name;
  final num? calories; // Using num because API might send int (640) or double (28.4)
  final num? protein;
  final num? carbohydrate;
  final num? fat;

  NutritionRecord({
    required this.name,
    this.calories,
    this.protein,
    this.carbohydrate,
    this.fat,
  });

  factory NutritionRecord.fromJson(Map<String, dynamic> json) {
    return NutritionRecord(
      name: json['name'] ?? 'Unknown Food',
      calories: json['calories'],
      protein: json['protein'],
      carbohydrate: json['carbohydrate'],
      fat: json['fat'],
    );
  }

  // We need this to save the nutrition data to SharedPreferences locally!
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbohydrate': carbohydrate,
      'fat': fat,
    };
  }
}