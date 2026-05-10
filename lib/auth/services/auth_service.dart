import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:connevo/auth/model/auth_model.dart';
import 'notification_service.dart';

class AuthMethod {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  
  final String _imgbbApiKey = "61ea607e250048756e170b7db4a946ad";

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
      ? "420624463594-1333eeuahtdq6isp0ucetjhf206njhd1.apps.googleusercontent.com" 
      : null,
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ImgBB Upload logic
  Future<String> uploadProfileImage(Uint8List file) async {
    try {
      String base64Image = base64Encode(file);
      var response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgbbApiKey'),
        body: {'image': base64Image},
      );

      var result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        String downloadUrl = result['data']['url'];
        String uid = _auth.currentUser!.uid;
        await _firestore.collection('users').doc(uid).update({'profilePic': downloadUrl});
        return "Success";
      } else {
        return "Upload failed: ${result['error']['message']}";
      }
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> updateNotificationSetting(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({'notificationsEnabled': enabled});
  }

  Future<void> setUserPresence(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _registerDeviceToken() async {
    await _notificationService.saveTokenToDatabase();
  }

  Future<String> updateName(String name) async {
    try {
      if (name.isEmpty) return "Name cannot be empty";
      String uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({'name': name});
      return "Success";
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> signUpUser({required String email, required String password, required String name}) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection("users").doc(cred.user!.uid).set({
        "name": name, "email": email, "uid": cred.user!.uid,
        "createdAt": DateTime.now().toIso8601String(), "profilePic": null,
        "isOnline": true, "lastSeen": DateTime.now().toIso8601String(), "notificationsEnabled": true,
      });
      await _registerDeviceToken();
      return "Success";
    } on FirebaseAuthException catch (e) { return e.message ?? "Error"; }
    catch (e) { return e.toString(); }
  }

  Future<String> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await setUserPresence(true);
      await _registerDeviceToken();
      return "Success";
    } on FirebaseAuthException catch (e) { return e.message ?? "Error"; }
    catch (e) { return e.toString(); }
  }

  Future<String> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return "Success";
    } catch (e) { return e.toString(); }
  }

  Future<String> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Cancelled";
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        final doc = await _firestore.collection("users").doc(userCredential.user!.uid).get();
        if (!doc.exists) {
          await _firestore.collection("users").doc(userCredential.user!.uid).set({
            "name": userCredential.user!.displayName ?? "User", "email": userCredential.user!.email ?? "",
            "uid": userCredential.user!.uid, "profilePic": userCredential.user!.photoURL,
            "createdAt": DateTime.now().toIso8601String(), "isOnline": true, "notificationsEnabled": true,
          });
        } else { await setUserPresence(true); }
        await _registerDeviceToken();
      }
      return "Success";
    } catch (e) { return e.toString(); }
  }

  Future<void> signOut() async {
    await setUserPresence(false);
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

final authMethodProvider = Provider<AuthMethod>((ref) => AuthMethod());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authMethodProvider).authStateChanges;
});

// FIXED: This provider now explicitly watches authStateProvider.
// When the User object changes (login/logout), this entire stream resets.
final userProvider = StreamProvider<UserModel?>((ref) {
  final user = ref.watch(authStateProvider).value;
  
  if (user == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection("users")
      .doc(user.uid)
      .snapshots()
      .map((snap) => snap.exists ? UserModel.fromMap(snap.data()!) : null);
});
