/// SDK event emitted from the native SDK.
class SdkEvent {
  /// Function name that triggered the event.
  final String function;

  /// HTTP status code (if applicable).
  final int? code;

  /// Human-readable message.
  final String message;

  /// Event type.
  final String type;

  /// Optional event value payload.
  final Map<String, dynamic>? value;

  /// Timestamp string from the native SDK (yyyy-MM-dd HH:mm:ss.SSS).
  final String? timestamp;

  const SdkEvent({
    required this.function,
    this.code,
    required this.message,
    required this.type,
    this.value,
    this.timestamp,
  });

  /// Creates an SdkEvent from a Map (received via EventChannel).
  factory SdkEvent.fromMap(Map<dynamic, dynamic> map) {
    return SdkEvent(
      function: map['function'] as String? ?? '',
      code: map['code'] as int?,
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'event',
      value: map['value'] != null ? Map<String, dynamic>.from(map['value'] as Map) : null,
      timestamp: map['timestamp'] as String?,
    );
  }

  factory SdkEvent.fromJson(Map<String, dynamic> json) {
    return SdkEvent(
      function: json['function'] as String? ?? '',
      code: json['code'] as int?,
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'event',
      value: json['value'] != null ? Map<String, dynamic>.from(json['value'] as Map) : null,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'function': function,
      'code': code,
      'message': message,
      'type': type,
      'value': value,
      'timestamp': timestamp,
    };
  }
}
