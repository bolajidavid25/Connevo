import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connevo/auth/model/auth_model.dart';
import '../services/chat_service.dart';
import 'chat_room_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<UserModel> _selectedUsers = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleUser(UserModel user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  void _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name and select members")),
      );
      return;
    }

    final chatId = await ref.read(chatServiceProvider).createGroupChat(name, _selectedUsers);
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatRoomScreen(
            chatId: chatId,
            otherUserName: name,
            isGroup: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = ref.read(chatServiceProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("New Group", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _createGroup,
            child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
          )
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
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: "Group Name",
                    prefixIcon: const Icon(Icons.group_add_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<UserModel>>(
                  stream: chatService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final users = snapshot.data!;

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isSelected = _selectedUsers.contains(user);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.profilePic != null ? NetworkImage(user.profilePic!) : null,
                            child: user.profilePic == null ? Text(user.name[0]) : null,
                          ),
                          title: Text(user.name),
                          trailing: Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleUser(user),
                            activeColor: const Color(0xFF1A237E),
                          ),
                          onTap: () => _toggleUser(user),
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
    );
  }
}
