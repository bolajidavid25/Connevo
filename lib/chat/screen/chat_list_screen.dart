import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:connevo/auth/model/auth_model.dart';
import '../model/chat_model.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';
import 'user_list_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.read(chatServiceProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("Messages",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: Color(0xFF1A237E))),
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded, color: Color(0xFF1A237E)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupScreen()));
            },
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
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: "Search conversations...",
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1A237E)),
                      suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<List<ChatRoomModel>>(
                  stream: chatService.getChatRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState("No conversations yet", Icons.chat_bubble_outline_rounded);
                    }

                    final filteredChats = snapshot.data!.where((chat) {
                      final otherName = chat.isGroup
                        ? (chat.groupName ?? "Group")
                        : (chat.names.entries.firstWhere((e) => e.key != currentUid, orElse: () => MapEntry("", "User")).value);
                      return otherName.toLowerCase().contains(_searchQuery);
                    }).toList();

                    return ListView.builder(
                      itemCount: filteredChats.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      itemBuilder: (context, index) {
                        final chat = filteredChats[index];
                        final unreadCount = chat.unreadCount[currentUid] ?? 0;

                        if (chat.isGroup) {
                          return _buildChatTile(
                            context,
                            chat,
                            chat.groupName ?? "Group",
                            chat.groupPic,
                            null,
                            unreadCount
                          );
                        }

                        final otherUid = chat.participants.firstWhere((id) => id != currentUid, orElse: () => "");

                        return StreamBuilder<UserModel?>(
                          stream: chatService.getUserById(otherUid),
                          builder: (context, userSnap) {
                            final user = userSnap.data;
                            final String displayName = user?.name ?? chat.names[otherUid] ?? "User";
                            final String? displayPic = user?.profilePic ?? chat.profilePics[otherUid];

                            return _buildChatTile(
                              context,
                              chat,
                              displayName,
                              displayPic,
                              otherUid,
                              unreadCount
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const UserListScreen()));
        },
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: const Text("New Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatRoomModel chat, String name, String? pic, String? otherUid, int unreadCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
          backgroundImage: pic != null && pic.isNotEmpty ? NetworkImage(pic) : null,
          child: (pic == null || pic.isEmpty)
            ? Icon(chat.isGroup ? Icons.groups_rounded : Icons.person_rounded, color: const Color(0xFF1A237E))
            : null,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(name, 
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold, fontSize: 17, color: Colors.black87)
              ),
            ),
            Text(DateFormat('HH:mm').format(chat.lastMessageTime), style: TextStyle(color: unreadCount > 0 ? const Color(0xFF1A237E) : Colors.grey[500], fontSize: 12, fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(chat.lastMessage.isEmpty ? "Start a conversation" : chat.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: unreadCount > 0 ? Colors.black : Colors.grey[600], fontSize: 14, fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal)),
              ),
            ),
            if (unreadCount > 0)
              Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle), child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ),
        onTap: () {
          ref.read(chatServiceProvider).resetUnreadCount(chat.chatId);
          Navigator.push(context, MaterialPageRoute(builder: (context) => ChatRoomScreen(
            chatId: chat.chatId, 
            otherUserName: name, 
            otherUserId: otherUid, // FIXED: Now passing the UID correctly
            otherUserPic: pic, 
            isGroup: chat.isGroup
          )));
        },
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 80, color: Colors.grey[200]), const SizedBox(height: 16), Text(message, style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w500))]));
  }
}
