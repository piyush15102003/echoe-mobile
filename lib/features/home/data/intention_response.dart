class IntentionResponse {
  final String id;
  final String text;
  final List<String> generatedFrom;

  const IntentionResponse({
    required this.id,
    required this.text,
    required this.generatedFrom,
  });

  factory IntentionResponse.fromJson(Map<String, dynamic> json) {
    return IntentionResponse(
      id: json['id'] as String,
      text: json['text'] as String,
      generatedFrom:
          (json['generated_from'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
