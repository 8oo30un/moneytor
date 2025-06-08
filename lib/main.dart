import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'firebase_options.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InitializationApp());
}

class InitializationApp extends StatelessWidget {
  const InitializationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        print('Firebase init state: ${snapshot.connectionState}');
        if (snapshot.hasError) {
          print('Firebase init error: ${snapshot.error}');
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Firebase init failed: ${snapshot.error}'),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.done) {
          print('Firebase 초기화 완료');
          return const MyApp();
        }
        return const MaterialApp(
          home: Scaffold(body: Center(child: CircularProgressIndicator())),
        );
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moneytor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
