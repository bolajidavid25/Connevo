import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connevo/chat/screen/contact_info_screen.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:connevo/auth/services/auth_service.dart';
import '../model/chat_model.dart';
import '../services/chat_service.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String otherUserName;
  final String? otherUserId;
  final String? otherUserPic;
  final bool isGroup;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserName,
    this.otherUserId,
    this.otherUserPic,
    this.isGroup = false,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      ref.read(chatServiceProvider).markMessagesAsSeen(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String value) {
    if (_typingTimer?.isActive ?? false) _typingTimer!.cancel();
    ref.read(chatServiceProvider).setTypingStatus(widget.chatId, true);
    _typingTimer = Timer(const Duration(seconds: 2), () {
      ref.read(chatServiceProvider).setTypingStatus(widget.chatId, false);
    });
  }

  IconData _getFileIcon(String fileName) {
    String ext = fileName.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (ext == 'doc' || ext == 'docx') return Icons.description_rounded;
    if (ext == 'xls' || ext == 'xlsx') return Icons.table_chart_rounded;
    if (ext == 'txt') return Icons.text_snippet_rounded;
    if (ext == 'zip' || ext == 'rar') return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (image != null) {
      setState(() => _isUploading = true);
      final bytes = await image.readAsBytes();
      final mediaUrl = await ref.read(chatServiceProvider).uploadChatMedia(bytes, widget.chatId);
      if (mediaUrl != null) {
        await ref.read(chatServiceProvider).sendMessage(widget.chatId, "", mediaUrl: mediaUrl, type: 'image');
      }
      setState(() => _isUploading = false);
    }
  }

  Future<void> _pickAndSendDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
      if (result != null) {
        setState(() => _isUploading = true);
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final mediaUrl = await ref.read(chatServiceProvider).uploadChatDocument(bytes, file.name, widget.chatId);
          if (mediaUrl != null) {
            await ref.read(chatServiceProvider).sendMessage(widget.chatId, file.name, mediaUrl: mediaUrl, type: 'doc');
          }
        }
        setState(() => _isUploading = false);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      debugPrint("FILE PICKER ERROR: $e");
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    ref.read(chatServiceProvider).setTypingStatus(widget.chatId, false);
    await ref.read(chatServiceProvider).sendMessage(widget.chatId, text);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _onCallPressed({required bool isVideo}) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";
    final currentUserData = ref.read(userProvider).value;
    final currentUserName = currentUserData?.name ?? "User";

    if (widget.otherUserId == null) return;

    DateTime? startTime;

    // Listen for the other user joining to start the timer (Strict 4.x compatibility)
    final subscription = ZegoUIKit().getUserJoinStream().listen((List<ZegoUIKitUser> users) {
      for (var user in users) {
        if (user.id == widget.otherUserId) {
          startTime = DateTime.now();
        }
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ZegoUIKitPrebuiltCall(
          appID: 0, // Removed for security
          appSign: '', // Removed for security
          userID: currentUserId,
          userName: currentUserName,
          callID: widget.chatId,
          config: (isVideo
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall())
            ..avatarBuilder = (context, size, user, extraInfo) {
              return CircleAvatar(
                backgroundImage: widget.otherUserPic != null ? NetworkImage(widget.otherUserPic!) : null,
                child: widget.otherUserPic == null ? Text(widget.otherUserName[0]) : null,
              );
            },
          events: ZegoUIKitPrebuiltCallEvents(
            onCallEnd: (ZegoCallEndEvent event, defaultAction) async {
              subscription.cancel(); // Clean up listener

              // Perform the default hangup action (popping the screen) first
              defaultAction.call();

              int duration = 0;
              if (startTime != null) {
                duration = DateTime.now().difference(startTime!).inSeconds;
              }

              final log = CallLogModel(
                callId: widget.chatId,
                callerId: currentUserId,
                receiverId: widget.otherUserId!,
                callerName: currentUserName,
                receiverName: widget.otherUserName,
                callerPic: currentUserData?.profilePic,
                receiverPic: widget.otherUserPic,
                timestamp: DateTime.now(),
                isVideo: isVideo,
                duration: duration,
              );

              // Log the call in the background without blocking the UI
              ref.read(chatServiceProvider).logCall(log, widget.chatId);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 1,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
          builder: (context, snapshot) {
            String subtitle = "";
            String otherUidFromSnap = widget.otherUserId ?? "";
            
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              if (!widget.isGroup) {
                final participants = List<String>.from(data['participants'] ?? []);
                otherUidFromSnap = participants.firstWhere((id) => id != currentUid, orElse: () => "");
              }
              final typingStatus = Map<String, dynamic>.from(data['typingStatus'] ?? {});
              List<String> typingNames = [];
              typingStatus.forEach((uid, isTyping) { 
                if (isTyping && uid != currentUid) typingNames.add(data['names'][uid] ?? "Someone"); 
              });
              if (typingNames.isNotEmpty) subtitle = widget.isGroup ? "${typingNames.join(", ")} typing..." : "typing...";
            }

            return GestureDetector(
              onTap: () { 
                if (!widget.isGroup && otherUidFromSnap.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ContactInfoScreen(userId: otherUidFromSnap))); 
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.otherUserName, style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 16)),
                  if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          },
        ),
        actions: [
          if (!widget.isGroup) ...[
            IconButton(
              icon: const Icon(Icons.call, color: Color(0xFF1A237E)),
              onPressed: () => _onCallPressed(isVideo: false),
            ),
            IconButton(
              icon: const Icon(Icons.videocam, color: Color(0xFF1A237E)),
              onPressed: () => _onCallPressed(isVideo: true),
            ),
          ],
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
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: ref.read(chatServiceProvider).getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
                    final messages = snapshot.data ?? [];
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: messages.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId == currentUid;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                                      child: Text((message.senderName ?? "U")[0].toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)))
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? const Color(0xFF1A237E) : Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: const Radius.circular(20),
                                          topRight: const Radius.circular(20),
                                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                                          bottomRight: Radius.circular(isMe ? 4 : 20)
                                        ),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, 2))],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe && widget.isGroup && message.senderName != null)
                                            Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text(message.senderName!, style: const TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold, fontSize: 11))),

                                          if (message.type == 'image' && message.mediaUrl != null)
                                            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(message.mediaUrl!, fit: BoxFit.cover)),

                                          if (message.type == 'doc' && message.mediaUrl != null)
                                            InkWell(
                                              onTap: () async {
                                                final url = Uri.parse(message.mediaUrl!);
                                                await launchUrl(url, mode: LaunchMode.externalApplication);
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: isMe ? Colors.white.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(_getFileIcon(message.text), color: isMe ? Colors.white : const Color(0xFF1A237E)),
                                                    const SizedBox(width: 10),
                                                    Flexible(child: Text(message.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, fontSize: 13), overflow: TextOverflow.ellipsis)),
                                                  ],
                                                ),
                                              ),
                                            ),

                                          if (message.type == 'text' && message.text.isNotEmpty)
                                            Text(message.text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),

                                          if (message.type == 'call_log')
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  message.text.contains("Video") ? Icons.videocam_rounded : Icons.call_rounded,
                                                  size: 16,
                                                  color: isMe ? Colors.white70 : const Color(0xFF1A237E),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  message.text,
                                                  style: TextStyle(
                                                    color: isMe ? Colors.white : Colors.black87,
                                                    fontSize: 14,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ],
                                            ),

                                          const SizedBox(height: 4),
                                          Text(DateFormat('HH:mm').format(message.timestamp), style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[400], fontSize: 9)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 8),
                                    CircleAvatar(radius: 16, backgroundColor: const Color(0xFF1A237E), child: const Icon(Icons.person_rounded, size: 18, color: Colors.white))
                                  ],
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFF1A237E)), onPressed: _pickAndSendImage),
                    IconButton(icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF1A237E)), onPressed: _pickAndSendDocument),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(25)),
                        child: TextField(
                          controller: _messageController,
                          onChanged: _onTextChanged,
                          decoration: InputDecoration(
                            hintText: _isUploading ? "Uploading..." : "Type a message...",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            suffixIcon: _isUploading ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(onTap: _sendMessage, child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle), child: const Icon(Icons.send_rounded, color: Colors.white, size: 24))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
