import 'package:google_generative_ai/google_generative_ai.dart';
import '../../settings/domain/settings_state.dart';

class GeminiAnalysisService {
  final String apiKey;
  final GeminiModel model;

  GeminiAnalysisService({required this.apiKey, required this.model});

  /// Analyzes the terminal output and provides a structured response.
  Future<String> analyzeTerminalOutput(String terminalContext) async {
    if (apiKey.isEmpty) {
      return "⚠️ **오류**: Gemini API 키가 설정되지 않았습니다.\n설정(Settings) 메뉴 > AI Assistant 탭에서 API 키를 입력해주세요.";
    }

    try {
      final generativModel = GenerativeModel(
        model: model.modelId,
        apiKey: apiKey,
      );

      final prompt =
          '''
Role: You are an expert generic Linux System Administrator and DevOps Engineer.
Task: Analyze the following terminal output provided by the user.

Terminal Output:
"""
$terminalContext
"""

Instructions:
1. **Identify**: Briefly explain what is happening or what the error is.
2. **Analysis**:
    - If it's an error, identify the root cause.
    - If it's a status check (e.g., free, df), summarize the health status.
3. **Solution**: Provide the *exact* command to fix the issue or the next recommended step.
    - Wrap the recommended command in a code block like `command`.
    - If there are multiple steps, number them.
4. **Tone**: Professional, Concise, Helpful.
5. **Language**: **KOREAN** (Translate everything to Korean).

Output Format (Markdown):
## 🔍 분석 (Analysis)
<Brief explanation>

## 🛠️ 해결 방법 (Solution)
<Detailed solution or next steps>

## 💡 추천 명령어 (Action)
`<command>`
''';

      final content = [Content.text(prompt)];
      final response = await generativModel.generateContent(content);

      return response.text ?? "⚠️ **오류**: AI로부터 응답을 받지 못했습니다.";
    } catch (e) {
      return "⚠️ **오류 발생**: AI 분석 중 문제가 발생했습니다.\nError: $e";
    }
  }
}
