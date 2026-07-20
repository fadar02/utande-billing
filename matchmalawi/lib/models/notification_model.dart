import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final String? type;
  final String? referenceId;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.read = false,
    required this.createdAt,
    this.type,
    this.referenceId,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      read: data['read'] ?? false,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      type: data['type'],
      referenceId: data['referenceId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'read': read,
      'createdAt': createdAt,
      'type': type,
      'referenceId': referenceId,
    };
  }
}
