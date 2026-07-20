import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String mediaUrl;
  final String? caption;
  final StoryType type;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;
  final int viewCount;

  StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrl,
    this.caption,
    this.type = StoryType.image,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.viewCount = 0,
  });

  factory StoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return StoryModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      mediaUrl: data['mediaUrl'] ?? '',
      caption: data['caption'],
      type: StoryType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => StoryType.image,
      ),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      expiresAt: data['expiresAt']?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      viewers: List<String>.from(data['viewers'] ?? []),
      viewCount: data['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mediaUrl': mediaUrl,
      'caption': caption,
      'type': type.name,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'viewers': viewers,
      'viewCount': viewCount,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isVideo => type == StoryType.video;

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}

enum StoryType { image, video, text }
