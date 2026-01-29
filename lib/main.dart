import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/bootstrap.dart';
import 'src/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app dependencies
  await bootstrap();

  runApp(
    const ProviderScope(
      child: BookSwipeApp(),
    ),
  );
}
