import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connevo/chat/screen/chat_room_screen.dart';
import 'package:connevo/main.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  StreamSubscription? _chatSubscription;

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!);
          _navigateToChat(data);
        }
      },
    );

    // HANDLE TERMINATED STATE
    final NotificationAppLaunchDetails? launchDetails = 
        await _localNotifications.getNotificationAppLaunchDetails();
    
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      if (payload != null) {
        final data = jsonDecode(payload);
        Future.delayed(const Duration(seconds: 1), () {
          _navigateToChat(data);
        });
      }
    }

    startFirestoreNotificationListener();
  }

  void _navigateToChat(Map<String, dynamic> data) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ChatRoomScreen(
          chatId: data['chatId'],
          otherUserName: data['otherUserName'],
          otherUserPic: data['otherUserPic'],
          isGroup: data['isGroup'] ?? false,
        ),
      ),
    );
  }

  void startFirestoreNotificationListener() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null) {
            final lastMessage = data['lastMessage'] ?? "";
            final participants = List<String>.from(data['participants'] ?? []);
            final names = Map<String, dynamic>.from(data['names'] ?? {});
            final profilePics = Map<String, dynamic>.from(data['profilePics'] ?? {});
            final isGroup = data['isGroup'] ?? false;
            final groupName = data['groupName'];

            final senderId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => "");
            final String displayName = isGroup ? (groupName ?? "Group") : (names[senderId] ?? "Someone");
            final String? displayPic = isGroup ? data['groupPic'] : profilePics[senderId];

            if (lastMessage.isNotEmpty) {
              final payload = jsonEncode({
                'chatId': change.doc.id,
                'otherUserName': displayName,
                'otherUserPic': displayPic,
                'isGroup': isGroup,
              });
              _showLocalNotification(displayName, lastMessage, payload);
            }
          }
        }
      }
    });
  }

  Future<void> _showLocalNotification(String title, String body, String payload) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      0,
      "New message from $title",
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // RE-ADDED: The missing method that caused the error in auth_service.dart
  Future<void> saveTokenToDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) return;

    try {
      String? token = await _fcm.getToken();
      String? uid = FirebaseAuth.instance.currentUser?.uid;

      if (token != null && uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }

  void dispose() {
    _chatSubscription?.cancel();
  }
}
