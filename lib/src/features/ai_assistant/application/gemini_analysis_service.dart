import 'package:google_generative_ai/google_generative_ai.dart';
import '../../settings/domain/settings_state.dart';
import 'dart:io';

class GeminiAnalysisService {
  final String apiKey;
  final GeminiModel model;

  GeminiAnalysisService({required this.apiKey, required this.model});

  /// Analyzes the terminal output and provides a structured response.
  Future<String> analyzeTerminalOutput(String terminalContext) async {
    if (apiKey.isEmpty) {
      return "⚠️ **Error**: Gemini API Key is not set.\nPlease set it in Settings > AI Assistant.";
    }

    try {
      final generativModel = GenerativeModel(
        model: model.modelId,
        apiKey: apiKey,
      );

      final String systemLocale = Platform.localeName; // e.g., 'en_US', 'ko_KR'
      String languageInstruction = 'English';
      if (systemLocale.startsWith('ko')) {
        languageInstruction = 'KOREAN';
      } else if (systemLocale.startsWith('ja')) {
        languageInstruction = 'JAPANESE';
      } else if (systemLocale.startsWith('zh')) {
        languageInstruction = 'CHINESE';
      }

      final prompt =
          '''
Role: You are an expert generic Linux System Administrator and DevOps Engineer.
Task: Analyze the following terminal output provided by the user.

Terminal Output:
"""
$terminalContext
"""

Instructions:
1. **Focus**: Identify the **LAST executed command** and its result (usually at the bottom of the output).
    - If the last command failed, analyze the error.
    - If the last command succeeded, summarize the result.
    - If the last command is not visible or clear, analyze the general visible text for any issues or status.
    - **Ignore** previous command outputs unless they provide necessary context for the last command.
2. **Analysis**:
    - Identify what happened.
    - Determine the root cause (if error).
3. **Solution**: Provide the *exact* command to fix the issue or the next recommended step.
    - Wrap the recommended command in a code block like `command`.
4. **Tone**: Professional, Concise, Helpful.
5. **Language**: **$languageInstruction** (Translate everything to $languageInstruction).

Output Format (Markdown):
## 🔍 Analysis
<Focus on the last command's result>

## 🛠️ Solution
<Detailed solution or next steps>

## 💡 Recommended Action
`<command>`
''';

      final content = [Content.text(prompt)];
      final response = await generativModel.generateContent(content);

      return response.text ?? "⚠️ **Error**: No response from AI.";
    } catch (e) {
      return "⚠️ **Error**: AI Analysis failed.\nError: $e";
    }
  }
}
