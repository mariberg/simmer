import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SimmerApp());
}

class SimmerApp extends StatelessWidget {
  const SimmerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Simmer',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
