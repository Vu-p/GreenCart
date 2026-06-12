import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app/green_cart_app.dart';
import 'src/core/services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.instance.ensureInitialized();
  runApp(const ProviderScope(child: GreenCartApp()));
}
