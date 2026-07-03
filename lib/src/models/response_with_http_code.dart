/// HTTP response with status code from the Altcraft API.
class ResponseWithHttpCode {
  /// HTTP status code.
  final int httpCode;

  /// Response body.
  final Map<String, dynamic>? response;

  const ResponseWithHttpCode({
    required this.httpCode,
    this.response,
  });

  /// Creates from a Map (received via MethodChannel).
  factory ResponseWithHttpCode.fromMap(Map<dynamic, dynamic> map) {
    return ResponseWithHttpCode(
      httpCode: map['httpCode'] as int? ?? 0,
      response: map['response'] != null
          ? Map<String, dynamic>.from(map['response'] as Map)
          : null,
    );
  }
}
