import 'package:flutter/material.dart';
import 'package:connevo/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late AnimationController _progressController;
  bool _showLoadingBar = false;

  @override
  void initState() {
    super.initState();

    // 1. Logo Animation Controller (1.5 seconds)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Pop In Effect (Elastic)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    // Spin Effect (1 full rotation)
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOutCubic,
      ),
    );

    // 2. Progress Bar Controller (3 seconds)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addListener(() {
        setState(() {});
      });

    // --- SEQUENTIAL EXECUTION ---
    // First, start the logo animations (Spin & Pop In)
    _logoController.forward().then((_) {
      if (mounted) {
        // After animations finish, show and animate the loading bar
        setState(() {
          _showLoadingBar = true;
        });

        _progressController.forward().then((_) {
          if (mounted) {
            // Navigate to AuthChecker once the 3s loading is complete
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AuthChecker(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 800),
              ),
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            // Logo with Scale (Pop In) and Rotation (Spin) animations
            ScaleTransition(
              scale: _scaleAnimation,
              child: RotationTransition(
                turns: _rotationAnimation,
                child: Image.asset(
                  'assets/logo.png',
                  width: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Sequential Loading Bar area
            SizedBox(
              height: 100,
              child: AnimatedOpacity(
                opacity: _showLoadingBar ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progressController.value,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A237E)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "Loading...",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
