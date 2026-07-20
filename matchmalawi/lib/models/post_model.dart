import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final List<String> mediaUrls;
  final String caption;
  final List<String> likes;
  final List<CommentModel> comments;
  final DateTime createdAt;
  final String? location;
  final List<String> tags;

  PostModel({
    required this.id,
    required this.userId,
    required this.mediaUrls,
    this.caption = '',
    this.likes = const [],
    this.comments = const [],
    required this.createdAt,
    this.location,
    this.tags = const [],
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      mediaUrls: List<String>.from(data['mediaUrls'] ?? []),
      caption: data['caption'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      comments: (data['comments'] as List<dynamic>? ?? [])
          .map((c) => CommentModel.fromMap(c as Map<String, dynamic>))
          .toList(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      location: data['location'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'mediaUrls': mediaUrls,
      'caption': caption,
      'likes': likes,
      'comments': comments.map((c) => c.toMap()).toList(),
      'createdAt': createdAt,
      'location': location,
      'tags': tags,
    };
  }

  int get likeCount => likes.length;
  int get commentCount => comments.length;
  bool isLikedBy(String userId) => likes.contains(userId);
}

class CommentModel {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final List<String> likes;

  CommentModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    this.likes = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> data) {
    return CommentModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'createdAt': createdAt,
      'likes': likes,
    };
  }
}
