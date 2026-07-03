import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:altcraft_sdk/altcraft_sdk.dart';
import 'package:altcraft_sdk_example/services/store.dart';
import 'package:altcraft_sdk_example/services/sdk_tests.dart';
import 'package:altcraft_sdk_example/services/event_bus.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _token;
  String? _provider;
  final List<SdkEvent> _events = [];
  bool _showSubscribe = false;
  bool _showProfile = false;
  Map<String, dynamic>? _profileData;
  String? _loading;
  String? _initError;
  bool _isInitialized = false;

  bool _showMobileEvent = false;
  final _meEventNameController = TextEditingController();

  bool _showTokenActions = false;
  bool _showProfileFields = false;
  final _pfKeyController = TextEditingController();
  final _pfValueController = TextEditingController();
  final Map<String, String> _pfFields = {};

  StreamSubscription<SdkEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _eventSubscription = EventBus.instance.stream.listen(_handleEvent);
    _init();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _meEventNameController.dispose();
    _pfKeyController.dispose();
    _pfValueController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final config = await Store.instance.getConfig();

      await SdkTests.initializationSDK(config);

      final tokenData = await AltcraftSDK.getPushToken();
      if (tokenData != null) {
        if (mounted) setState(() {
          _token = tokenData.token;
          _provider = tokenData.provider;
        });
        await Store.instance.saveTokenData(tokenData.provider, tokenData.token);
      } else {
        final savedToken = await Store.instance.getToken();
        final savedProvider = await Store.instance.getProvider();
        if (mounted) setState(() {
          _token = savedToken;
          _provider = savedProvider;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    }
  }

  void _handleEvent(SdkEvent event) {
    // Prepend new events (newest first)
    setState(() {
      _events.insert(0, event);
      if (_events.length > 200) _events.removeRange(_events.length - 200, _events.length);
    });

    if ((event.code == 233 || event.code == 201) && event.value != null) {
      final val = event.value!;
      if (val['provider'] != null && val['token'] != null) {
        setState(() {
          _provider = val['provider'] as String?;
          _token = val['token'] as String?;
        });
        Store.instance.saveTokenData(val['provider'] as String, val['token'] as String);
      }
    }
  }

  Future<void> _run(String label, Future<void> Function() fn) async {
    setState(() => _loading = label);
    try {
      await fn();
    } catch (e) {
      debugPrint('[$label] error: $e');
    } finally {
      setState(() => _loading = null);
    }
  }

  String get _tokenDisplay {
    if (_token == null) return '—';
    if (_token!.length > 16) return '${_token!.substring(0, 6)}…${_token!.substring(_token!.length - 10)}';
    return _token!;
  }

  final _cardShadow = [
    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_initError != null) ...[
            _buildCard(
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF6E7F), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_initError!, style: const TextStyle(fontSize: 11, color: Color(0xFFFF6E7F), fontFamily: 'Menlo')),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _initError = null);
                      _init();
                    },
                    child: const Text('Retry', style: TextStyle(fontSize: 11, color: Color(0xFF3366FF))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Connection card
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Push data', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildChip('Provider', _provider ?? '—')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildChip('Token', _tokenDisplay)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Actions
          const Text('Actions:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          _buildActionRow(
            _buildActionButton('Subscribe', isActive: _showSubscribe, isSubscribe: true, onTap: () => setState(() => _showSubscribe = !_showSubscribe)),
            _buildActionButton('Profile', isActive: _showProfile, onTap: () async {
              setState(() => _showProfile = !_showProfile);
              final data = await SdkTests.doGetProfileStatus();
              setState(() => _profileData = data);
            }),
          ),
          _buildActionRow(
            _buildActionButton('Update Token', isActive: _showTokenActions, onTap: () => setState(() => _showTokenActions = !_showTokenActions)),
            _buildActionButton('Clear', onTap: () => _run('clear', () async {
              SdkTests.doClear();
              _eventSubscription?.cancel();
              _eventSubscription = null;
              setState(() {
                _token = null;
                _provider = null;
                _events.clear();
                _profileData = null;
                _showProfile = false;
                _showSubscribe = false;
                _isInitialized = false;
              });
              await Store.instance.clearAll();
            })),
          ),
           _buildActionRow(
            _buildActionButton('Mobile Event', isActive: _showMobileEvent, onTap: () => setState(() => _showMobileEvent = !_showMobileEvent)),
            _buildActionButton('Profile Fields', isActive: _showProfileFields, onTap: () => setState(() => _showProfileFields = !_showProfileFields)),
          ),

          // Token Actions Panel
          if (_showTokenActions) ...[
            _buildPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Token Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildActionRow(
                    _buildSubButton('Forced Token Update', Colors.white, onTap: () {
                      _run('token', SdkTests.doForcedTokenUpdate);
                      setState(() => _showTokenActions = false);
                    }),
                  ),
                  const SizedBox(height: 8),
                  if (Platform.isAndroid) ...[
                    _buildActionRow(
                      _buildSubButton('FCM', Colors.white, onTap: () {
                        AltcraftSDK.changePushProviderPriorityList(['android-firebase']);
                        setState(() => _showTokenActions = false);
                      }),
                      _buildSubButton('HMS', Colors.white, onTap: () {
                        AltcraftSDK.changePushProviderPriorityList(['android-huawei']);
                        setState(() => _showTokenActions = false);
                      }),
                      _buildSubButton('RUSTORE', Colors.white, onTap: () {
                        AltcraftSDK.changePushProviderPriorityList(['android-rustore']);
                        setState(() => _showTokenActions = false);
                      }),
                    ),
                  ] else ...[
                    _buildActionRow(
                      _buildSubButton('APNS', Colors.white, onTap: () {
                        AltcraftSDK.changePushProviderPriorityList(['ios-apns']);
                        setState(() => _showTokenActions = false);
                      }),
                      _buildSubButton('FCM', Colors.white, onTap: () {
                        AltcraftSDK.changePushProviderPriorityList(['ios-firebase']);
                        setState(() => _showTokenActions = false);
                      }),
                      _buildSubButton('HMS', Colors.white, onTap: () {
                        AltcraftSDK.changePushProviderPriorityList(['ios-hms']);
                        setState(() => _showTokenActions = false);
                      }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_loading != null) ...[
            const SizedBox(height: 4),
            Text('$_loading…', style: const TextStyle(color: Color(0xFF666666), fontSize: 12)),
          ],

          const SizedBox(height: 12),

          // Subscribe Panel
          if (_showSubscribe) ...[
            _buildPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subscribe Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildActionRow(
                    _buildSubButton('Subscribe', Colors.white, onTap: () { SdkTests.doPushSubscribe(); setState(() => _showSubscribe = false); }),
                    _buildSubButton('Suspend', Colors.white, onTap: () { SdkTests.doPushSuspend(); setState(() => _showSubscribe = false); }),
                  ),
                  _buildActionRow(
                    _buildSubButton('Unsubscribe', Colors.white, onTap: () { SdkTests.doPushUnSubscribe(); setState(() => _showSubscribe = false); }),
                    _buildSubButton('Log In', Colors.white, onTap: () { SdkTests.doLogin(); setState(() => _showSubscribe = false); }),
                  ),
                  _buildActionRow(
                    _buildSubButton('Log Out', Colors.white, onTap: () { SdkTests.doLogout(); setState(() => _showSubscribe = false); }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Mobile Event Panel
          if (_showMobileEvent) ...[
            _buildPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mobile Event', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  TextField(
                    controller: _meEventNameController,
                    decoration: const InputDecoration(hintText: 'Event name', isDense: true),
                  ),
                  const SizedBox(height: 6),
                  _buildSubButton('Send', Colors.white, onTap: () async {
                    setState(() => _loading = 'mobileEvent');
                    try {
                      SdkTests.doSendMobileEvent(_meEventNameController.text.trim().isEmpty ? 'rn_event' : _meEventNameController.text.trim());
                    } catch (e) {
                      debugPrint('[sendMobileEvent] error: $e');
                    } finally {
                      setState(() {
                        _loading = null;
                        _showMobileEvent = false;
                      });
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Profile Fields Panel
          if (_showProfileFields) ...[
            _buildPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Fields', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  for (var entry in _pfFields.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _buildCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${entry.key} = ${entry.value}', style: const TextStyle(fontSize: 11, fontFamily: 'Menlo')),
                            TextButton(onPressed: () => setState(() => _pfFields.remove(entry.key)), child: const Text('✕', style: TextStyle(color: Color(0xFFFF6E7F)))),
                          ],
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _pfKeyController, decoration: const InputDecoration(hintText: 'Key', isDense: true))),
                      const SizedBox(width: 4),
                      Expanded(child: TextField(controller: _pfValueController, decoration: const InputDecoration(hintText: 'Value', isDense: true))),
                      const SizedBox(width: 4),
                      _buildCard(
                        child: IconButton(icon: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), onPressed: () {
                          if (_pfKeyController.text.trim().isEmpty) return;
                          setState(() {
                            _pfFields[_pfKeyController.text.trim()] = _pfValueController.text.trim();
                            _pfKeyController.clear();
                            _pfValueController.clear();
                          });
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildSubButton('Update', Colors.white, onTap: () async {
                    setState(() => _loading = 'profileFields');
                    try {
                      SdkTests.doUpdateProfile(_pfFields.isEmpty ? null : Map.from(_pfFields));
                    } catch (e) {
                      debugPrint('[sendProfileFields] error: $e');
                    } finally {
                      setState(() {
                        _loading = null;
                        _showProfileFields = false;
                      });
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Profile Panel
          if (_showProfile) ...[
            _buildPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Profile Data', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  if (_profileData != null)
                    for (var entry in _profileData!.entries)
                      Text('${entry.key}: ${entry.value}', style: const TextStyle(fontFamily: 'Menlo', fontSize: 11))
                  else
                    const Text('No data', style: TextStyle(fontFamily: 'Menlo', fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Recent Events
          if (_events.isNotEmpty) ...[
            const Text('Recent Events', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 8),
            _buildEventsList(),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _cardShadow,
      ),
      child: child,
    );
  }

  Widget _buildPanel({required Widget child}) {
    return _buildCard(child: child);
  }

  Widget _buildChip(String label, String value) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF808080))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 12, fontFamily: 'Menlo', fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActionRow(Widget a, [Widget? b, Widget? c]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: c != null
          ? [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b!), const SizedBox(width: 8), Expanded(child: c)]
          : b != null
              ? [Expanded(child: a), const SizedBox(width: 8), Expanded(child: b)]
              : [Expanded(child: a)]),
    );
  }

  Widget _buildActionButton(String text, {bool isActive = false, bool isSubscribe = false, VoidCallback? onTap}) {
    return _buildCard(
      child: InkWell(
        onTap: _loading != null ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSubscribe && isActive ? const Color(0xFFd3f5da) : isActive ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildSubButton(String text, Color color, {VoidCallback? onTap}) {
    return _buildCard(
      child: InkWell(
        onTap: _loading != null ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    final visible = _events.length > 5 ? _events.sublist(0, 5) : _events;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: _cardShadow,
      ),
      child: Column(
        children: visible.asMap().entries.map((entry) {
          final i = entry.key;
          final ev = entry.value;
          final statusColor = _getEventStatusColor(ev);
          final badgeText = _getEventBadgeText(ev);

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Timeline
                  SizedBox(
                    width: 14,
                    height: 54,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (i > 0) const Align(alignment: Alignment.topCenter, child: SizedBox(width: 1, height: 27, child: VerticalDivider(width: 1, color: Color(0xFFE2E8F0)))),
                        if (i < visible.length - 1) const Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 1, height: 27, child: VerticalDivider(width: 1, color: Color(0xFFE2E8F0)))),
                        Container(width: 9, height: 9, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      ],
                    ),
                   ),
                   const SizedBox(width: 6),
                   // Timestamp
                   SizedBox(
                      width: 72,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev.timestamp != null ? _formatDatePart(ev.timestamp!) : '—', style: const TextStyle(color: Color(0xFF475569), fontSize: 8.5, fontWeight: FontWeight.w700)),
                          Text(ev.timestamp != null ? _formatTimePart(ev.timestamp!) : '—', style: const TextStyle(color: Color(0xFF0F172A), fontSize: 8.5, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  // Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ev.function.isEmpty ? ev.type : ev.function, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 10, fontWeight: FontWeight.w700)),
                          Text(ev.message.isEmpty ? 'SDK event' : ev.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF475569), fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
                   // Badge
                   SizedBox(
                     width: 50,
                     child: Center(
                       child: badgeText != null
                           ? Container(
                               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                               decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                               child: Text(badgeText, style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                             )
                           : const Text('›', style: TextStyle(color: Color(0xFF475569), fontSize: 20)),
                     ),
                   ),
                ],
              ),
              if (i < visible.length - 1)
                Padding(padding: const EdgeInsets.only(left: 92), child: const Divider(height: 1, thickness: 0.8, color: Color(0xFFE2E8F0))),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _formatDatePart(String ts) {
    try {
      final parts = ts.split(' ');
      if (parts.isNotEmpty) return parts[0];
      return ts;
    } catch (_) {
      return ts;
    }
  }

  String _formatTimePart(String ts) {
    try {
      final parts = ts.split(' ');
      if (parts.length > 1) return parts[1];
      return '';
    } catch (_) {
      return '';
    }
  }

  Color _getEventStatusColor(SdkEvent ev) {
    if (ev.code == 233) return const Color(0xFF33FF5F);
    if (ev.type == 'error') return const Color(0xFFFF6E7F);
    if (ev.type == 'retryError') return const Color(0xFFFF6E7F);
    final code = ev.code;
    if (code != null && ((code >= 200 && code <= 299) || code == 304)) return const Color(0xFF33FF5F);
    return Colors.black;
  }

  String? _getEventBadgeText(SdkEvent ev) {
    if (ev.code == 233) {
      final token = ev.value?['token'];
      if (token is String && token.isNotEmpty) return token.substring(token.length - 3);
      return null;
    }
    return ev.code != null ? ev.code.toString() : null;
  }
}
