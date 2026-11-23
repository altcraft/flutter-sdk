import 'dart:async';

import 'package:altcraft_core/altcraft_core.dart';

/// Central event bus — all SDK events flow through here.
/// Both HomeScreen and LogsScreen listen to this single source.
class EventBus {
  EventBus._();
  static final instance = EventBus._();

  final _controller = StreamController<SdkEvent>.broadcast();

  /// Stream of all SDK events for the current session.
  Stream<SdkEvent> get stream => _controller.stream;

  /// Start listening to the native SDK and forward events to all subscribers.
  void init() {
    AltcraftCore.subscribeToEvents().listen(_controller.add);
  }

  /// Add an event directly (for testing or internal use).
  void add(SdkEvent event) => _controller.add(event);

  /// Dispose — stop forwarding and close the stream.
  void dispose() {
    _controller.close();
  }
}
