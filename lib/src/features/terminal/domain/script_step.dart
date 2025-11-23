import 'dart:convert';

/// Represents a single script step with keyword matching
class ScriptStep {
  final String id;
  final String
  keyword; // Expected output keyword (e.g., "$", "password:", etc.)
  final String command; // Command to execute when keyword is matched
  final int delayMs; // Delay before executing command (optional)

  ScriptStep({
    String? id,
    required this.keyword,
    required this.command,
    this.delayMs = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  ScriptStep copyWith({
    String? id,
    String? keyword,
    String? command,
    int? delayMs,
  }) {
    return ScriptStep(
      id: id ?? this.id,
      keyword: keyword ?? this.keyword,
      command: command ?? this.command,
      delayMs: delayMs ?? this.delayMs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'keyword': keyword,
      'command': command,
      'delayMs': delayMs,
    };
  }

  factory ScriptStep.fromJson(Map<String, dynamic> json) {
    return ScriptStep(
      id: json['id'] as String?,
      keyword: json['keyword'] as String,
      command: json['command'] as String,
      delayMs: json['delayMs'] as int? ?? 0,
    );
  }

  @override
  String toString() =>
      'ScriptStep(keyword: $keyword, command: $command, delay: ${delayMs}ms)';
}

/// Login script model containing multiple steps
class LoginScript {
  final List<ScriptStep> steps;

  const LoginScript({this.steps = const []});

  LoginScript copyWith({List<ScriptStep>? steps}) {
    return LoginScript(steps: steps ?? this.steps);
  }

  String toJson() {
    final stepsJson = steps.map((s) => s.toJson()).toList();
    return jsonEncode({'steps': stepsJson});
  }

  factory LoginScript.fromJson(String json) {
    try {
      final Map<String, dynamic> data = jsonDecode(json);
      final List<dynamic> stepsJson = data['steps'] as List<dynamic>;
      final steps = stepsJson
          .map((s) => ScriptStep.fromJson(s as Map<String, dynamic>))
          .toList();
      return LoginScript(steps: steps);
    } catch (e) {
      return const LoginScript();
    }
  }

  bool get isEmpty => steps.isEmpty;
  bool get isNotEmpty => steps.isNotEmpty;
}
