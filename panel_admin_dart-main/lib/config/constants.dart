class Constants {
  static const String serverIp = 'localhost:3000';
  static const bool isProduction = false;

  static String get baseUrl =>
      isProduction ? 'https://$serverIp/api' : 'http://$serverIp/api';

  static String get socketUrl =>
      isProduction ? 'wss://$serverIp' : 'ws://$serverIp';
}
