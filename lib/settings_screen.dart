import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth/services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userProvider);
    final authMethod = ref.read(authMethodProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 0,
        foregroundColor: const Color(0xFF1A237E),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
          userData.when(
            data: (user) {
              if (user == null) return const Center(child: CircularProgressIndicator());

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Notifications",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: SwitchListTile(
                      title: const Text(
                        "Push Notifications",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text("Receive alerts for new messages"),
                      value: user.notificationsEnabled,
                      activeThumbColor: const Color(0xFF1A237E),
                      onChanged: (bool value) {
                        authMethod.updateNotificationSetting(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.redAccent),
                          title: const Text("Logout", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                          onTap: () async {
                            await authMethod.signOut();
                            if (context.mounted) {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
            error: (e, _) => Center(child: Text("Error: $e")),
          ),
        ],
      ),
    );
  }
}
