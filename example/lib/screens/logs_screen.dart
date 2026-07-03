import 'dart:async';

import 'package:flutter/material.dart';
import 'package:altcraft_sdk/altcraft_sdk.dart';
import 'package:altcraft_sdk_example/services/event_bus.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final List<SdkEvent> _events = [];
  final _scrollController = ScrollController();
  StreamSubscription<SdkEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = EventBus.instance.stream.listen((event) {
      setState(() => _events.add(event));
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_events.isEmpty) {
      return const Center(child: Text('No events yet', style: TextStyle(color: Color(0xFF999999), fontSize: 14)));
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: _events.asMap().entries.map((entry) {
          final i = entry.key;
          final ev = entry.value;
          final ts = ev.timestamp ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ts.isEmpty ? '—' : ts,
                          style: const TextStyle(color: Color(0xFF3678E2), fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          ev.message.isEmpty ? 'No message' : ev.message,
                          style: const TextStyle(color: Colors.black, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (i < _events.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, thickness: 0.8, color: Color(0xFFCCCCCC)),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
