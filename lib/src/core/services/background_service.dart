import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // This must match the function name
      onStart: onStart,
      autoStart: false, // We will manually start it when a session is active
      isForegroundMode: true,
      notificationChannelId: 'anter_background_service',
      initialNotificationTitle: 'Anter Terminal',
      initialNotificationContent: 'Initializing background service...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  // iOS background processing is more restrictive
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Logic to execute when the service starts
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Keep the service alive with a periodic timer or simply by being a foreground service
  // Since we just want to keep the isolates allowed, simply running is enough.
  // We can update notification content if needed.
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Anter Terminal",
      content: "Maintaing active SSH connections...",
    );
  }
}
