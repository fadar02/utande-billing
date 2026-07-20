import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String reportedBy;
  final String reportedUser;
  final String reason;
  final String? description;
  final DateTime date;
  final String status;

  ReportModel({
    required this.id,
    required this.reportedBy,
    required this.reportedUser,
    required this.reason,
    this.description,
    required this.date,
    this.status = 'pending',
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ReportModel(
      id: doc.id,
      reportedBy: data['reportedBy'] ?? '',
      reportedUser: data['reportedUser'] ?? '',
      reason: data['reason'] ?? '',
      description: data['description'],
      date: data['date']?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reportedBy': reportedBy,
      'reportedUser': reportedUser,
      'reason': reason,
      'description': description,
      'date': date,
      'status': status,
    };
  }

  static const List<String> reportReasons = [
    'Fake profile',
    'Inappropriate content',
    'Harassment',
    'Spam',
    'Underage',
    'Other',
  ];
}
