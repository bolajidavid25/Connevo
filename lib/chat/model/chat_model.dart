import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, dynamic> names;
  final Map<String, dynamic> profilePics;
  final Map<String, dynamic> unreadCount;
  final bool isGroup;
  final String? groupName;
  final String? groupPic;
  final Map<String, dynamic> typingStatus;
  final Map<String, dynamic> mutedBy;

  ChatRoomModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.names,
    required this.profilePics,
    required this.unreadCount,
    this.isGroup = false,
    this.groupName,
    this.groupPic,
    this.typingStatus = const {},
    this.mutedBy = const {},
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatRoomModel(
      chatId: id,
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] != null 
          ? (map['lastMessageTime'] as Timestamp).toDate() 
          : DateTime.now(),
      names: map['names'] ?? {},
      profilePics: map['profilePics'] ?? {},
      unreadCount: map['unreadCount'] ?? {},
      isGroup: map['isGroup'] ?? false,
      groupName: map['groupName'],
      groupPic: map['groupPic'],
      typingStatus: map['typingStatus'] ?? {},
      mutedBy: map['mutedBy'] ?? {},
    );
  }
}

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final String? mediaUrl;
  final DateTime timestamp;
  final String type;
  final String? senderName;
  final List<String> seenBy;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.mediaUrl,
    required this.timestamp,
    required this.type,
    this.senderName,
    this.seenBy = const [],
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      messageId: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      mediaUrl: map['mediaUrl'], // Ensure this matches exactly with Firestore field key
      timestamp: map['timestamp'] != null 
          ? (map['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      type: map['type'] ?? 'text',
      senderName: map['senderName'],
      seenBy: List<String>.from(map['seenBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'mediaUrl': mediaUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'senderName': senderName,
      'seenBy': seenBy,
    };
  }
}

class CallLogModel {
  final String callId;
  final String callerId;
  final String receiverId;
  final String callerName;
  final String receiverName;
  final String? callerPic;
  final String? receiverPic;
  final DateTime timestamp;
  final bool isVideo;
  final int duration; // in seconds

  CallLogModel({
    required this.callId,
    required this.callerId,
    required this.receiverId,
    required this.callerName,
    required this.receiverName,
    this.callerPic,
    this.receiverPic,
    required this.timestamp,
    required this.isVideo,
    required this.duration,
  });

  factory CallLogModel.fromMap(Map<String, dynamic> map, String id) {
    return CallLogModel(
      callId: id,
      callerId: map['callerId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      callerName: map['callerName'] ?? '',
      receiverName: map['receiverName'] ?? '',
      callerPic: map['callerPic'],
      receiverPic: map['receiverPic'],
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isVideo: map['isVideo'] ?? false,
      duration: map['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'callerId': callerId,
      'receiverId': receiverId,
      'callerName': callerName,
      'receiverName': receiverName,
      'callerPic': callerPic,
      'receiverPic': receiverPic,
      'timestamp': FieldValue.serverTimestamp(),
      'isVideo': isVideo,
      'duration': duration,
    };
  }
}
