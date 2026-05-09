import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:connevo/auth/model/auth_model.dart';
import '../services/chat_service.dart';

class ContactInfoScreen extends ConsumerWidget {
  final String userId;

  const ContactInfoScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.read(chatServiceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("Contact Info", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
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
          StreamBuilder<UserModel?>(
            stream: chatService.getUserById(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text("User not found"));
              }

              final user = snapshot.data!;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Profile Avatar
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A237E), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          backgroundImage: user.profilePic != null && user.profilePic!.isNotEmpty
                              ? NetworkImage(user.profilePic!)
                              : null,
                          child: (user.profilePic == null || user.profilePic!.isEmpty)
                              ? const Icon(Icons.person_rounded, size: 85, color: Color(0xFF1A237E))
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Online Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: user.isOnline ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: user.isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            user.isOnline ? "Online" : "Offline",
                            style: TextStyle(
                              color: user.isOnline ? Colors.green : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 40),

                    // Information Tiles
                    _buildInfoTile(Icons.alternate_email_rounded, "Email Address", user.email),
                    _buildInfoTile(Icons.access_time_rounded, "Last Seen",
                      user.lastSeen != null ? DateFormat('MMM d, HH:mm').format(user.lastSeen!) : "Never"),
                    _buildInfoTile(Icons.calendar_today_rounded, "Member Since",
                      user.createdAt != null ? DateFormat('MMM d, yyyy').format(user.createdAt!) : "N/A"),

                    const SizedBox(height: 40),
                    // Action: Start Chatting (Optional)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A237E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          label: const Text("Message Now",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1A237E)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
