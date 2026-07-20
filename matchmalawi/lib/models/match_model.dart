import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime date;
  final bool isNew;

  MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.date,
    this.isNew = true,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MatchModel(
      id: doc.id,
      user1Id: data['user1'] ?? '',
      user2Id: data['user2'] ?? '',
      date: data['date']?.toDate() ?? DateTime.now(),
      isNew: data['isNew'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user1': user1Id,
      'user2': user2Id,
      'date': date,
      'isNew': isNew,
    };
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}
