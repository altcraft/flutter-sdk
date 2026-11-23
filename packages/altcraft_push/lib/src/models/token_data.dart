/// Push token data returned from the SDK.
class TokenData {
  /// Push provider identifier (e.g. 'android-firebase', 'ios-apns').
  final String provider;

  /// Push token value.
  final String token;

  const TokenData({
    required this.provider,
    required this.token,
  });

  /// Creates TokenData from a Map (received via MethodChannel).
  factory TokenData.fromMap(Map<dynamic, dynamic> map) {
    return TokenData(
      provider: map['provider'] as String? ?? '',
      token: map['token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'token': token,
    };
  }
}
