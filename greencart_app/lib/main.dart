import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/green_cart_app.dart';
import 'src/core/services/firebase_bootstrap.dart';
import 'src/core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(FirebaseBootstrap.instance.ensureInitialized());
  unawaited(LocalNotificationService().init());
  runApp(const ProviderScope(child: GreenCartApp()));
}
