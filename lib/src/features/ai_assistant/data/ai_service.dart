import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  static Future<String> generateCommand(
    String apiKey,
    String modelId,
    String userQuery,
  ) async {
    if (apiKey.isEmpty) {
      throw Exception('API Key is required. Please set it in Settings.');
    }

    final model = GenerativeModel(model: modelId, apiKey: apiKey);

    final prompt =
        '''
You are a highly skilled Linux command expert.
Your task is to provide the exact Linux command that satisfies the user's request.
RETURN ONLY THE COMMAND. NO MARKDOWN, NO EXPLANATION, NO CODE BLOCKS.
If the request is dangerous or ambiguous, provide a safe version or a comment starting with #.
Do not wrap it in backticks. Just the raw command string.

User Request: $userQuery
''';

    try {
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text?.trim() ?? '';
    } catch (e) {
      throw Exception('Failed to generate command: $e');
    }
  }
}
