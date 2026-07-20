import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String matchId;
  final String senderId;
  final String message;
  final MessageType type;
  final DateTime time;
  final bool read;
  final String? imageUrl;
  final String? voiceUrl;
  final double? latitude;
  final double? longitude;

  MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.message,
    this.type = MessageType.text,
    required this.time,
    this.read = false,
    this.imageUrl,
    this.voiceUrl,
    this.latitude,
    this.longitude,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel(
      id: doc.id,
      matchId: data['matchId'] ?? '',
      senderId: data['sender'] ?? '',
      message: data['message'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MessageType.text,
      ),
      time: data['time']?.toDate() ?? DateTime.now(),
      read: data['read'] ?? false,
      imageUrl: data['imageUrl'],
      voiceUrl: data['voiceUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'matchId': matchId,
      'sender': senderId,
      'message': message,
      'type': type.name,
      'time': time,
      'read': read,
      'imageUrl': imageUrl,
      'voiceUrl': voiceUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

enum MessageType {
  text,
  image,
  voice,
  video,
  location,
  sticker,
  gif,
}
