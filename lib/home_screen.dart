import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connevo/chat/screen/chat_list_screen.dart';
import 'package:connevo/chat/screen/call_history_screen.dart';
import 'auth/services/auth_service.dart';
import 'chat/services/chat_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Pick image from local device
  Future<void> _pickAndUploadImage(WidgetRef ref, BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compress for faster upload
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      final authMethod = ref.read(authMethodProvider);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updating profile picture..."), behavior: SnackBarBehavior.floating),
      );

      final res = await authMethod.uploadProfileImage(bytes);
      
      if (!context.mounted) return;

      if (res == "Success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Success! Avatar updated."), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $res"), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // Edit name dialog
  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Your Name"),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Full Name",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E)),
            onPressed: () async {
              final res = await ref.read(authMethodProvider).updateName(nameController.text.trim());
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(res == "Success" ? "Name updated successfully!" : res),
                  backgroundColor: res == "Success" ? Colors.green : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userProvider);
    final authMethod = ref.read(authMethodProvider);
    final totalUnread = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        foregroundColor: const Color(0xFF1A237E),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CallHistoryScreen()),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          // Message Icon with Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListScreen()),
                  );
                },
                icon: const Icon(Icons.chat_bubble_rounded),
              ),
              totalUnread.when(
                data: (count) => count > 0 
                  ? Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (e, stack) => const SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            onPressed: () async => await authMethod.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: userData.when(
        data: (user) {
          if (user == null) return const Center(child: CircularProgressIndicator());

          return Stack(
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar Section
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
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
                              key: ValueKey(user.profilePic),
                              backgroundImage: user.profilePic != null && user.profilePic!.isNotEmpty
                                  ? NetworkImage(user.profilePic!)
                                  : null,
                              child: (user.profilePic == null || user.profilePic!.isEmpty)
                                  ? const Icon(Icons.person_rounded, size: 85, color: Color(0xFF1A237E))
                                  : null,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(ref, context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFF1A237E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Name and Email
                    Text(
                      user.name,
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF1A237E)),
                    ),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 40),

                    // Information Tiles
                    _buildInfoTile(Icons.alternate_email_rounded, "Account Email", user.email),
                    _buildInfoTile(Icons.badge_outlined, "Full Name", user.name),

                    const SizedBox(height: 40),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                        onPressed: () => _showEditNameDialog(context, ref, user.name),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A237E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                        ),
                        label: const Text("Edit Profile Name",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
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
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
