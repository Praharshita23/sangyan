import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/result_screen.dart';

void main() {
  runApp(const SangyanApp());
}

class SangyanApp extends StatelessWidget {
  const SangyanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sangyan',

      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7FF),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const HomeScreen(),
        '/scan': (context) => const ScanScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/result') {
          final args = settings.arguments;

          if (args is Map<String, dynamic>) {
            return MaterialPageRoute(
              builder: (_) => ResultScreen(
                message: args['message']?.toString() ?? '',
                analysis: args['analysis']?.toString() ?? '',
                isScam: args['isScam'] == true,
                scamType: args['scamType']?.toString() ?? 'Unknown',
                riskLevel: args['riskLevel']?.toString() ?? 'Unknown',
                confidence: (args['confidence'] as num?)?.toDouble() ?? 0.0,
                category: args['category']?.toString() ?? 'Unknown',
              ),
            );
          }
        }

        return null;
      },
    );
  }
}