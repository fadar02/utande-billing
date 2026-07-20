import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String district;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String occupation;
  final String education;
  final String? religion;
  final String? tribe;
  final String? height;
  final List<String> interests;
  final String bio;
  final List<String> photos;
  final String? videoUrl;
  final bool verified;
  final bool premium;
  final String? premiumPlan;
  final DateTime? premiumExpiry;
  final String? phoneNumber;
  final String? email;
  final String? photoUrl;
  final String lookingFor;
  final String? ageRangeMin;
  final String? ageRangeMax;
  final String? distancePreference;
  final String? relationshipType;
  final bool online;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool blocked;
  final bool banned;
  final int superLikesRemaining;
  final int likesRemaining;
  final DateTime? lastLikeReset;

  UserModel({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.district,
    this.city,
    this.latitude,
    this.longitude,
    required this.occupation,
    required this.education,
    this.religion,
    this.tribe,
    this.height,
    this.interests = const [],
    this.bio = '',
    this.photos = const [],
    this.videoUrl,
    this.verified = false,
    this.premium = false,
    this.premiumPlan,
    this.premiumExpiry,
    this.phoneNumber,
    this.email,
    this.photoUrl,
    this.lookingFor = 'Female',
    this.ageRangeMin = '18',
    this.ageRangeMax = '25',
    this.distancePreference = '20',
    this.relationshipType = 'Serious relationship',
    this.online = false,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
    this.blocked = false,
    this.banned = false,
    this.superLikesRemaining = 1,
    this.likesRemaining = 10,
    this.lastLikeReset,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      gender: data['gender'] ?? '',
      district: data['district'] ?? '',
      city: data['city'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      occupation: data['occupation'] ?? '',
      education: data['education'] ?? '',
      religion: data['religion'],
      tribe: data['tribe'],
      height: data['height'],
      interests: List<String>.from(data['interests'] ?? []),
      bio: data['bio'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      videoUrl: data['videoUrl'],
      verified: data['verified'] ?? false,
      premium: data['premium'] ?? false,
      premiumPlan: data['premiumPlan'],
      premiumExpiry: data['premiumExpiry']?.toDate(),
      phoneNumber: data['phoneNumber'],
      email: data['email'],
      photoUrl: data['photoUrl'],
      lookingFor: data['lookingFor'] ?? 'Female',
      ageRangeMin: data['ageRangeMin'],
      ageRangeMax: data['ageRangeMax'],
      distancePreference: data['distancePreference'],
      relationshipType: data['relationshipType'],
      online: data['online'] ?? false,
      lastSeen: data['lastSeen']?.toDate(),
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
      blocked: data['blocked'] ?? false,
      banned: data['banned'] ?? false,
      superLikesRemaining: data['superLikesRemaining'] ?? 1,
      likesRemaining: data['likesRemaining'] ?? 10,
      lastLikeReset: data['lastLikeReset']?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'district': district,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'occupation': occupation,
      'education': education,
      'religion': religion,
      'tribe': tribe,
      'height': height,
      'interests': interests,
      'bio': bio,
      'photos': photos,
      'videoUrl': videoUrl,
      'verified': verified,
      'premium': premium,
      'premiumPlan': premiumPlan,
      'premiumExpiry': premiumExpiry,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoUrl': photoUrl,
      'lookingFor': lookingFor,
      'ageRangeMin': ageRangeMin,
      'ageRangeMax': ageRangeMax,
      'distancePreference': distancePreference,
      'relationshipType': relationshipType,
      'online': online,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'blocked': blocked,
      'banned': banned,
      'superLikesRemaining': superLikesRemaining,
      'likesRemaining': likesRemaining,
      'lastLikeReset': lastLikeReset,
    };
  }

  UserModel copyWith({
    String? name,
    int? age,
    String? gender,
    String? district,
    String? city,
    double? latitude,
    double? longitude,
    String? occupation,
    String? education,
    String? religion,
    String? tribe,
    String? height,
    List<String>? interests,
    String? bio,
    List<String>? photos,
    String? videoUrl,
    bool? verified,
    bool? premium,
    String? premiumPlan,
    DateTime? premiumExpiry,
    String? lookingFor,
    String? ageRangeMin,
    String? ageRangeMax,
    String? distancePreference,
    String? relationshipType,
    bool? online,
    DateTime? lastSeen,
    bool? blocked,
    bool? banned,
    int? superLikesRemaining,
    int? likesRemaining,
    DateTime? lastLikeReset,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      district: district ?? this.district,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      religion: religion ?? this.religion,
      tribe: tribe ?? this.tribe,
      height: height ?? this.height,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      videoUrl: videoUrl ?? this.videoUrl,
      verified: verified ?? this.verified,
      premium: premium ?? this.premium,
      premiumPlan: premiumPlan ?? this.premiumPlan,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      lookingFor: lookingFor ?? this.lookingFor,
      ageRangeMin: ageRangeMin ?? this.ageRangeMin,
      ageRangeMax: ageRangeMax ?? this.ageRangeMax,
      distancePreference: distancePreference ?? this.distancePreference,
      relationshipType: relationshipType ?? this.relationshipType,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      blocked: blocked ?? this.blocked,
      banned: banned ?? this.banned,
      superLikesRemaining: superLikesRemaining ?? this.superLikesRemaining,
      likesRemaining: likesRemaining ?? this.likesRemaining,
      lastLikeReset: lastLikeReset ?? this.lastLikeReset,
    );
  }

  String get mainPhoto => photos.isNotEmpty ? photos.first : (photoUrl ?? '');

  bool get isPremiumActive =>
      premium &&
      premiumExpiry != null &&
      premiumExpiry!.isAfter(DateTime.now());

  static const List<String> districts = [
    'Balaka',
    'Blantyre',
    'Chikwawa',
    'Chitipa',
    'Dedza',
    'Dowa',
    'Karonga',
    'Kasungu',
    'Likoma',
    'Lilongwe',
    'Machinga',
    'Mangochi',
    'Mchinji',
    'Mulanje',
    'Mwanza',
    'Mzimba',
    'Neno',
    'Nkhata Bay',
    'Ntcheu',
    'Ntchisi',
    'Phalombe',
    'Rumphi',
    'Salima',
    'Thyolo',
    'Zomba',
  ];

  static const List<String> interestsList = [
    'Reading', 'Traveling', 'Music', 'Sports', 'Cooking',
    'Dancing', 'Photography', 'Gaming', 'Hiking', 'Swimming',
    'Art', 'Movies', 'Fitness', 'Yoga', 'Fashion',
    'Technology', 'Volunteering', 'Gardening', 'Food', 'Nature',
    'Church', 'Masambazo', 'Bundu', 'Chitenje', 'Malawian Culture',
  ];

  static const List<String> occupationsList = [
    'Student', 'Teacher', 'Nurse', 'Doctor', 'Engineer',
    'Lawyer', 'Business Owner', 'Farmer', 'Accountant', 'Developer',
    'Designer', 'Marketing', 'Sales', 'Government', 'NGO',
    'Banking', 'Construction', 'Transport', 'Hospitality', 'Other',
  ];

  static const List<String> educationList = [
    'Primary School', 'Secondary School', 'Certificate',
    'Diploma', 'Bachelor\'s Degree', 'Master\'s Degree',
    'PhD', 'Other',
  ];

  static const List<String> religionsList = [
    'Christianity', 'Islam', 'Traditional', 'Other', 'Prefer not to say',
  ];

  static const List<String> tribesList = [
    'Chewa', 'Tumbuka', 'Yao', 'Lomwe', 'Sena',
    'Ngoni', 'Tonga', 'Ngonde', 'Other', 'Prefer not to say',
  ];

  static const List<String> heightsList = [
    '150 cm', '155 cm', '160 cm', '165 cm', '170 cm',
    '175 cm', '180 cm', '185 cm', '190 cm', '195 cm',
  ];

  static const List<String> relationshipTypes = [
    'Serious relationship', 'Marriage', 'Friendship', 'Chat', 'Networking',
  ];
}
