/// Subscription data for push/email/SMS channels.
class Subscription {
  /// Subscription type.
  final String type;

  /// Resource ID for the subscription.
  final int resourceId;

  /// Subscription status.
  final String? status;

  /// Subscription priority.
  final int? priority;

  /// Email address (for type 'email').
  final String? email;

  /// Phone number (for type 'sms').
  final String? phone;

  /// Push provider (for type 'push').
  final String? provider;

  /// Subscription ID (for type 'push').
  final String? subscriptionId;

  /// Custom fields.
  final Map<String, dynamic>? customFields;

  /// Categories.
  final List<dynamic>? cats;

  /// CC data (for type 'cc_data').
  final Map<String, dynamic>? ccData;

  const Subscription({
    required this.type,
    required this.resourceId,
    this.status,
    this.priority,
    this.email,
    this.phone,
    this.provider,
    this.subscriptionId,
    this.customFields,
    this.cats,
    this.ccData,
  });

  /// Email subscription factory.
  factory Subscription.email({
    required int resourceId,
    required String email,
    String? status,
    int? priority,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
  }) {
    return Subscription(
      type: 'email',
      resourceId: resourceId,
      email: email,
      status: status,
      priority: priority,
      customFields: customFields,
      cats: cats,
    );
  }

  /// SMS subscription factory.
  factory Subscription.sms({
    required int resourceId,
    required String phone,
    String? status,
    int? priority,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
  }) {
    return Subscription(
      type: 'sms',
      resourceId: resourceId,
      phone: phone,
      status: status,
      priority: priority,
      customFields: customFields,
      cats: cats,
    );
  }

  /// Push subscription factory.
  factory Subscription.push({
    required int resourceId,
    required String provider,
    required String subscriptionId,
    String? status,
    int? priority,
    Map<String, dynamic>? customFields,
    List<dynamic>? cats,
  }) {
    return Subscription(
      type: 'push',
      resourceId: resourceId,
      provider: provider,
      subscriptionId: subscriptionId,
      status: status,
      priority: priority,
      customFields: customFields,
      cats: cats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'resource_id': resourceId,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (provider != null) 'provider': provider,
      if (subscriptionId != null) 'subscription_id': subscriptionId,
      if (customFields != null) 'custom_fields': customFields,
      if (cats != null) 'cats': cats,
      if (ccData != null) 'cc_data': ccData,
    };
  }
}
