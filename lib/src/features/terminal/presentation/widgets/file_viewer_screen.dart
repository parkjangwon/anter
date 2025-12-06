import 'package:flutter/material.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart' as hi;

class FileViewerScreen extends StatelessWidget {
  final String filePath;
  final String content;

  const FileViewerScreen({
    super.key,
    required this.filePath,
    required this.content,
  });

  // Helper to convert highlight nodes to TextSpan
  TextSpan _convert(List<hi.Node> nodes, Map<String, TextStyle> theme) {
    List<TextSpan> spans = [];
    var currentSpans = spans;
    List<List<TextSpan>> stack = [];

    void traverse(hi.Node node) {
      if (node.value != null) {
        currentSpans.add(TextSpan(text: node.value));
      } else if (node.children != null) {
        List<TextSpan> tmp = [];
        currentSpans.add(TextSpan(style: theme[node.className], children: tmp));
        stack.add(currentSpans);
        currentSpans = tmp;

        for (var n in node.children!) {
          traverse(n);
        }

        currentSpans = stack.removeLast();
      }
    }

    for (var node in nodes) {
      traverse(node);
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    // Basic language detection based on extension
    final ext = p.extension(filePath).replaceAll('.', '');

    // Mapping common extensions to highlight modes
    // flutter_highlight specific names (checking highlight package core names)
    String language = 'plaintext';
    switch (ext.toLowerCase()) {
      case 'dart':
        language = 'dart';
        break;
      case 'py':
        language = 'python';
        break;
      case 'js':
        language = 'javascript';
        break;
      case 'ts':
        language = 'typescript';
        break;
      case 'html':
        language = 'xml';
        break;
      case 'xml':
        language = 'xml';
        break;
      case 'css':
        language = 'css';
        break;
      case 'json':
        language = 'json';
        break;
      case 'yaml':
      case 'yml':
        language = 'yaml';
        break;
      case 'md':
        language = 'markdown';
        break;
      case 'sh':
      case 'bash':
        language = 'bash';
        break;
      case 'sql':
        language = 'sql';
        break;
      case 'c':
        language = 'cpp';
        break;
      case 'h':
        language = 'cpp';
        break;
      case 'cpp':
        language = 'cpp';
        break;
      case 'go':
        language = 'go';
        break;
      case 'java':
        language = 'java';
        break;
      case 'kt':
        language = 'kotlin';
        break;
      case 'swift':
        language = 'swift';
        break;
      case 'rs':
        language = 'rust';
        break;
      case 'rb':
        language = 'ruby';
        break;
      case 'php':
        language = 'php';
        break;
      case 'dockerfile':
        language = 'dockerfile';
        break;
      // Add more as needed
      default:
        // Try to match ext directly if logic above failed
        if (ext.isNotEmpty) language = ext;
    }

    // Parse content for highlighting
    hi.Result result;
    try {
      result = hi.highlight.parse(content, language: language);
    } catch (_) {
      // Fallback if language not found
      result = hi.highlight.parse(content, autoDetection: false);
    }

    final textSpan = _convert(result.nodes!, atomOneDarkTheme);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.basename(filePath)),
        centerTitle: true,
        // Hide default back button on macOS to avoid traffic light overlap
        automaticallyImplyLeading: !Platform.isMacOS,
        leading: Platform.isMacOS ? null : const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy All',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: content));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
          // Add Close button on the right for macOS (or typically all platforms for modal-like view)
          if (Platform.isMacOS)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
        ],
      ),
      body: Container(
        color: const Color(0xff282c34), // Match atom one dark background
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText.rich(
                textSpan,
                style: const TextStyle(
                  fontFamily: 'MesloLGS NF',
                  fontSize: 14,
                  color: Color(
                    0xffabb2bf,
                  ), // Default foreground color for One Dark
                ),
                cursorColor: Colors.blue,
                showCursor: true, // Helpful for selection feedback
              ),
            ),
          ),
        ),
      ),
    );
  }
}
