// Android init when dart:io is available (mobile/desktop).
// Notifications disabled on Android: no permission, no channel, no background task.

import 'dart:io' show Platform;

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';

bool get isAndroid => Platform.isAndroid;

Future<void> initAndroidIfNeeded() async {
  if (!Platform.isAndroid) return;
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // Notification init and Workmanager removed for Resto App (no system notifications on Android).
}

/// No-op: notifications disabled on Android.
Future<void> scheduleOneOffNotificationCheck() async {}
