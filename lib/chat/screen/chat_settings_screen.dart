import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatSettingsScreen extends ConsumerWidget {
  final String chatId;
  final String chatName;
  final bool isGroup;

  const ChatSettingsScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.isGroup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("Chat Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
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
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('chats').doc(chatId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: CircularProgressIndicator());
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final mutedBy = Map<String, dynamic>.from(data['mutedBy'] ?? {});
              final isMuted = mutedBy[currentUid] ?? false;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF1A237E),
                          child: Icon(
                            isGroup ? Icons.groups_rounded : Icons.person_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          chatName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "Notifications",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: SwitchListTile(
                      title: const Text("Mute Notifications", style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text("Silence alerts for this specific chat"),
                      value: isMuted,
                      activeColor: const Color(0xFF1A237E),
                      onChanged: (bool value) {
                        ref.read(chatServiceProvider).toggleChatMute(chatId, value);
                      },
                    ),
                  ),
                  if (isGroup) ...[
                    const SizedBox(height: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        "Group Info",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const Icon(Icons.people_outline_rounded, color: Color(0xFF1A237E)),
                        title: const Text("Participants", style: TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(
                          "${List.from(data['participants'] ?? []).length} members",
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
