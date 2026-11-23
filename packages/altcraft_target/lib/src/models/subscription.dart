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
  final List<String>? cats;

  /// CC data (for type 'cc_data').
  final Map<String, dynamic>? ccData;

  /// CC channel name (for type 'cc_data', e.g. 'telegram_bot').
  final String? ccChannel;

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
    this.ccChannel,
  });

  /// Email subscription factory.
  factory Subscription.email({
    required int resourceId,
    required String email,
    String? status,
    int? priority,
    Map<String, dynamic>? customFields,
    List<String>? cats,
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
    List<String>? cats,
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
    List<String>? cats,
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

  /// Custom channel data subscription factory.
  factory Subscription.ccData({
    required int resourceId,
    required String channel,
    required Map<String, dynamic> ccData,
    String? status,
    int? priority,
    Map<String, dynamic>? customFields,
    List<String>? cats,
  }) {
    return Subscription(
      type: 'cc_data',
      resourceId: resourceId,
      ccData: ccData,
      ccChannel: channel,
      status: status,
      priority: priority,
      customFields: customFields,
      cats: cats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'channel': type,
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
      if (ccChannel != null) 'cc_channel': ccChannel,
    };
  }
}
