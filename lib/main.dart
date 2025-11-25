import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/features/session/presentation/session_list_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'src/features/settings/presentation/settings_provider.dart';

import 'package:window_manager/window_manager.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const AnterApp(),
    ),
  );
}

class AnterApp extends ConsumerStatefulWidget {
  const AnterApp({super.key});

  @override
  ConsumerState<AnterApp> createState() => _AnterAppState();
}

class _AnterAppState extends ConsumerState<AnterApp> with WindowListener {
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      _initWindow();
    }
  }

  Future<void> _initWindow() async {
    // Set initial opacity from settings
    final settings = ref.read(settingsProvider);
    await windowManager.setOpacity(settings.windowOpacity);
    await windowManager.setPreventClose(
      true,
    ); // Always prevent close to handle it manually
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // I need a GlobalKey<NavigatorState> to show dialogs from here.
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeControllerProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey, // Assign key
      title: 'Anter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD0BCFF),
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: themeMode,
      home: PopScope(
        canPop: !Platform.isAndroid,
        onPopInvoked: _onPopInvoked,
        child: const SessionListScreen(),
      ),
    );
  }

  void _onPopInvoked(bool didPop) {
    if (didPop) return;

    if (Platform.isAndroid) {
      final now = DateTime.now();
      final isFirstPress = _lastBackPressed == null ||
          now.difference(_lastBackPressed!) > const Duration(seconds: 2);

      if (isFirstPress) {
        _lastBackPressed = now;
        final context = _navigatorKey.currentContext;
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
      SystemNavigator.pop();
    }
  }

  // Override onWindowClose to use _navigatorKey
  @override
  Future<void> onWindowClose() async {
    final settings = ref.read(settingsProvider);
    if (settings.confirmOnExit) {
      final context = _navigatorKey.currentContext;
      if (context == null) {
        await windowManager.destroy();
        return;
      }

      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Exit Anter?'),
          content: const Text(
            'Are you sure you want to close the application?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Exit'),
            ),
          ],
        ),
      );

      if (shouldClose == true) {
        await windowManager.destroy();
      }
    } else {
      await windowManager.destroy();
    }
  }
}
