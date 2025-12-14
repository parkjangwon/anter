import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/app_lock_notifier.dart';
import 'lock_screen.dart';

class AppLockWrapper extends ConsumerWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to lock state
    final isLocked = ref.watch(appLockProvider.select((s) => s.isLocked));

    return Stack(
      children: [
        child,
        if (isLocked) const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
