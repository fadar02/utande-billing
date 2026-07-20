class AppConstants {
  static const String appName = 'Match Malawi';
  static const String appTagline = 'Find love in the Warm Heart of Africa';
  static const String chichewaProverb = 'Chimwemwe chili mu maso';
  static const String chichewaProverbMeaning = 'Happiness is in the eyes';

  static const String airtelMoneyUSSD = '*777#';
  static const String tnmMpambaUSSD = '*444#';

  static const int maxPhotos = 6;
  static const int maxPostPhotos = 10;
  static const int maxBioLength = 500;
  static const int maxCaptionLength = 2000;
  static const int maxStoryTextLength = 200;
  static const int minInterests = 3;
  static const int maxInterests = 10;

  static const int freeLikesPerDay = 10;
  static const int freeSuperLikesPerDay = 1;
  static const int storyDurationHours = 24;

  static const Map<String, String> malawiProverbs = {
    'Chimwemwe chili mu maso': 'Happiness is in the eyes',
    'Kukonda si kugona': 'Love is not sleeping',
    'Mtima siwaonana': 'Hearts do not meet by chance',
    'Chikondi ndi nyengo': 'Love takes time',
    'Wokonda sangakane': 'A lover cannot deny',
    'Umoyo ndi maso': 'Life is in the eyes',
    'Chonde ndi chonde': 'Please and please',
    'Mtima wabwino ndi mtenda': 'A good heart is a treasure',
    'Kumvera ndi kupanga': 'Listening is doing',
    'Tisaiwale komwe tachokera': 'Let us not forget where we come from',
  };

  static const Map<String, List<String>> safeMeetingSpots = {
    'Blantyre': [
      'Mandala House',
      'Kamuzu Stadium Area',
      'Chileka Airport Road Cafes',
      'Game City Mall',
      'Blantyre Sports Club',
    ],
    'Lilongwe': [
      'Crossroads Mall',
      'Gateway Mall',
      'Lilongwe Wildlife Centre',
      'Bwandilo Market Area',
      'Area 47 Restaurants',
    ],
    'Mzuzu': [
      'Mzuzu Cathedral Area',
      'Chilambula Road Cafes',
      'Mzuzu Shopping Centre',
    ],
    'Zomba': [
      'Zomba Plateau',
      'Queen\'s University Area',
      'Zomba Market',
    ],
  };
}
