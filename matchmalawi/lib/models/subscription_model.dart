import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final DateTime expiry;
  final DateTime startDate;
  final bool active;
  final String? paymentMethod;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.expiry,
    required this.startDate,
    this.active = true,
    this.paymentMethod,
  });

  factory SubscriptionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubscriptionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      plan: data['plan'] ?? '',
      expiry: data['expiry']?.toDate() ?? DateTime.now(),
      startDate: data['startDate']?.toDate() ?? DateTime.now(),
      active: data['active'] ?? true,
      paymentMethod: data['paymentMethod'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'plan': plan,
      'expiry': expiry,
      'startDate': startDate,
      'active': active,
      'paymentMethod': paymentMethod,
    };
  }

  bool get isExpired => expiry.isBefore(DateTime.now());

  static const Map<String, Map<String, dynamic>> plans = {
    'gold': {
      'name': 'Gold',
      'price': 15000,
      'currency': 'MWK',
      'duration': 30,
      'features': [
        'Unlimited Likes',
        'See who liked you',
        'Read receipts',
        'Unlimited messaging',
      ],
    },
    'platinum': {
      'name': 'Platinum',
      'price': 25000,
      'currency': 'MWK',
      'duration': 30,
      'features': [
        'Everything in Gold',
        'Rewind swipes',
        'Boost profile',
        'Passport mode',
        'Priority support',
      ],
    },
    'diamond': {
      'name': 'Diamond',
      'price': 40000,
      'currency': 'MWK',
      'duration': 30,
      'features': [
        'Everything in Platinum',
        '5 Super Likes per day',
        'Profile spotlight',
        'Advanced filters',
        'Video calls',
        'Verified badge',
      ],
    },
  };
}
