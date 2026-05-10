import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../model/chat_model.dart';
import '../services/chat_service.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        title: const Text("Call History",
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.2),
        elevation: 0,
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
          StreamBuilder<List<CallLogModel>>(
            stream: ref.read(chatServiceProvider).getCallLogs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.call_end_rounded, size: 80, color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      Text("No call history yet", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                    ],
                  ),
                );
              }

              final logs = snapshot.data!;

              return ListView.builder(
                itemCount: logs.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final isCaller = log.callerId == currentUid;
                  final otherName = isCaller ? log.receiverName : log.callerName;
                  final otherPic = isCaller ? log.receiverPic : log.callerPic;

                  String durationText = log.duration > 0
                      ? "${(log.duration / 60).floor()}:${(log.duration % 60).toString().padLeft(2, '0')}"
                      : "No answer";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                        backgroundImage: otherPic != null ? NetworkImage(otherPic) : null,
                        child: otherPic == null ? Text(otherName[0].toUpperCase()) : null,
                      ),
                      title: Text(otherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Row(
                        children: [
                          Icon(
                            isCaller ? Icons.call_made_rounded : Icons.call_received_rounded,
                            size: 14,
                            color: log.duration > 0 ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${log.isVideo ? 'Video' : 'Voice'} • $durationText",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            DateFormat('MMM d').format(log.timestamp),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                          Text(
                            DateFormat('HH:mm').format(log.timestamp),
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
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
