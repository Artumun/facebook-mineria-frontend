import 'package:flutter/material.dart';
import 'views/login_view.dart';
import 'views/dashboard_view.dart';

void main() {
  runApp(const MineriaIAApp());
}

class MineriaIAApp extends StatelessWidget {
  const MineriaIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de análisis de interacciones • Facebook',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F172A),
          brightness: Brightness.light,
          primary: const Color(0xFF0F172A),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginView(),
        '/dashboard': (context) => const DashboardView(),
      },
    );
  }
}