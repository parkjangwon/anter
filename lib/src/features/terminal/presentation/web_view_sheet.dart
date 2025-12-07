import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewSheet extends StatefulWidget {
  final String url;
  final VoidCallback onClose;

  const WebViewSheet({super.key, required this.url, required this.onClose});

  @override
  State<WebViewSheet> createState() => _WebViewSheetState();
}

class _WebViewSheetState extends State<WebViewSheet> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const String _consoleHookScript = '''
    window.hookConsole = function() {
      if (window.consoleHooked) return;
      
      var oldLog = console.log;
      console.log = function(message) {
        if (window.FlutterConsole) {
          window.FlutterConsole.postMessage("LOG: " + message);
        }
        oldLog.apply(console, arguments);
      };
      
      var oldError = console.error;
      console.error = function(message) {
        if (window.FlutterConsole) {
          window.FlutterConsole.postMessage("ERROR: " + message);
        }
        oldError.apply(console, arguments);
      };
      
      window.onerror = function(message, source, lineno, colno, error) {
        if (window.FlutterConsole) {
          window.FlutterConsole.postMessage("JS ERROR: " + message);
        }
      };

      window.addEventListener('error', function(e) {
        if (e.target && (e.target.tagName === 'SCRIPT' || e.target.tagName === 'LINK')) {
           if (window.FlutterConsole) {
              window.FlutterConsole.postMessage("RESOURCE LOAD ERROR: " + (e.target.src || e.target.href));
           }
        }
      }, true);
      
      window.consoleHooked = true;
      console.log("Console hooked successfully");
    };
    window.hookConsole();
  ''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterConsole',
        onMessageReceived: (JavaScriptMessage message) {
          print('WebView Console: ${message.message}');
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
            if (progress % 20 == 0) print('WebView Load Progress: $progress%');
          },
          onPageStarted: (String url) {
            print('WebView Page Started: $url');
            if (mounted) setState(() => _isLoading = true);
            // Try to inject early
            _controller.runJavaScript(_consoleHookScript);
          },
          onPageFinished: (String url) {
            print('WebView Page Finished: $url');
            if (mounted) setState(() => _isLoading = false);

            // Re-inject to ensure it persists
            _controller.runJavaScript(_consoleHookScript);

            // Check status
            _controller.runJavaScript('''
              console.log("Page Loaded: " + document.title);
              console.log("HTML length: " + document.body.innerHTML.length);
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            print(
              'WebView Resource Error: ${error.description} (${error.errorCode})',
            );
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _runDiagnostics() async {
    await _controller.runJavaScript('''
      (async function() {
        console.log("Running Network Diagnostics...");
        
        async function checkResource(path) {
          try {
            console.log("Fetching " + path + "...");
            const response = await fetch(path);
            console.log("Fetch " + path + ": " + response.status + " " + response.statusText);
            if (response.ok) {
              const text = await response.text();
              console.log("Content (" + path + "): " + text.substring(0, 100) + "...");
            } else {
              console.error("Failed to fetch " + path);
            }
          } catch (e) {
            console.error("Network error fetching " + path + ": " + e);
          }
        }

        await checkResource('/src/main.ts');
        await checkResource('/@vite/client');
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Web View',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.url,
              style: TextStyle(color: Colors.grey, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.black),
            tooltip: 'Run Diagnostics',
            onPressed: _runDiagnostics,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              _controller.clearCache();
              _controller.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Use a transparent container to avoid any background color interference
          Container(color: Colors.white),
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ),
    );
  }
}
