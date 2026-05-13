import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Class12c4App());
}

class Class12c4App extends StatelessWidget {
  const Class12c4App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lớp 12C4 — Kỷ niệm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const HomeShell(),
    );
  }
}
