import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get awsAccessKey => dotenv.env['AWS_ACCESS_KEY'] ?? '';
  static String get awsSecretKey => dotenv.env['AWS_SECRET_KEY'] ?? '';
  static String get awsRegion => dotenv.env['AWS_REGION'] ?? '';
  static String get awsBucketName => dotenv.env['AWS_BUCKET_NAME'] ?? '';
}
