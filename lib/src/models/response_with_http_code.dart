/// Safely converts a dynamic value to int.
int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

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
    final raw = map['http_code'] ?? map['httpCode'];
    final resp = map['response'];
    return ResponseWithHttpCode(
      httpCode: _asInt(raw) ?? 0,
      response: resp is Map
          ? Map<String, dynamic>.from(resp)
          : null,
    );
  }
}
