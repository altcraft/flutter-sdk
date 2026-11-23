import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:altcraft_push/altcraft_push.dart';
import 'package:altcraft_sdk_example/services/store.dart';

const _kSuccessSoft = Color(0xFFADF7BD);
const _kAccent = Color(0xFF8DBFFC);
const _kLine = Color(0xFFE0E0E0);

/// Example screen for configuring and displaying a test push notification.
///
/// Mirrors Android Compose ExampleScreen:
/// - Altcraft header
/// - Notification preview card
/// - Scrollable notification settings
/// - Text, image and button settings
/// - Send push action
class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _titleController = TextEditingController(text: kExampleTitle);
  final _bodyController = TextEditingController(text: kExampleBody);
  final _smallUrlController = TextEditingController();
  final _largeUrlController = TextEditingController();

  List<String> _buttons = [];

  Uint8List? _smallImage;
  Uint8List? _largeImage;

  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // Load saved notification configuration.
    _load();

    // Refresh the notification preview when text changes.
    _titleController.addListener(_onPreviewChanged);
    _bodyController.addListener(_onPreviewChanged);
  }

  @override
  void dispose() {
    _titleController.removeListener(_onPreviewChanged);
    _bodyController.removeListener(_onPreviewChanged);

    _titleController.dispose();
    _bodyController.dispose();
    _smallUrlController.dispose();
    _largeUrlController.dispose();

    super.dispose();
  }

  void _onPreviewChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Loads notification data from persistent storage.
  Future<void> _load() async {
    final data = await Store.instance.getNotificationData();

    if (!mounted) return;

    setState(() {
      _titleController.text = data.title;
      _bodyController.text = data.body;

      _smallUrlController.text = data.smallImageUrl ?? '';
      _largeUrlController.text = data.largeImageUrl ?? '';

      _buttons = List<String>.of(data.buttons);

      _smallImage = null;
      _largeImage = null;
    });

    if (data.smallImageUrl != null && data.smallImageUrl!.isNotEmpty) {
      await _loadImage(
        data.smallImageUrl!,
        small: true,
      );
    }

    if (data.largeImageUrl != null && data.largeImageUrl!.isNotEmpty) {
      await _loadImage(
        data.largeImageUrl!,
        small: false,
      );
    }
  }

  /// Downloads a notification image for the preview.
  Future<void> _loadImage(
    String url, {
    required bool small,
  }) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          if (small) {
            _smallImage = response.bodyBytes;
          } else {
            _largeImage = response.bodyBytes;
          }
        });
      }
    } catch (_) {
      // Image loading failure does not block notification editing.
    }
  }

  /// Saves the current notification configuration.
  Future<void> _saveAll() async {
    final data = NotificationData(
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      smallImageUrl: _smallUrlController.text.trim(),
      largeImageUrl: _largeUrlController.text.trim(),
      buttons: List<String>.of(_buttons),
    );

    await Store.instance.saveNotificationData(data);

    if (!mounted) return;

    await _load();
  }

  /// Builds and sends a test Altcraft push using saved data.
  Future<void> _sendPush() async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final data = await Store.instance.getNotificationData();

      final buttons = data.buttons.map((label) {
        return {
          'label': label,
          'link': '',
          'action': 'open app',
        };
      }).toList();

      final pushMap = <String, String>{
        '_title': data.title,
        '_body': data.body,
        '_buttons': jsonEncode(buttons),
        if (Platform.isAndroid)
          '_uid': DateTime.now().millisecondsSinceEpoch.toString(),
        if (data.smallImageUrl != null) '_icon': data.smallImageUrl!,
        if (data.largeImageUrl != null)
          (Platform.isIOS ? '_media' : '_image'): data.largeImageUrl!,
        '_ac_push': 'Altcraft',
      };

      await AltcraftPush.requestNotificationPermission();
      await AltcraftPush.takePush(pushMap);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  /// Creates the complete Example screen.
  ///
  /// Mirrors the Compose screen hierarchy:
  /// HeaderSection
  /// NotificationCard
  /// LazyColumn with settings and Send push action
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Altcraft application header.
          _header(),

          // Space above notification preview.
          const SizedBox(height: 35),

          // Notification preview stays outside the settings scroll area.
          _notificationPreview(),

          const SizedBox(height: 25),

          // Scrollable notification settings.
          Expanded(
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    0.04,
                    0.94,
                    1.0,
                  ],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView(
                padding: const EdgeInsets.only(
                  top: 12,
                  bottom: 24,
                ),
                children: [
                  _textSetting(),

                  const SizedBox(height: 16),

                  _imageSetting(),

                  const SizedBox(height: 16),

                  _buttonsSetting(),

                  const SizedBox(height: 16),

                  // Sends the configured notification.
                  _sendPill(),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates the Altcraft logo header.
  ///
  /// Corresponds to HeaderSection in Android Compose.
  Widget _header() {
    return Container(
      height: 60,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Image.asset(
        'assets/ic_altcraft.png',
        width: 80,
        height: 20,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Creates a push notification preview matching Compose NotificationCard.
  ///
  /// The small image is displayed on the right side of the title.
  /// The large image appears below the notification body.
  Widget _notificationPreview() {
    final now = DateTime.now();

    final time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              top: 15,
              right: 15,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Altcraft notification icon.
                _notificationIcon(),

                const SizedBox(width: 10),

                // Notification content.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App name and current time.
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'AltcraftMSDKv2',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Title and small notification image.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              _titleController.text.isEmpty
                                  ? kExampleTitle
                                  : _titleController.text,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          if (_smallImage != null) ...[
                            const SizedBox(width: 10),
                            _notificationSmallImage(),
                          ],

                          const SizedBox(width: 8),

                          // Small angled notification indicator.
                          Transform.translate(
                            offset: const Offset(-5, 10),
                            child: Transform.rotate(
                              angle: math.pi / 4,
                              child: const Icon(
                                Icons.chevron_right,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Notification body.
                      Text(
                        _bodyController.text.isEmpty
                            ? kExampleBody
                            : _bodyController.text,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Large notification image.
                      if (_largeImage != null) _notificationLargeImage(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notification action buttons.
          if (_largeImage != null || _buttons.isNotEmpty) ...[
            const SizedBox(height: 15),
            _notificationButtonRow(),
          ] else
            const SizedBox(height: 15),
        ],
      ),
    );
  }

  /// Creates the notification application icon.
  ///
  /// Matches Compose IconBox:
  /// 35dp white circular container with a 19dp image.
  Widget _notificationIcon() {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/ic_altcraft_push_icon.jpg',
        width: 19,
        height: 19,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Creates the small image on the right side of the title.
  Widget _notificationSmallImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.memory(
        _smallImage!,
        height: 30,
        width: 30,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Creates the large image below the notification body.
  Widget _notificationLargeImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.memory(
        _largeImage!,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }

  /// Creates horizontally distributed notification action buttons.
  ///
  /// Matches Compose NotificationButtonRow:
  /// - Height: 30dp
  /// - Horizontal padding: 10dp
  /// - Text size: 14sp
  /// - Vertical separators between buttons
  Widget _notificationButtonRow() {
    return SizedBox(
      height: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < _buttons.length; index++) ...[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _buttons[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              if (index < _buttons.length - 1)
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// Creates a settings section heading with remove and add buttons.
  ///
  /// Matches the Compose section headers used by:
  /// TextSetting, ImageSetting and ButtonsSetting.
  Widget _sectionHeader(
    String title,
    VoidCallback onRemove,
    VoidCallback onAdd,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),

              // Remove/reset button.
              _settingActionButton(
                icon: Icons.remove,
                color: Colors.black.withValues(alpha: 0.05),
                onTap: onRemove,
              ),

              const SizedBox(width: 10),

              // Save/apply button.
              _settingActionButton(
                icon: Icons.check,
                color: _kSuccessSoft.withValues(alpha: 0.4),
                onTap: onAdd,
              ),
            ],
          ),
        ),

        // Compose-style blue-to-green bottom accent.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Container(
            width: double.infinity,
            height: 3,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              gradient: LinearGradient(
                colors: [
                  Color(0x668DBFFC),
                  Color(0x1A000000),
                  Color(0x66ADF7BD),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Creates a circular button in the settings section header.
  Widget _settingActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            size: 18,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  /// Creates one labeled editable field.
  ///
  /// Corresponds to EditTextRow in Compose.
  Widget _editRow(
    String label,
    TextEditingController controller, {
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 4,
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
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
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: _kLine,
          ),
        ],
      ),
    );
  }

  /// Creates the notification text settings.
  ///
  /// Mirrors Compose TextSetting.
  Widget _textSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Text setting:',
          () async {
            setState(() {
              _titleController.text = kExampleTitle;
              _bodyController.text = kExampleBody;
            });

            await _saveAll();
          },
          () async {
            await _saveAll();
          },
        ),
        const SizedBox(height: 10),
        _editRow(
          'Title',
          _titleController,
          hint: kExampleTitle,
        ),
        const SizedBox(height: 7),
        _editRow(
          'Body',
          _bodyController,
          hint: kExampleBody,
        ),
      ],
    );
  }

  /// Creates notification image URL settings.
  ///
  /// Mirrors Compose ImageSetting.
  Widget _imageSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Image setting:',
          () async {
            setState(() {
              _smallUrlController.clear();
              _largeUrlController.clear();
              _smallImage = null;
              _largeImage = null;
            });

            await _saveAll();
          },
          () async {
            await _saveAll();
          },
        ),
        const SizedBox(height: 10),
        _editRow(
          'Small URL',
          _smallUrlController,
          hint: 'Enter small image URL',
        ),
        const SizedBox(height: 7),
        _editRow(
          'Large URL',
          _largeUrlController,
          hint: 'Enter large image URL',
        ),
      ],
    );
  }

  /// Creates editable notification action buttons.
  ///
  /// Mirrors Compose ButtonsSetting.
  ///
  /// The list contains up to three buttons.
  Widget _buttonsSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Buttons setting:',
          () async {
            setState(() {
              _buttons.clear();
            });

            await _saveAll();
          },
          () {
            if (_buttons.length >= 3) return;

            setState(() {
              _buttons.add('');
            });
          },
        ),
        const SizedBox(height: 10),
        if (_buttons.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _buttons.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _editableButtonItem(index),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  /// Creates one editable notification action button.
  ///
  /// Matches Compose EditableButtonItem:
  /// - White background
  /// - 10dp corner radius
  /// - Soft shadow
  /// - Editable label
  /// - Remove icon
  Widget _editableButtonItem(int index) {
    return Container(
      key: ValueKey('notification_button_$index'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('button_label_$index'),
                initialValue: _buttons[index],
                onChanged: (value) {
                  if (index >= _buttons.length) return;

                  _buttons[index] = value;

                  // Update the notification preview without
                  // rebuilding the active input on each keystroke.
                  if (mounted) {
                    setState(() {});
                  }
                },
                onEditingComplete: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  await _saveAll();
                },
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Button text',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                if (index >= _buttons.length) return;

                setState(() {
                  _buttons.removeAt(index);
                });

                await _saveAll();
              },
              child: const SizedBox(
                width: 20,
                height: 20,
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates the Send push action strip.
  ///
  /// Matches Compose SectionInfo(boxHeight = 30dp).
  Widget _sendPill() {
    return GestureDetector(
      onTap: _isSending ? null : _sendPush,
      child: Container(
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _kAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(5),
        ),
        alignment: Alignment.center,
        child: _isSending
            ? const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.grey,
                ),
              )
            : const Text(
                'Send push',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}
