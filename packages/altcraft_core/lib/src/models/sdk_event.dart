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
      function: map['function']?.toString() ?? '',
      code: _safeInt(map['code']),
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? 'event',
      value: map['value'] is Map
          ? Map<String, dynamic>.from(map['value'] as Map)
          : null,
      timestamp: map['timestamp']?.toString(),
    );
  }

  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  factory SdkEvent.fromJson(Map<String, dynamic> json) {
    return SdkEvent(
      function: json['function']?.toString() ?? '',
      code: _safeInt(json['code']),
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'event',
      value: json['value'] is Map
          ? Map<String, dynamic>.from(json['value'] as Map)
          : null,
      timestamp: json['timestamp']?.toString(),
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
