import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connevo/auth/model/auth_model.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatService = ref.read(chatServiceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("New Chat", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF1A237E)),
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
          StreamBuilder<List<UserModel>>(
            stream: chatService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text("No users found", style: TextStyle(color: Colors.grey[500])),
                );
              }

              final users = snapshot.data!;

              return ListView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final user = users[index];

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1A237E),
                      backgroundImage: user.profilePic != null ? NetworkImage(user.profilePic!) : null,
                      child: user.profilePic == null
                        ? Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white))
                        : null,
                    ),
                    title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user.email),
                    onTap: () async {
                      final chatId = await chatService.getOrCreateChatRoom(user);
                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatRoomScreen(
                              chatId: chatId,
                              otherUserName: user.name,
                              otherUserId: user.uid, // FIXED: Now passing the ID
                              otherUserPic: user.profilePic,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
