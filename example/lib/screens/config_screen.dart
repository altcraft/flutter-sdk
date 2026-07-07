import 'package:flutter/material.dart';
import 'package:altcraft_sdk/altcraft_sdk.dart';
import 'package:altcraft_sdk_example/services/store.dart';
import 'package:altcraft_sdk_example/services/sdk_tests.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _apiUrlController = TextEditingController();
  final _rTokenController = TextEditingController();
  final _jwtAnonController = TextEditingController();
  final _jwtRegController = TextEditingController();

  late ConfigData _config;
  bool _sync = true;
  bool _replace = false;
  bool _skipTriggers = false;
  final Map<String, String> _customFields = {};
  final Map<String, String> _profileFields = {};
  final List<String> _categories = [];
  final List<String> _providers = [];

  final _cfKeyController = TextEditingController();
  final _cfValueController = TextEditingController();
  final _pfKeyController = TextEditingController();
  final _pfValueController = TextEditingController();
  final _catController = TextEditingController();

  final androidProviders = ['android-firebase', 'android-huawei', 'android-rustore'];
  final iosProviders = ['ios-apns', 'ios-firebase', 'ios-huawei'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _config = await Store.instance.getConfig();
    _apiUrlController.text = _config.apiUrl;
    _rTokenController.text = _config.effectiveRToken ?? kDefaultRToken;
    _providers.addAll(_config.providerPriorityList);
    _jwtAnonController.text = await Store.instance.getJwtAnon();
    _jwtRegController.text = await Store.instance.getJwtReg();
    final ss = await Store.instance.getSubscribeSettings();
    setState(() {
      _sync = ss.sync;
      _replace = ss.replace;
      _skipTriggers = ss.skipTriggers;
      _customFields.addAll(ss.customFields);
      _profileFields.addAll(ss.profileFields);
      _categories.addAll(ss.cats.map((c) => c.name ?? ''));
    });
  }

  Future<void> _saveConfig() async {
    final newConfig = ConfigData(
      apiUrl: _apiUrlController.text.trim().isEmpty ? _config.apiUrl : _apiUrlController.text.trim(),
      rToken: _rTokenController.text.trim().isEmpty ? null : _rTokenController.text.trim(),
      providerPriorityList: List.from(_providers),
    );
    _config = newConfig;
    await Store.instance.saveConfig(newConfig);
    await AltcraftSDK.unlockInitialOperationsInThisSession();
    await SdkTests.initializationSDK(newConfig);
  }

  Future<void> _clearConfig() async {
    final reset = ConfigData(apiUrl: '', rToken: null, providerPriorityList: []);
    setState(() {
      _config = reset;
      _apiUrlController.clear();
      _rTokenController.clear();
      _providers.clear();
    });
    await Store.instance.saveConfig(reset);
  }

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

  @override
  Widget build(BuildContext context) {
    final availableProviders = Theme.of(context).platform == TargetPlatform.android ? androidProviders : iosProviders;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Config
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Config', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(controller: _apiUrlController, decoration: const InputDecoration(hintText: 'API URL', isDense: true)),
                const SizedBox(height: 4),
                TextField(controller: _rTokenController, decoration: const InputDecoration(hintText: 'RToken', isDense: true)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  children: availableProviders.map((p) {
                    final active = _providers.contains(p);
                    return InkWell(
                      onTap: () => setState(() => active ? _providers.remove(p) : _providers.add(p)),
                      borderRadius: BorderRadius.circular(10),
                      child: _buildCard(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: active ? Colors.white : Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Text(p, style: TextStyle(fontSize: 11, fontFamily: 'Menlo', fontWeight: active ? FontWeight.w700 : FontWeight.normal, color: Colors.black)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildSubButton('Save', const Color(0xFF8DBFFC).withOpacity(0.4), onTap: _saveConfig)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSubButton('Clear', const Color(0xFFCCCCCC), onTap: _clearConfig)),
                  ],
                ),
              ],
            ),
          ),

          // JWT
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JWT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                TextField(controller: _jwtAnonController, decoration: const InputDecoration(hintText: 'Anon JWT', isDense: true), maxLines: 2),
                const SizedBox(height: 4),
                TextField(controller: _jwtRegController, decoration: const InputDecoration(hintText: 'Registered JWT', isDense: true), maxLines: 2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubButton('Save', const Color(0xFF8DBFFC).withOpacity(0.4), onTap: () async {
                        await Store.instance.saveJwtAnon(_jwtAnonController.text);
                        await Store.instance.saveJwtReg(_jwtRegController.text);
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSubButton('Clear', const Color(0xFFCCCCCC), onTap: () async {
                        setState(() {
                          _jwtAnonController.clear();
                          _jwtRegController.clear();
                        });
                        await Store.instance.saveJwtAnon('');
                        await Store.instance.saveJwtReg('');
                        await Store.instance.saveAuthStatus(false);
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Subscribe Settings
          _buildCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subscribe Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ToggleListTile(title: 'Sync', value: _sync, onChanged: (v) => setState(() => _sync = v)),
                ToggleListTile(title: 'Replace', value: _replace, onChanged: (v) => setState(() => _replace = v)),
                ToggleListTile(title: 'Skip Triggers', value: _skipTriggers, onChanged: (v) => setState(() => _skipTriggers = v)),
                const SizedBox(height: 8),
                const Text('Custom Fields', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                _buildFieldList(_customFields, _cfKeyController, _cfValueController, onAdd: () {
                  if (_cfKeyController.text.trim().isEmpty) return;
                  setState(() {
                    _customFields[_cfKeyController.text.trim()] = _cfValueController.text.trim();
                    _cfKeyController.clear();
                    _cfValueController.clear();
                  });
                }),
                const Text('Profile Fields', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                _buildFieldList(_profileFields, _pfKeyController, _pfValueController, onAdd: () {
                  if (_pfKeyController.text.trim().isEmpty) return;
                  setState(() {
                    _profileFields[_pfKeyController.text.trim()] = _pfValueController.text.trim();
                    _pfKeyController.clear();
                    _pfValueController.clear();
                  });
                }),
                const Text('Categories', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                _buildCategoryList(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildSubButton('Save', const Color(0xFF8DBFFC).withOpacity(0.4), onTap: () => Store.instance.saveSubscribeSettings(SubscribeSettings(
                        sync: _sync, replace: _replace, skipTriggers: _skipTriggers,
                        customFields: Map.from(_customFields), profileFields: Map.from(_profileFields),
                        cats: _categories.map((c) => CategoryData(name: c)).toList(),
                      ))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSubButton('Clear', const Color(0xFFCCCCCC), onTap: () {
                        setState(() {
                          _sync = true; _replace = false; _skipTriggers = false;
                          _customFields.clear(); _profileFields.clear(); _categories.clear();
                        });
                        Store.instance.saveSubscribeSettings(SubscribeSettings());
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubButton(String text, Color color, {VoidCallback? onTap}) {
    return _buildCard(
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 10), alignment: Alignment.center,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildFieldList(Map<String, String> fields, TextEditingController keyCtrl, TextEditingController valueCtrl, {required VoidCallback onAdd}) {
    return Column(
      children: [
        for (var entry in fields.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildCard(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${entry.key} = ${entry.value}', style: const TextStyle(fontSize: 11, fontFamily: 'Menlo')),
                  TextButton(onPressed: () => setState(() => fields.remove(entry.key)), child: const Text('✕', style: TextStyle(color: Color(0xFFFF6E7F)))),
                ],
              ),
            ),
          ),
        Row(children: [
          Expanded(child: TextField(controller: keyCtrl, decoration: const InputDecoration(hintText: 'Key', isDense: true))),
          const SizedBox(width: 4),
          Expanded(child: TextField(controller: valueCtrl, decoration: const InputDecoration(hintText: 'Value', isDense: true))),
          const SizedBox(width: 4),
          _buildCard(child: IconButton(icon: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), onPressed: onAdd)),
        ]),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Column(
      children: [
        for (var i = 0; i < _categories.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: _buildCard(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_categories[i], style: const TextStyle(fontSize: 11, fontFamily: 'Menlo')),
                  TextButton(onPressed: () => setState(() => _categories.removeAt(i)), child: const Text('✕', style: TextStyle(color: Color(0xFFFF6E7F)))),
                ],
              ),
            ),
          ),
        Row(children: [
          Expanded(child: TextField(controller: _catController, decoration: const InputDecoration(hintText: 'Category name', isDense: true))),
          const SizedBox(width: 4),
          _buildCard(child: IconButton(icon: const Text('+', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), onPressed: () {
            if (_catController.text.trim().isEmpty) return;
            setState(() {
              _categories.add(_catController.text.trim());
              _catController.clear();
            });
          })),
        ]),
      ],
    );
  }
}

class ToggleListTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleListTile({super.key, required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Container(
              width: 40, height: 22,
              decoration: BoxDecoration(
                color: value ? const Color(0xFFADF7BD) : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(width: 18, height: 18, margin: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
