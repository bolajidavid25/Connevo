import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connevo/auth/screen/signup.dart';
import 'package:connevo/firebase_options.dart';
import 'package:connevo/home_screen.dart';
import 'package:connevo/splash_screen.dart';
import 'auth/services/auth_service.dart';
import 'auth/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const HomeScreen();
        }
        return const SignUpScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A237E)),
        ),
      ),
      error: (e, stack) => Scaffold(
        body: Center(
          child: Text('Error: $e'),
        ),
      ),
    );
  }
}
