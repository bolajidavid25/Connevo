import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:connevo/auth/model/auth_model.dart';
import '../model/chat_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final String _imgbbApiKey = ""; // Removed for security

  // CLOUDINARY CONFIG
  final String _cloudinaryCloudName = ""; // Removed for security
  final String _cloudinaryUploadPreset = ""; // Removed for security

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').limit(50).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).where((user) => user.uid != _auth.currentUser!.uid).toList();
    });
  }

  Stream<UserModel?> getUserById(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
  }

  Future<String> getOrCreateChatRoom(UserModel otherUser) async {
    final String currentUid = _auth.currentUser!.uid;
    final String otherUid = otherUser.uid;
    List<String> ids = [currentUid, otherUid];
    ids.sort();
    String chatId = ids.join("_");
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
      await _firestore.collection('chats').doc(chatId).set({
        'participants': ids, 'lastMessage': '', 'lastMessageTime': FieldValue.serverTimestamp(),
        'names': {currentUid: currentUserDoc.data()?['name'] ?? "User", otherUid: otherUser.name},
        'profilePics': {currentUid: currentUserDoc.data()?['profilePic'], otherUid: otherUser.profilePic},
        'unreadCount': {currentUid: 0, otherUid: 0},
        'typingStatus': {currentUid: false, otherUid: false},
        'mutedBy': {currentUid: false, otherUid: false}, 'isGroup': false,
      });
    }
    return chatId;
  }

  Future<String> createGroupChat(String groupName, List<UserModel> selectedUsers) async {
    final String currentUid = _auth.currentUser!.uid;
    final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
    final currentUserName = currentUserDoc.data()?['name'] ?? "User";
    final currentUserPic = currentUserDoc.data()?['profilePic'];

    List<String> participants = [currentUid, ...selectedUsers.map((u) => u.uid)];
    Map<String, String> names = {currentUid: currentUserName};
    Map<String, dynamic> profilePics = {currentUid: currentUserPic};
    Map<String, int> unreadCount = {currentUid: 0};
    Map<String, bool> typingStatus = {currentUid: false};
    Map<String, bool> mutedBy = {currentUid: false};

    for (var user in selectedUsers) {
      names[user.uid] = user.name;
      profilePics[user.uid] = user.profilePic;
      unreadCount[user.uid] = 0;
      typingStatus[user.uid] = false;
      mutedBy[user.uid] = false;
    }

    DocumentReference docRef = await _firestore.collection('chats').add({
      'participants': participants,
      'lastMessage': 'Group created',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'names': names,
      'profilePics': profilePics,
      'unreadCount': unreadCount,
      'typingStatus': typingStatus,
      'mutedBy': mutedBy,
      'isGroup': true,
      'groupName': groupName,
      'groupPic': null,
    });

    return docRef.id;
  }

  // ADDED BACK: toggleChatMute
  Future<void> toggleChatMute(String chatId, bool isMuted) async {
    final String? currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;
    await _firestore.collection('chats').doc(chatId).update({
      'mutedBy.$currentUid': isMuted,
    });
  }

  Future<void> markMessagesAsSeen(String chatId) async {
    final String currentUid = _auth.currentUser!.uid;
    final messagesSnapshot = await _firestore.collection('chats').doc(chatId).collection('messages').get();
    WriteBatch batch = _firestore.batch();
    bool hasUnread = false;
    for (var doc in messagesSnapshot.docs) {
      if (doc.data()['senderId'] != currentUid) {
        List seenBy = List.from(doc.data()['seenBy'] ?? []);
        if (!seenBy.contains(currentUid)) {
          seenBy.add(currentUid);
          batch.update(doc.reference, {'seenBy': seenBy});
          hasUnread = true;
        }
      }
    }
    if (hasUnread) {
      batch.update(_firestore.collection('chats').doc(chatId), {'unreadCount.$currentUid': 0});
      await batch.commit();
    }
  }

  Stream<List<MessageModel>> getMessages(String chatId, {int limit = 40}) {
    return _firestore.collection('chats').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true).limit(limit).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> sendMessage(String chatId, String text, {String? mediaUrl, String type = 'text'}) async {
    final String currentUid = _auth.currentUser!.uid;
    final currentUserDoc = await _firestore.collection('users').doc(currentUid).get();
    final message = MessageModel(
      messageId: '', senderId: currentUid, text: text.trim(), mediaUrl: mediaUrl,
      timestamp: DateTime.now(), type: type, senderName: currentUserDoc.data()?['name'] ?? "User", seenBy: [currentUid],
    );
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();
    final participants = List<String>.from(chatDoc.data()?['participants'] ?? []);
    WriteBatch batch = _firestore.batch();
    DocumentReference messageRef = _firestore.collection('chats').doc(chatId).collection('messages').doc();
    batch.set(messageRef, message.toMap());
    
    String lastText = text.trim();
    if (type == 'image') lastText = '📷 Photo';
    if (type == 'doc') lastText = '📄 Document';

    Map<String, dynamic> updates = {'lastMessage': lastText, 'lastMessageTime': FieldValue.serverTimestamp()};
    for (var pId in participants) { if (pId != currentUid) updates['unreadCount.$pId'] = FieldValue.increment(1); }
    batch.update(_firestore.collection('chats').doc(chatId), updates);
    await batch.commit();
  }

  Future<String?> uploadChatMedia(Uint8List file, String chatId) async {
    try {
      String base64Image = base64Encode(file);
      var response = await http.post(Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'), body: {'image': base64Image});
      if (response.statusCode == 200) return jsonDecode(response.body)['data']['url'];
      return null;
    } catch (e) { return null; }
  }

  Future<String?> uploadChatDocument(Uint8List file, String fileName, String chatId) async {
    try {
      final url = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/raw/upload");
      var request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _cloudinaryUploadPreset;
      request.files.add(http.MultipartFile.fromBytes('file', file, filename: fileName));
      var res = await request.send().timeout(const Duration(seconds: 60));
      var resData = await http.Response.fromStream(res);
      if (res.statusCode == 200 || res.statusCode == 201) return json.decode(resData.body)['secure_url'];
      return null;
    } catch (e) { return null; }
  }

  Future<void> setTypingStatus(String chatId, bool isTyping) async {
    final String currentUid = _auth.currentUser!.uid;
    await _firestore.collection('chats').doc(chatId).update({'typingStatus.$currentUid': isTyping});
  }

  Future<void> resetUnreadCount(String chatId) async {
    final String? currentUid = _auth.currentUser?.uid;
    if (currentUid != null) await _firestore.collection('chats').doc(chatId).update({'unreadCount.$currentUid': 0});
  }

  Stream<int> getTotalUnreadCount() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return _firestore.collection('chats').where('participants', arrayContains: uid).snapshots()
        .map((snapshot) => snapshot.docs.fold<int>(0, (total, doc) => total + (doc.data()['unreadCount']?[uid] as num? ?? 0).toInt()));
  }

  Stream<List<ChatRoomModel>> getChatRooms() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestore.collection('chats').where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true).limit(20).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> logCall(CallLogModel log, String chatId) async {
    await _firestore.collection('call_logs').add(log.toMap());

    String message = log.isVideo ? "📹 Video Call" : "📞 Voice Call";
    String durationText = log.duration > 0
        ? " (${(log.duration / 60).floor()}:${(log.duration % 60).toString().padLeft(2, '0')})"
        : " (No answer)";

    await sendMessage(chatId, "$message$durationText", type: 'call_log');
  }

  Stream<List<CallLogModel>> getCallLogs() {
    String? uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);
    return _firestore.collection('call_logs')
        .where(Filter.or(Filter('callerId', isEqualTo: uid), Filter('receiverId', isEqualTo: uid)))
        .orderBy('timestamp', descending: true).limit(50).snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CallLogModel.fromMap(doc.data(), doc.id)).toList());
  }
}

final chatServiceProvider = Provider((ref) => ChatService());
final totalUnreadCountProvider = StreamProvider<int>((ref) => ref.watch(chatServiceProvider).getTotalUnreadCount());
