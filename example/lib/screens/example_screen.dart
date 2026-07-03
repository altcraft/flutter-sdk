import 'package:flutter/material.dart';
import 'package:altcraft_sdk/altcraft_sdk.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({super.key});

  @override
  State<ExampleScreen> createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _buttonsController = TextEditingController();
  final _acKeyController = TextEditingController(text: '_ac_push');
  final _acValueController = TextEditingController(text: '1');
  String _result = '';

  final _cardShadow = [
    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4)),
  ];

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: _cardShadow),
      child: child,
    );
  }

  Future<void> _sendPush() async {
    final msg = <String, String>{};
    if (_acKeyController.text.trim().isNotEmpty) msg[_acKeyController.text.trim()] = _acValueController.text.trim();
    if (_titleController.text.trim().isNotEmpty) msg['title'] = _titleController.text.trim();
    if (_bodyController.text.trim().isNotEmpty) msg['body'] = _bodyController.text.trim();
    if (_imageUrlController.text.trim().isNotEmpty) msg['image_url'] = _imageUrlController.text.trim();
    if (_buttonsController.text.trim().isNotEmpty) msg['buttons'] = _buttonsController.text.trim();

    AltcraftSDK.takePush(msg);
    setState(() => _result = 'Sent: $msg');
  }

  Future<void> _checkPush() async {
    final msg = <String, String>{};
    if (_acKeyController.text.trim().isNotEmpty) msg[_acKeyController.text.trim()] = _acValueController.text.trim();
    final isAlt = await AltcraftSDK.isAltcraftPush(msg);
    setState(() => _result = 'isAltcraftPush: $isAlt');
  }

  List<String> get _btnList => _buttonsController.text.trim().isEmpty ? [] : _buttonsController.text.trim().split(',').map((b) => b.trim()).where((b) => b.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titleController.text.isEmpty ? 'Notification Title' : _titleController.text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(_bodyController.text.isEmpty ? 'Notification body text...' : _bodyController.text, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                if (_imageUrlController.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(_imageUrlController.text.trim(), height: 120, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.grey[200]))),
                ],
                if (_btnList.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: _btnList.map((b) {
                      return _buildCard(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Text(b, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black)),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // Push Settings
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Push Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Title', isDense: true)),
                const SizedBox(height: 4),
                TextField(controller: _bodyController, decoration: const InputDecoration(hintText: 'Body', isDense: true), maxLines: 2),
                const SizedBox(height: 4),
                TextField(controller: _imageUrlController, decoration: const InputDecoration(hintText: 'Image URL', isDense: true)),
                const SizedBox(height: 4),
                TextField(controller: _buttonsController, decoration: const InputDecoration(hintText: 'Buttons (comma-separated)', isDense: true)),
              ],
            ),
          ),

          // Altcraft Key
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Altcraft Push Key', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _acKeyController, decoration: const InputDecoration(hintText: 'Key', isDense: true))),
                    const SizedBox(width: 4),
                    Expanded(child: TextField(controller: _acValueController, decoration: const InputDecoration(hintText: 'Value', isDense: true))),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            children: [
              Expanded(child: _buildCard(child: _buildSubButton('Send Push', Colors.white, onTap: _sendPush))),
              const SizedBox(width: 8),
              Expanded(child: _buildCard(child: _buildSubButton('Check', const Color(0xFFADF7BD), onTap: _checkPush))),
            ],
          ),

          if (_result.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_result, style: const TextStyle(fontFamily: 'Menlo', fontSize: 11, color: Color(0xFF666666))),
          ],
        ],
      ),
    );
  }

  Widget _buildSubButton(String text, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black)),
      ),
    );
  }
}
