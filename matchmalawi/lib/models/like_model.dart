import 'package:cloud_firestore/cloud_firestore.dart';

class LikeModel {
  final String id;
  final String senderId;
  final String receiverId;
  final bool isSuperLike;
  final DateTime date;

  LikeModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.isSuperLike = false,
    required this.date,
  });

  factory LikeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return LikeModel(
      id: doc.id,
      senderId: data['sender'] ?? '',
      receiverId: data['receiver'] ?? '',
      isSuperLike: data['isSuperLike'] ?? false,
      date: data['date']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender': senderId,
      'receiver': receiverId,
      'isSuperLike': isSuperLike,
      'date': date,
    };
  }
}
