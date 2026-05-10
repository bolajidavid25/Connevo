import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connevo/auth/screen/signup.dart';
import '../services/auth_provider.dart';
import '../services/auth_service.dart';

class UserLoginScreen extends ConsumerStatefulWidget {
  const UserLoginScreen({super.key});

  @override
  ConsumerState<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends ConsumerState<UserLoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ref.read(authFormProvider.notifier).clear();
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutCirc)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showInvalidUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Invalid User"),
        content: const Text("User not found. Please sign up to create an account."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authFormProvider.notifier).clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: const Text("Sign Up", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Forgot Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email address to receive a password reset link."),
            const SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Email",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A237E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final authMethod = ref.read(authMethodProvider);
              final res = await authMethod.resetPassword(email: emailController.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res == "Success" ? "Password reset link sent to your email" : res),
                  backgroundColor: res == "Success" ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Send Link", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _loginUser() async {
    final formNotifier = ref.read(authFormProvider.notifier);
    final authMethod = ref.read(authMethodProvider);
    final formState = ref.read(authFormProvider);

    formNotifier.setLoading(true);
    final res = await authMethod.loginUser(
      email: formState.email,
      password: formState.password,
    );

    if (res != "Success") {
      if (mounted) {
        formNotifier.setLoading(false);
        if (res == "Invalid user, please sign up") {
          _showInvalidUserDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(authFormProvider);
    final formNotifier = ref.read(authFormProvider.notifier);
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("Login", style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
      ),
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Watermark Logo
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Image.asset('assets/logo.png', fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: height * 0.3,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage('assets/logo_join_animation.gif'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          const Text(
                            "Welcome Back",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A237E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            "Please login to continue",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40),

                          _buildTextField(
                            hint: "Email Address",
                            icon: Icons.alternate_email_rounded,
                            onChanged: (val) => formNotifier.updateEmail(val),
                            errorText: formState.emailError,
                          ),
                          const SizedBox(height: 20),

                          _buildTextField(
                            hint: "Password",
                            icon: Icons.lock_open_rounded,
                            isPassword: true,
                            obscureText: formState.isPasswordHidden,
                            onChanged: (val) => formNotifier.updatePassword(val),
                            errorText: formState.passwordError,
                            togglePassword: () => formNotifier.togglePasswordVisibility(),
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: (formState.isLoading || !formState.isLoginValid) ? null : _loginUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A237E),
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey[300],
                                elevation: 8,
                                shadowColor: const Color(0xFF1A237E).withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: formState.isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              GestureDetector(
                                onTap: () {
                                  ref.read(authFormProvider.notifier).clear();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignUpScreen())
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Color(0xFF1A237E),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Function(String)? onChanged,
    String? errorText,
    VoidCallback? togglePassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: errorText != null ? Colors.redAccent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextField(
            obscureText: obscureText,
            onChanged: onChanged,
            style: const TextStyle(fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, color: const Color(0xFF1A237E)),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.grey[400],
                      ),
                      onPressed: togglePassword,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 8),
            child: Text(
              errorText,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
