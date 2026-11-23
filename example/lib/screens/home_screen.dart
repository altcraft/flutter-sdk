
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'package:altcraft_sdk_example/services/app_state.dart';
import 'package:altcraft_sdk_example/services/sdk_tests.dart';
import 'package:altcraft_sdk_example/services/store.dart';

const _kSuccess = Color(0xFF33FF5F);
const _kSuccessSoft = Color(0xFFADF7BD);
const _kError = Color(0xFFFF6E7F);
const _kSuspended = Color(0xFFFFD700);
const _kAccent = Color(0xFF8DBFFC);
const _kLine = Color(0xFFE2E8F0);
const _kTextSecondary = Color(0xFF475569);
const _kTextDark = Color(0xFF0F172A);

/// Main dashboard screen containing the SDK information,
/// action buttons and the recent event timeline.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _activePanel;
  Map<String, dynamic>? _profileData;
  bool _profileLoading = false;

  final _sidController = TextEditingController();
  final _nameController = TextEditingController();
  final _profileFieldsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    AppState.instance.removeListener(_onStateChanged);
    _sidController.dispose();
    _nameController.dispose();
    _profileFieldsController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Returns available push providers depending on the platform.
  List<_ModuleDef> get _modules {
    if (Platform.isIOS) {
      return [
        _ModuleDef(
          'apns',
          'assets/ic_apns.png',
          22,
          kApnsProvider,
          [kApnsProvider, kFcmProvider, kHmsProvider],
        ),
        _ModuleDef(
          'fcm',
          'assets/ic_fcm.png',
          19,
          kFcmProvider,
          [kFcmProvider, kHmsProvider, kApnsProvider],
        ),
        _ModuleDef(
          'hms',
          'assets/ic_hms.png',
          25,
          kHmsProvider,
          [kHmsProvider, kFcmProvider, kApnsProvider],
        ),
      ];
    }

    return [
      _ModuleDef(
        'fcm',
        'assets/ic_fcm.png',
        19,
        kFcmProvider,
        [kFcmProvider, kHmsProvider, kRustoreProvider],
      ),
      _ModuleDef(
        'hms',
        'assets/ic_hms.png',
        25,
        kHmsProvider,
        [kHmsProvider, kFcmProvider, kRustoreProvider],
      ),
      _ModuleDef(
        'rustore',
        'assets/ic_rus.png',
        22,
        kRustoreProvider,
        [kRustoreProvider, kFcmProvider, kHmsProvider],
      ),
    ];
  }

  /// Opens or closes one of the action panels.
  Future<void> _togglePanel(String panel) async {
    if (_activePanel == panel) {
      setState(() => _activePanel = null);
      return;
    }

    setState(() => _activePanel = panel);

    if (panel == 'profile') {
      setState(() => _profileLoading = true);

      final data = await SdkTests.doGetProfileStatus();

      if (!mounted) return;

      setState(() {
        _profileData = data;
        _profileLoading = false;
      });
    }
  }

  /// Clears local event history and resets the SDK.
  Future<void> _onClear() async {
    setState(() {
      _activePanel = null;
      _profileData = null;
    });

    AppState.instance.clearEvents();
    await SdkTests.doClear();
  }

  /// Creates the main screen and its vertically scrollable sections.
  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with providers, token cards and status buttons.
            _InfoCard(
              state: state,
              modules: _modules,
            ),

            const Padding(
              padding: EdgeInsets.only(left: 15, top: 20),
              child: Text(
                'Actions:',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Main Android Compose-style action buttons.
            _buildActionRow(),

            // Expanded panel or recent SDK events.
            ..._buildPanel(state),
          ],
        ),
      ),
    );
  }

  /// Creates the four primary action buttons.
  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: ComposeActionButton(
              label: 'Subscribe',
              icon: ComposeActionIcon.subscribe,
              onPressed: () => _togglePanel('subscribe'),
            ),
          ),
          Flexible(
            child: ComposeActionButton(
              label: 'Profile',
              icon: ComposeActionIcon.profile,
              onPressed: () => _togglePanel('profile'),
            ),
          ),
          Flexible(
            child: ComposeActionButton(
              label: 'Target',
              icon: ComposeActionIcon.target,
              onPressed: () => _togglePanel('target'),
            ),
          ),
          Flexible(
            child: ComposeActionButton(
              label: 'Clear',
              icon: ComposeActionIcon.clear,
              semanticsIdentifier: 'home_clear_config_button',
              onPressed: _onClear,
            ),
          ),
        ],
      ),
    );
  }

  /// Chooses the currently visible content below Actions.
  List<Widget> _buildPanel(AppState state) {
    switch (_activePanel) {
      case 'subscribe':
        return [_buildSubBox()];
      case 'profile':
        return [_buildProfileBox()];
      case 'target':
        return [_buildMobileEventBox()];
      default:
        return [_buildEventsSection(state)];
    }
  }

  /// Creates a shared section heading.
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 15,
        top: 20,
        bottom: 10,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  /// Creates a tinted informational strip with an optional action.
  Widget _sectionInfo(
    String text, {
    Color bg = const Color(0x33ADF7BD),
    VoidCallback? onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 6,
        ),
        height: 25,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 12,
                color: Colors.black.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates the Push and In-App subscription management panel.
  /// Mirrors ActionsComponents.SubBox in Android Compose.
  Widget _buildSubBox() {
    Future<void> runAndClose(Future<void> Function() action) async {
      await action();
      if (mounted) setState(() => _activePanel = null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Subscribe to:'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            height: 130,
            child: Row(
              children: [
                _verticalLabel('push', _kSuccess),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _subActionButton(
                          'Subscribe',
                          icon: const _SubPlusIcon(Colors.black),
                          iconBackground: _kSuccess.withValues(alpha: 0.1),
                          onTap: () => runAndClose(SdkTests.doPushSubscribe),
                        ),
                      ),
                      Expanded(
                        child: _subActionButton(
                          'Unsubscribe',
                          icon: const _SubXIcon(Colors.black, Colors.black),
                          onTap: () => runAndClose(SdkTests.doPushUnSubscribe),
                        ),
                      ),
                    ],
                  ),
                ),
                _verticalLabel('inapp', _kAccent),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _subActionButton(
                          'Subscribe',
                          icon: const _SubPlusIcon(Colors.black),
                          iconBackground: _kAccent.withValues(alpha: 0.1),
                          onTap: () => runAndClose(SdkTests.doInAppSubscribe),
                        ),
                      ),
                      Expanded(
                        child: _subActionButton(
                          'Unsubscribe',
                          icon: const _SubXIcon(Colors.black, Colors.black),
                          onTap: () => runAndClose(SdkTests.doInAppUnsubscribe),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 88.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _subActionButton(
                          'Log In',
                          iconSize: 23,
                          textSize: 10,
                          iconBackground: Colors.black.withValues(alpha: 0.7),
                          icon: const _SubArrowIcon(-1),
                          onTap: () => runAndClose(SdkTests.doLogin),
                        ),
                      ),
                      Expanded(
                        child: _subActionButton(
                          'Log Out',
                          iconSize: 23,
                          textSize: 10,
                          iconBackground: Colors.black.withValues(alpha: 0.7),
                          icon: const _SubArrowIcon(1),
                          onTap: () => runAndClose(SdkTests.doLogout),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Vertical module label, mirrors ActionsComponents.VerticalLabel.
  Widget _verticalLabel(String text, Color color) {
    return Expanded(
      flex: 1,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final char in text.split(''))
              Text(
                char,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// White rounded action tile, mirrors ActionsComponents.SubActionButton.
  Widget _subActionButton(
    String text, {
    required Widget icon,
    double iconSize = 20,
    double textSize = 8,
    Color iconBackground = const Color(0x1A000000),
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBackground,
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 2),
            Text(
              text,
              maxLines: 1,
              style: TextStyle(
                fontSize: textSize,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates the profile panel and its close action.
  /// Mirrors ProfileComponents.ProfileBox in Android Compose.
  Widget _buildProfileBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Profile info:'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Padding(
            padding: const EdgeInsets.only(left: 2.5),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: _profileLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _profileContent(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        _sectionTitle('Update profile fields:'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _textFieldRow('json', _profileFieldsController),
          ),
        ),
        _sectionInfo(
          'Click to update',
          bg: _kSuccessSoft.withValues(alpha: 0.2),
          icon: Icons.arrow_outward,
          onTap: () {
            final text = _profileFieldsController.text.trim();
            if (text.isEmpty) return;

            final decoded = jsonDecode(text);
            if (decoded is! Map<String, dynamic>) return;

            SdkTests.doUpdateProfileFields(decoded);
          },
        ),
        _sectionInfo(
          'Click to close',
          bg: _kAccent.withValues(alpha: 0.2),
          icon: Icons.close,
          onTap: () => setState(() => _activePanel = null),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  /// Builds the profile information shown in the Android profile panel.
  /// Its internal scroll height is limited to 70% of the screen height.
  Widget _profileContent() {
    final response = _profileData?['response'];
    final profile = response is Map ? response['profile'] : null;

    if (profile is! Map) {
      final errorText = response is Map ? response['error_text']?.toString() : null;
      return Text(
        errorText == null || errorText.isEmpty
            ? 'Profile data is null'
            : errorText,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    final subscription = profile['subscription'];
    final content = <Widget>[
      _profileRow('ID', _profileValue('ID', profile['id'])),
      _profileRow('Status', _profileValue('Status', profile['status'])),
      _profileRow('Is Test', _profileValue('Is Test', profile['is_test'])),
    ];

    if (subscription is Map) {
      content.addAll([
        const SizedBox(height: 5),
        _profileDivider(),
        const Text(
          'Subscription:',
          style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 5),
        _profileRow('Subscription ID',
            _profileValue('Subscription ID', subscription['subscription_id'])),
        _profileRow('Hash ID', _profileValue('Hash ID', subscription['hash_id'])),
        _profileRow('Provider', _profileValue('Provider', subscription['provider'])),
        _profileRow('Status', _profileValue('Status', subscription['status'])),
      ]);

      final cats = subscription['cats'];
      if (cats is List) {
        content.addAll([
          const SizedBox(height: 5),
          _profileDivider(),
          const Text(
            'Categories:',
            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
        ]);
        for (final category in cats) {
          if (category is Map) {
            content.addAll([
              _profileRow('Name', _profileValue('Name', category['name'])),
              _profileRow('Title', _profileValue('Title', category['title'])),
              _profileRow('Steady', _profileValue('Steady', category['steady'])),
              _profileRow('Active', _profileValue('Active', category['active'])),
              const SizedBox(height: 4),
            ]);
          }
        }
      }

      final fields = subscription['fields'];
      if (fields is Map) {
        content.addAll([
          const SizedBox(height: 5),
          _profileDivider(),
          const Text(
            'Fields:',
            style: TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
        ]);
        fields.forEach((key, value) {
          content.add(_profileRow(key.toString(), value?.toString() ?? 'null'));
        });
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < content.length; index++) ...[
              if (index > 0) const SizedBox(height: 4),
              content[index],
            ],
          ],
        ),
      ),
    );
  }

  /// Three-color divider used by Subscription, Categories and Fields.
  Widget _profileDivider() {
    return Container(
      width: double.infinity,
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        gradient: LinearGradient(
          colors: [
            _kAccent.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }

  /// Truncates long subscription IDs to the first and last 15 characters.
  String _profileValue(String label, dynamic value) {
    final text = value?.toString();
    if (label == 'Subscription ID' && text != null && text.length > 30) {
      return '${text.substring(0, 15)}...${text.substring(text.length - 15)}';
    }
    return text ?? 'null';
  }

  /// SpaceBetween layout with 10sp gray label and black value.
  Widget _profileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 3,
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 10, color: Colors.black),
          ),
        ),
      ],
    );
  }

  /// Creates the mobile event input form.
  Widget _buildMobileEventBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mobile Event:'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _textFieldRow('sid', _sidController),
                const Divider(
                  height: 12,
                  color: Color(0xFFE0E0E0),
                ),
                _textFieldRow('name', _nameController),
              ],
            ),
          ),
        ),
        _sectionInfo(
          'Click to send',
          bg: _kSuccessSoft.withValues(alpha: 0.2),
          icon: Icons.arrow_outward,
          onTap: () async {
            final sid = _sidController.text.trim();
            final name = _nameController.text.trim();

            if (sid.isEmpty || name.isEmpty) return;

            await SdkTests.doSendMobileEvent(sid, name);
          },
        ),
        _sectionInfo(
          'Click to close',
          bg: _kAccent.withValues(alpha: 0.2),
          icon: Icons.close,
          onTap: () => setState(() => _activePanel = null),
        ),
      ],
    );
  }

  /// Creates a labeled text field for mobile event parameters.
  Widget _textFieldRow(
    String label,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Enter value',
            ),
          ),
        ),
      ],
    );
  }

  /// Creates the recent SDK events section.
  Widget _buildEventsSection(AppState state) {
    final count = math.min(state.events.length, 5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Main events:'),
        if (state.events.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 15),
            child: Text(
              'No events yet',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 14,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 270),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(
                  left: 5,
                  right: 5,
                  top: 5,
                ),
                itemCount: count,
                itemBuilder: (context, index) {
                  final event =
                      state.events[state.events.length - 1 - index];

                  return _EventCard(
                    ev: event,
                    isFirst: index == 0,
                    isLast: index == count - 1,
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Contains metadata for a push notification provider.
class _ModuleDef {
  final String name;
  final String icon;
  final double iconSize;
  final String providerConst;
  final List<String> priority;

  const _ModuleDef(
    this.name,
    this.icon,
    this.iconSize,
    this.providerConst,
    this.priority,
  );
}

/// Main information header matching Android InfoComponents.
///
/// Layout:
/// - Altcraft logo
/// - Push provider cards
/// - Horizontally scrollable token cards
/// - InApp, Push, Auth and GitHub status cards
/// - Altcraft website card
/// - Subscribe status indicator
///
/// The token carousel and status buttons occupy independent
/// non-overlapping regions. No status card is rendered inside
/// the token carousel.
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.state,
    required this.modules,
  });

  final AppState state;
  final List<_ModuleDef> modules;

  static const double _headerHeight = 320;
  static const double _logoTop = 16;
  static const double _logoHeight = 20;
  static const double _logoBottom = 11;

  static const double _tokenRowHeight = 135;
  static const double _statusRowHeight = 65;

  /// Native Altcraft SDK module versions, matching the artifacts linked
  /// by the example app (android-sdk-* on Android, ios-sdk on iOS).
  static final String _sdkModuleVersions = Platform.isIOS
      ? 'core: 2.0.0\npush: 2.0.0\ninapp: 2.0.0\ntarget: 2.0.0\nprofile: 2.0.0'
      : 'core: 1.0.1\npush: 1.0.1\ninapp: 1.0.1\ntarget: 1.0.1\nprofile: 1.0.1';

  @override
  Widget build(BuildContext context) {
    final tokenCardTitle = _tokenCardTitle(state.provider);

    final token = state.token;
    final tokenBody = token == null || token.isEmpty
        ? kEmptyValueUi
        : token.substring(math.max(0, token.length - 10));

    final updateTime = _formatDate(state.tokenUpdateTime);

    final provider = state.provider;
    final effectiveProvider =
        provider != null && _isKnownProvider(provider)
            ? provider
            : null;

    // Reserve the required height for the token and status rows.
    //
    // The header is composed of:
    // 16dp top padding
    // 20dp logo
    // 11dp space below logo
    // 135dp token carousel
    // 65dp first status row
    // 65dp second status row
    //
    // The status rows start AFTER the token viewport.
    // They cannot paint on top of the token cards.
    return Container(
      height: _headerHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: _logoTop),

              // Altcraft logo.
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Image.asset(
                  'assets/ic_altcraft.png',
                  width: 80,
                  height: _logoHeight,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: _logoBottom),

              // Providers on the left, information on the right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: modules.map((module) {
                        return _ModuleCard(
                          def: module,
                          isOn: module.providerConst ==
                                  effectiveProvider ||
                              (effectiveProvider?.contains(
                                    module.providerConst
                                        .split('-')
                                        .last,
                                  ) ??
                                  false),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Independent information and status column.
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First band: token information carousel.
                        //
                        // SizedBox establishes the exact viewport height.
                        // The scrolling cards cannot change the vertical
                        // position of the status buttons.
                        SizedBox(
                          height: _tokenRowHeight,
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _InfoItemCard(
                                  title: tokenCardTitle,
                                  body: tokenBody,
                                  icon: _tokenIcon(state.provider),
                                ),
                                const _InfoItemCard(
                                  title: 'platform:',
                                  body: 'Flutter',
                                  icon: 'assets/ic_os.png',
                                  iconSize: 28,
                                ),
                                _InfoItemCard(
                                  title: 'update time:',
                                  body: updateTime,
                                  icon: 'assets/ic_time_icon.png',
                                ),
                                _InfoItemCard(
                                  title: 'version:',
                                  body: _sdkModuleVersions,
                                  icon: 'assets/ic_info_setting2.png',
                                  bodyMaxLines: 5,
                                  bodyFontSize: 10,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Second band: InApp, Push, Auth and GitHub.
                        //
                        // The Row itself is transparent. Only the
                        // individual cards have white backgrounds.
                        SizedBox(
                          height: _statusRowHeight,
                          child: _statusCardsRow([
                            _StatusCard(
                              icon: 'assets/ic_menu_example.png',
                              iconSize: 22,
                              iconAlpha: 0.5,
                              badge:
                                  state.inAppStatus == kSubscribed,
                              semanticsLabel:
                                  'home_inapp_subscription_button',
                              semanticsIdentifier:
                                  'home_inapp_subscription_button',
                              onTap: () async {
                                if (state.inAppStatus == kSubscribed) {
                                  await SdkTests
                                      .doInAppUnsubscribe();
                                } else {
                                  await SdkTests
                                      .doInAppSubscribe();
                                }
                              },
                            ),
                            _StatusCard(
                              icon: 'assets/ic_bell_3.png',
                              iconSize: 20,
                              iconAlpha: 0.7,
                              badge: state.status == kSubscribed,
                              onTap: () async {
                                if (state.status == kSubscribed) {
                                  await SdkTests
                                      .doPushUnSubscribe();
                                } else {
                                  await SdkTests
                                      .doPushSubscribe();
                                }
                              },
                            ),
                            _StatusCard(
                              icon: 'assets/ic_fingerprint.png',
                              iconSize: 25,
                              authDot: state.authStatus,
                              semanticsLabel: 'home_auth_button',
                              semanticsIdentifier: 'home_auth_button',
                              onTap: () async {
                                if (state.authStatus) {
                                  await AltcraftCore.logOut();
                                } else {
                                  await AltcraftCore.authenticate();
                                }
                              },
                            ),
                            _StatusCard(
                              icon: 'assets/ic_github.png',
                              iconSize: 20,
                              onTap: () => _openUrl(
                                'https://github.com/altcraft/android-sdk',
                              ),
                            ),
                          ]),
                        ),

                        // Third band: Altcraft website button.
                        //
                        // The first three slots are transparent,
                        // preserving the original Compose alignment.
                        SizedBox(
                          height: _statusRowHeight,
                          child: _statusCardsRow([
                            const _StatusCard.invisible(),
                            const _StatusCard.invisible(),
                            const _StatusCard.invisible(),
                            _StatusCard(
                              icon:
                                  'assets/ic_altcraft_push_icon.jpg',
                              iconSize: 27,
                              onTap: () => _openUrl(
                                'https://guides.altcraft.com/developer-guide/sdk/mobile/android/',
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Subscribe status is aligned with the Altcraft website card,
          // exactly like the Android Compose reference.
          Positioned(
            left: 15,
            bottom: 17,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Subscribe status:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusIndicator(
                  status: state.status,
                  radius: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Checks whether a provider is supported by the SDK.
  bool _isKnownProvider(String provider) {
    return provider == kFcmProvider ||
        provider == kHmsProvider ||
        provider == kRustoreProvider ||
        provider == kApnsProvider;
  }

  /// Returns the active push token card title.
  String _tokenCardTitle(String? provider) {
    if (provider == kFcmProvider) return 'fcm token:';
    if (provider == kHmsProvider) return 'hms token:';
    if (provider == kRustoreProvider) {
      return 'rustore token:';
    }
    if (provider == kApnsProvider) return 'apns token:';
    return 'no providers:';
  }

  /// Returns the icon associated with the active provider.
  String _tokenIcon(String? provider) {
    if (provider == kHmsProvider) {
      return 'assets/ic_hms_logo_2.png';
    }
    if (provider == kRustoreProvider) {
      return 'assets/ic_rus.png';
    }
    if (provider == kApnsProvider) {
      return 'assets/ic_apns.png';
    }
    return 'assets/ic_fcm.png';
  }

  /// Formats an ISO-like date as dd.MM.yyyy.
  String _formatDate(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      return '—';
    }

    final datePart = timestamp.split(' ').first;
    final parts = datePart.split('-');

    if (parts.length < 3) return datePart;

    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }

  /// Opens external documentation or the GitHub repository.
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  /// Creates one transparent row of four status button slots.
  ///
  /// Matches the weighted layout used in Android Compose:
  /// the first two buttons use 2.0 weight and the last
  /// two use 1.85 weight.
  Widget _statusCardsRow(List<Widget> cards) {
    assert(cards.length == 4);

    return Padding(
      padding: const EdgeInsets.only(
        left: 7,
        top: 3,
        right: 5,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 200,
            child: Row(
              children: [
                Expanded(child: cards[0]),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          Expanded(
            flex: 185,
            child: Row(
              children: [
                Expanded(child: cards[2]),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Creates one push provider card in the left column.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.def,
    required this.isOn,
  });

  final _ModuleDef def;
  final bool isOn;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await SdkTests.doUpdateProvider(def.priority);
      },
      child: SizedBox(
        width: 90,
        height: 66,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 7,
            left: 3,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  margin: const EdgeInsets.only(left: 5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    def.icon,
                    width: def.iconSize,
                    height: def.iconSize,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        def.name,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 7),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isOn ? 'on' : 'off',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _StatusIndicator(
                              status: isOn
                                  ? kSubscribed
                                  : kUnsubscribed,
                              radius: 7,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Creates one information card for token, date or SDK version.
class _InfoItemCard extends StatelessWidget {
  const _InfoItemCard({
    required this.title,
    required this.body,
    required this.icon,
    this.iconSize = 20,
    this.bodyMaxLines = 2,
    this.bodyFontSize = 12,
  });

  final String title;
  final String body;
  final String icon;
  final double iconSize;

  /// Maximum number of body text lines (use a larger value for lists).
  final int bodyMaxLines;

  /// Body text font size.
  final double bodyFontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 137,
      height: 135,
      child: Padding(
        padding: const EdgeInsets.only(
          top: 7,
          left: 8,
          right: 7,
          bottom: 4,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 5,
                  top: 5,
                  right: 4,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        icon,
                        width: iconSize,
                        height: iconSize,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 5),

              // The card body is centered in the remaining space.
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(2, -10),
                    child: Text(
                      body,
                      textAlign: TextAlign.center,
                      maxLines: bodyMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: bodyFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Creates a status shortcut button.
///
/// Displays:
/// - InApp subscription check badge
/// - Push subscription check badge
/// - Authentication green glow
/// - GitHub or Altcraft website icon
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.icon,
    this.iconSize = 20,
    this.iconAlpha = 1.0,
    this.badge = false,
    this.authDot = false,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.onTap,
  }) : opacity = null;

  const _StatusCard.invisible()
      : icon = '',
        iconSize = 0,
        iconAlpha = 0,
        badge = false,
        authDot = false,
        opacity = 0,
        semanticsLabel = null,
        semanticsIdentifier = null,
        onTap = null;

  final String icon;
  final double iconSize;
  final double iconAlpha;
  final bool badge;
  final bool authDot;
  final double? opacity;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Invisible cells do not create white backgrounds.
    if (opacity == 0) {
      return const SizedBox.expand();
    }

    final card = Padding(
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: SizedBox(
          width: iconSize,
          height: iconSize,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Green authentication indicator behind the fingerprint.
              if (authDot)
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kSuccessSoft.withValues(alpha: 0.5),
                  ),
                ),

              if (icon.isNotEmpty)
                Opacity(
                  opacity: iconAlpha,
                  child: Image.asset(
                    icon,
                    width: iconSize,
                    height: iconSize,
                  ),
                ),

              // Checkmark appears when Push or InApp is subscribed.
              if (badge)
                Positioned(
                  top: -2,
                  right: 0,
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 7,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      identifier: semanticsIdentifier,
      label: semanticsLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: opacity == null
            ? card
            : Opacity(
                opacity: opacity!,
                child: card,
              ),
      ),
    );
  }
}

/// Draws the provider or subscription status indicator.
class _StatusIndicator extends StatelessWidget {
  const _StatusIndicator({
    required this.status,
    required this.radius,
  });

  final String status;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (status == kSubscribed) {
      return Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              _kSuccessSoft,
              _kSuccess,
            ],
          ),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    if (status == kSuspended) {
      return Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              _kSuspended,
              _kError,
            ],
          ),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.1),
          ),
        ),
      );
    }

    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kError,
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

/// Displays an SDK event using the Android Compose timeline layout.
class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.ev,
    this.isFirst = false,
    required this.isLast,
  });

  final SdkEvent ev;
  final bool isFirst;
  final bool isLast;

  bool get _isProviderSet => ev.message.startsWith('push provider set -');

  Color get _dotColor {
    if (_isProviderSet) return _kSuccess;
    if (ev.type == 'error' || ev.type == 'retryError') return _kError;

    final code = ev.code;
    if (code != null) {
      return (code >= 200 && code <= 299) || code == 304
          ? _kSuccess
          : _kError;
    }
    return Colors.black;
  }

  String? get _badgeText {
    if (_isProviderSet) {
      final token = ev.value?['token']?.toString();
      if (token == null || token.trim().isEmpty) return null;
      return token.substring(math.max(0, token.length - 3));
    }
    return ev.code?.toString();
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = (ev.timestamp ?? '').trim();
    final parts = timestamp.split(RegExp(r'\s+'));
    final date = timestamp.isEmpty ? '--' : parts.first;
    final time = parts.length > 1 ? parts.skip(1).join(' ') : '--';
    final badge = _badgeText;
    final statusColor = _dotColor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 54,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!isFirst)
                        const Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            width: 1,
                            height: 27,
                            child: ColoredBox(color: _kLine),
                          ),
                        ),
                      if (!isLast)
                        const Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            width: 1,
                            height: 27,
                            child: ColoredBox(color: _kLine),
                          ),
                        ),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 82,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          date,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: _kTextSecondary,
                          ),
                        ),
                        Text(
                          time,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ev.function.isEmpty ? ev.type : ev.function,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          ev.message.isEmpty ? 'SDK event' : ev.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9,
                            color: _kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  )
                else
                  const Text(
                    '›',
                    style: TextStyle(
                      fontSize: 20,
                      color: _kTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 92),
            child: Container(
              width: double.infinity,
              height: 1,
              color: _kLine.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}

/// Available Android Compose-style action icons.
enum ComposeActionIcon {
  subscribe,
  profile,
  target,
  clear,
}

/// Creates a primary action button matching Android Compose.
///
/// The component contains:
/// - 60dp outer white circle
/// - 50dp inner black circle
/// - CustomPaint icon
/// - Label below the button
class ComposeActionButton extends StatelessWidget {
  const ComposeActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.semanticsIdentifier,
  });

  final String label;
  final ComposeActionIcon icon;
  final VoidCallback onPressed;
  final bool enabled;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: semanticsIdentifier,
              button: true,
              label: label,
              enabled: enabled,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: enabled ? onPressed : null,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: CustomPaint(
                        size: const Size(18, 18),
                        painter: _ComposeActionPainter(icon),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            SizedBox(
              width: 70,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  height: 1,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws action icons based on the Android Compose implementation.
class _ComposeActionPainter extends CustomPainter {
  const _ComposeActionPainter(this.icon);

  final ComposeActionIcon icon;

  static const _green = Color(0xFF33FF5F);
  static const _blue = Color(0xFF8DBFFC);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final scale = size.width / 18;

    final round = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    switch (icon) {
      case ComposeActionIcon.subscribe:
        // Rounded green plus.
        round.color = _green;

        canvas.drawLine(
          Offset(center.dx - 6 * scale, center.dy),
          Offset(center.dx + 6 * scale, center.dy),
          round,
        );

        canvas.drawLine(
          Offset(center.dx, center.dy - 6 * scale),
          Offset(center.dx, center.dy + 6 * scale),
          round,
        );
        break;

      case ComposeActionIcon.profile:
        // White dot with a blue V-shaped checkmark.
        canvas.drawCircle(
          Offset(center.dx, center.dy - 5 * scale),
          3.5 * scale,
          Paint()..color = Colors.white,
        );

        round.color = _blue;

        canvas.drawLine(
          Offset(
            center.dx - 6 * scale,
            center.dy + 2 * scale,
          ),
          Offset(
            center.dx,
            center.dy + 7 * scale,
          ),
          round,
        );

        canvas.drawLine(
          Offset(
            center.dx,
            center.dy + 7 * scale,
          ),
          Offset(
            center.dx + 6 * scale,
            center.dy + 2 * scale,
          ),
          round,
        );
        break;

      case ComposeActionIcon.target:
        // Blue and white semicircles.
        final rect = Rect.fromCircle(
          center: center,
          radius: 7.5 * scale,
        );

        round.strokeWidth = 3 * scale;
        round.color = _blue;

        canvas.drawArc(
          rect,
          math.pi,
          math.pi,
          false,
          round,
        );

        round.color = Colors.white;

        canvas.drawArc(
          rect,
          0,
          math.pi,
          false,
          round,
        );
        break;

      case ComposeActionIcon.clear:
        // Blue and white crossed strokes.
        round.color = _blue;

        canvas.drawLine(
          Offset(
            center.dx - 5 * scale,
            center.dy + 5 * scale,
          ),
          Offset(
            center.dx + 5 * scale,
            center.dy - 5 * scale,
          ),
          round,
        );

        round.color = Colors.white;

        canvas.drawLine(
          Offset(
            center.dx - 5 * scale,
            center.dy - 5 * scale,
          ),
          Offset(
            center.dx + 5 * scale,
            center.dy + 5 * scale,
          ),
          round,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(
    covariant _ComposeActionPainter oldDelegate,
  ) {
    return oldDelegate.icon != icon;
  }
}

/// Plus icon for the subscription panel, mirrors ActionsComponents.PlusIcon.
class _SubPlusIcon extends StatelessWidget {
  final Color color;

  const _SubPlusIcon(this.color);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(painter: _SubPlusPainter(color)),
    );
  }
}

class _SubPlusPainter extends CustomPainter {
  final Color color;

  const _SubPlusPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final thickness = size.height * 0.2;
    final radius = Radius.circular(thickness / 2);
    final top = size.height / 2 - thickness / 2;
    final bar = Rect.fromLTWH(0, top, size.width, thickness);
    final paint = Paint()..color = color;

    canvas.drawRRect(RRect.fromRectAndRadius(bar, radius), paint);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(math.pi / 2);
    canvas.translate(-size.width / 2, -size.height / 2);
    canvas.drawRRect(RRect.fromRectAndRadius(bar, radius), paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SubPlusPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// X-shaped icon, mirrors ActionsComponents.XShapedIcon.
class _SubXIcon extends StatelessWidget {
  final Color firstColor;
  final Color secondColor;

  const _SubXIcon(this.firstColor, this.secondColor);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(painter: _SubXPainter(firstColor, secondColor)),
    );
  }
}

class _SubXPainter extends CustomPainter {
  final Color firstColor;
  final Color secondColor;

  const _SubXPainter(this.firstColor, this.secondColor);

  @override
  void paint(Canvas canvas, Size size) {
    final thickness = size.height * 0.2;
    final radius = Radius.circular(thickness / 2);
    final top = size.height / 2 - thickness / 2;
    final bar = Rect.fromLTWH(0, top, size.width, thickness);

    for (final entry in [
      MapEntry(math.pi / 4, firstColor),
      MapEntry(-math.pi / 4, secondColor),
    ]) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.rotate(entry.key);
      canvas.translate(-size.width / 2, -size.height / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, radius),
        Paint()..color = entry.value,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SubXPainter oldDelegate) =>
      oldDelegate.firstColor != firstColor ||
      oldDelegate.secondColor != secondColor;
}

/// Arrow icon for Log In / Log Out, mirrors ActionsComponents.CommonIcon
/// with a rotated CheckMarkIcon.
class _SubArrowIcon extends StatelessWidget {
  final int quarterTurns;

  const _SubArrowIcon(this.quarterTurns);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 17,
      height: 17,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: CustomPaint(painter: const _SubCheckMarkPainter()),
      ),
    );
  }
}

class _SubCheckMarkPainter extends CustomPainter {
  const _SubCheckMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.height * (3.0 / 17.0);
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final bottom = Offset(size.width / 2, size.height * 0.9);
    final left = Offset(size.width * 0.15, size.height * 0.65);
    final right = Offset(size.width * 0.85, size.height * 0.65);

    canvas.drawLine(left, bottom, paint);
    canvas.drawLine(right, bottom, paint);
  }

  @override
  bool shouldRepaint(covariant _SubCheckMarkPainter oldDelegate) => false;
}
