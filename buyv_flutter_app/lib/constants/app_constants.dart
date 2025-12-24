import 'package:buyv_flutter_app/core/config/environment_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'BuyV';
  static const String appVersion = '1.0.0';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String productsCollection = 'products';
  static const String reelsCollection = 'reels';
  static const String ordersCollection = 'orders';
  static const String categoriesCollection = 'categories';
  static const String notificationsCollection = 'notifications';
  static const String commentsCollection = 'comments';
  static const String likesCollection = 'likes';
  static const String followsCollection = 'follows';

  // Cloudinary Configuration (Unsigned Upload)
  static String cloudinaryCloudName =
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? 'dwtbxzkst';
  static String cloudinaryUploadPreset =
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'Ecommerce_BuyV';
  // Note: API keys not needed for unsigned uploads

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String userTokenKey = 'user_token';
  static const String isLoggedInKey = 'is_logged_in';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';

  // API Endpoints
  static const String baseUrl = 'https://api.buyv.com';
  static String get fastApiBaseUrl => EnvironmentConfig.fastApiBaseUrl;

  // CJ Dropshipping API Configuration
  static String get cjBaseUrl => EnvironmentConfig.cjBaseUrl;
  // Note: These are test credentials - replace with your actual CJ API credentials
  // To get your API key: Login to CJ -> Settings -> API -> Generate API Key
  static String cjApiKey = dotenv.env['CJ_API_KEY'] ?? '';
  // If you prefer using CJ account ID instead of email
  static String cjAccount = dotenv.env['CJ_ACCOUNT_ID'] ?? '';
  static String cjEmail = dotenv.env['CJ_EMAIL'] ?? '';

  // Pagination
  static const int pageSize = 20;
  static const int reelsPageSize = 10;

  // Video Settings
  static const int maxVideoLength = 60; // seconds
  static const int maxVideoSize = 50; // MB

  // Image Settings
  static const int maxImageSize = 10; // MB
  static const List<String> allowedImageFormats = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  // Social Features
  static const int maxCommentLength = 500;
  static const int maxBioLength = 150;
  static const int maxUsernameLength = 30;

  // E-commerce
  static const double minOrderAmount = 10.0;
  static const double maxOrderAmount = 10000.0;
  static const int maxCartItems = 50;

  // Notification Types
  static const String orderNotification = 'order';
  static const String socialNotification = 'social';
  static const String promotionNotification = 'promotion';
  static const String securityNotification = 'security';
  static const String appUpdateNotification = 'app_update';
  static const String generalNotification = 'general';
}
