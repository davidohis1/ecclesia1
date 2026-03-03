class AppConstants {
  // Bunny.net Config
  static const String bunnyStorageZone = 'ecclesia-media';
  static const String bunnyBaseUrl = 'https://ecclesia-media.b-cdn.net';
  static const String bunnyApiKey = '3fdca9fc-9fcd-4957-96a7fef795b8-ad32-47aa'; // Replace with actual key
  static const String bunnyStorageApiUrl = 'https://storage.bunnycdn.com';
  
  // Folders
  static const String folderProfiles = 'profiles';
  static const String folderPosts = 'posts';
  static const String folderReels = 'reels';
  static const String folderLibrary = 'library';
  static const String folderAudio = 'audio';
  static const String folderMessages = 'messages';
  
  // Limits
  static const int maxReelSizeMb = 50;
  static const int maxPostImagesCount = 10;
  static const int discussionExpiryHours = 24;
  
  // Firestore Collections
  static const String colUsers = 'users';
  static const String colPosts = 'posts';
  static const String colReels = 'reels';
  static const String colLibrary = 'library';
  static const String colDiscussions = 'discussions';
  static const String colMessages = 'messages';
  static const String colAudio = 'audio';
  static const String colComments = 'comments';
  static const String colLikes = 'likes';
  static const String colFollows = 'follows';
  static const String colNotifications = 'notifications';
}

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String profileSetup = '/profile-setup';
  static const String home = '/home';
  static const String feed = '/feed';
  static const String reels = '/reels';
  static const String library = '/library';
  static const String discussions = '/discussions';
  static const String discussionRoom = '/discussion-room';
  static const String messages = '/messages';
  static const String chat = '/chat';
  static const String music = '/music';
  static const String profile = '/profile';
  static const String saints = '/saints';
  static const String createPost = '/create-post';
  static const String search = '/search';
}
