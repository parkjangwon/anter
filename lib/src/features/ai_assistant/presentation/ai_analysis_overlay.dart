import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../application/gemini_analysis_service.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../terminal/application/terminal_buffer_helper.dart';
import 'package:xterm/xterm.dart';

final aiAnalysisProvider = Provider<GeminiAnalysisService>((ref) {
  final settings = ref.watch(settingsProvider);
  return GeminiAnalysisService(
    apiKey: settings.geminiApiKey,
    model: settings.geminiModel,
  );
});

class AIAnalysisOverlay extends ConsumerStatefulWidget {
  final Terminal terminal;
  final VoidCallback onClose;

  /// Optional: specific text to analyze (for drag & drop). If null, captures buffer.
  final String? selectedText;

  const AIAnalysisOverlay({
    super.key,
    required this.terminal,
    required this.onClose,
    this.selectedText,
  });

  @override
  ConsumerState<AIAnalysisOverlay> createState() => _AIAnalysisOverlayState();
}

class _AIAnalysisOverlayState extends ConsumerState<AIAnalysisOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  String? _analysisResult;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Slide from right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _startAnalysis();
  }

  Future<void> _startAnalysis() async {
    final service = ref.read(aiAnalysisProvider);
    final contextText =
        widget.selectedText ??
        TerminalBufferHelper.getSanitizedOutput(widget.terminal, lineCount: 50);

    final result = await service.analyzeTerminalOutput(contextText);

    if (mounted) {
      setState(() {
        _analysisResult = result;
        _isLoading = false;
      });
    }
  }

  void _handleClose() async {
    await _controller.reverse();
    widget.onClose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Command copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _runCommand(String command) {
    widget.terminal.textInput(command + '\r');
    _handleClose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Width Logic
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    // On mobile, take 90% width or full width. On desktop fixed 450.
    final panelWidth = isMobile ? screenWidth * 0.95 : 450.0;

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: panelWidth,
      child: SlideTransition(
        position: _offsetAnimation,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(16),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(
                  0.90,
                ), // Slightly more opaque for mobile readability
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
                ],
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
              child: SafeArea(
                // Crucial for mobile (notch/home bar)
                child: Column(
                  children: [
                    // Header
                    _buildHeader(context),

                    // Content
                    Expanded(
                      child: _isLoading
                          ? _buildLoading()
                          : _buildContent(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Insight',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _handleClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Analyzing terminal output...',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_analysisResult == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownBody(
        data: _analysisResult!,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
          p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
          code: TextStyle(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            fontFamily: 'MesloLGS NF',
            fontSize: 13,
          ),
          codeblockDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        builders: {'code': CodeElementBuilder(_copyToClipboard, _runCommand)},
      ),
    );
  }
}

// Custom Builder to make code blocks actionable
class CodeElementBuilder extends MarkdownElementBuilder {
  final Function(String) onCopy;
  final Function(String) onRun;

  CodeElementBuilder(this.onCopy, this.onRun);

  @override
  Widget? visitText(MarkdownText text, TextStyle? preferredStyle) {
    // This is tricky with MarkdownBody, simpler to just detect single-line commands
    // But for blocks, visitElement is better.
    return null;
  }

  @override
  Widget? visitElementAfter(
    MarkdownElement element,
    TextStyle? preferredStyle,
  ) {
    // Only target code blocks (not inline code) if possible,
    // but Markdown package generic 'code' tag handles both often.
    // Let's wrapping the text with action buttons.
    final text = element.textContent;
    // Simple heuristic: if multiline or contains spaces, treat as potentially actionable

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'MesloLGS NF', fontSize: 13),
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 14),
                label: const Text("Copy"),
                onPressed: () => onCopy(text),
              ),
              TextButton.icon(
                icon: const Icon(Icons.play_arrow, size: 14),
                label: const Text("Run"),
                onPressed: () => onRun(text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
