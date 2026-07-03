/// Builder for structured profile field actions.
///
/// Produces a map entry compatible with the native SDK's ActionFieldBuilder.
/// The resulting map is intended to be merged into `profileFields` before
/// passing to `pushSubscribe`, `updateProfileFields`, or similar APIs.
class ActionFieldBuilder {
  final String key;

  ActionFieldBuilder(this.key);

  /// Set field to a specific value.
  Map<String, dynamic> set(dynamic value) {
    return {key: {'action': 'set', 'value': value}};
  }

  /// Unset (remove) a field value.
  Map<String, dynamic> unset(dynamic value) {
    return {key: {'action': 'unset', 'value': value}};
  }

  /// Increment a numeric field by the given value.
  Map<String, dynamic> incr(dynamic value) {
    return {key: {'action': 'incr', 'value': value}};
  }

  /// Add a value to a set/array field.
  Map<String, dynamic> add(dynamic value) {
    return {key: {'action': 'add', 'value': value}};
  }

  /// Delete a value from a set/array field.
  Map<String, dynamic> delete(dynamic value) {
    return {key: {'action': 'delete', 'value': value}};
  }

  /// Upsert: set if missing, update if exists.
  Map<String, dynamic> upsert(dynamic value) {
    return {key: {'action': 'upsert', 'value': value}};
  }
}

/// Creates an ActionFieldBuilder for the given field key.
ActionFieldBuilder actionField(String key) {
  return ActionFieldBuilder(key);
}
