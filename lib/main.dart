import 'package:flutter/material.dart';
import "package:provider/provider.dart";
import 'package:qarzbook/screens/main_navigation_screen.dart';
import 'services/debt_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => DebtService(),
      child: const QarzBookApp(),
    ),
  );
}

class QarzBookApp extends StatelessWidget {
  const QarzBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qarz Book',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0056D2),
          primary: const Color(0xFF0056D2),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', // Default but clean
      ),
      home: MainNavigationScreen(key: MainNavigationScreen.navigationKey),
    );
  }
}

