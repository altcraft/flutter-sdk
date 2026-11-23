import 'dart:async';

import 'package:flutter/material.dart';
import 'package:altcraft_sdk_example/services/app_state.dart';

const _kLogBlue = Color(0xFF3678E2);

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onChanged);
    _scrollToBottom();
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
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
    final events = AppState.instance.events;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text('No events yet', style: TextStyle(color: Color(0xFF999999), fontSize: 14)),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: events.length,
                      separatorBuilder: (_, __) => const Divider(height: 8, thickness: 0.8, color: Color(0xFFCCCCCC)),
                      itemBuilder: (context, i) {
                        final ev = events[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev.timestamp?.isEmpty ?? true ? '—' : ev.timestamp!,
                                style: const TextStyle(color: _kLogBlue, fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                ev.message.isEmpty ? 'No message' : ev.message,
                                style: const TextStyle(color: Colors.black, fontSize: 10),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 60,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))],
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Image.asset('assets/ic_altcraft.png', width: 80, height: 20, fit: BoxFit.contain),
    );
  }
}
