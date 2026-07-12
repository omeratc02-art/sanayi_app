import 'package:flutter/material.dart';

import 'screens/home/main_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SanayiApp());
}

class SanayiApp extends StatelessWidget {
  const SanayiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sanayi App',
      theme: AppTheme.light,
      home: const MainShell(),
    );
  }
}
