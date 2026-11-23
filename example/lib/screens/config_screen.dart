import 'dart:io';

import 'package:flutter/material.dart';
import 'package:altcraft_core/altcraft_core.dart';
import 'package:altcraft_sdk_example/services/sdk_tests.dart';
import 'package:altcraft_sdk_example/services/store.dart';

const _kSuccessSoft = Color(0xFFADF7BD);
const _kAccent = Color(0xFF8DBFFC);

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
  final _cFieldsController = TextEditingController();
  final _pFieldsController = TextEditingController();
  final _catsController = TextEditingController();

  List<String> _providerList = [];
  bool _sync = true;
  bool _replace = false;
  bool _skipTriggers = false;
  Map<String, String> _customFields = {};
  Map<String, String> _profileFields = {};
  List<CategoryData> _cats = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    _rTokenController.dispose();
    _jwtAnonController.dispose();
    _jwtRegController.dispose();
    _cFieldsController.dispose();
    _pFieldsController.dispose();
    _catsController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final store = Store.instance;
    final config = await store.getConfig();
    final ss = await store.getSubscribeSettings();
    final jwtAnon = await store.getJwtAnon();
    final jwtReg = await store.getJwtReg();
    if (!mounted) return;
    setState(() {
      _apiUrlController.text = config.apiUrl ?? '';
      _rTokenController.text = config.rToken ?? '';
      _providerList = List.of(config.providerPriorityList);
      _jwtAnonController.text = jwtAnon ?? '';
      _jwtRegController.text = jwtReg ?? '';
      _sync = ss.sync;
      _replace = ss.replace;
      _skipTriggers = ss.skipTriggers;
      _customFields = Map.of(ss.customFields);
      _profileFields = Map.of(ss.profileFields);
      _cats = List.of(ss.cats);
    });
  }

  List<_ProviderDef> get _providers {
    if (Platform.isIOS) {
      return [
        _ProviderDef('APNs', 'assets/ic_apns.png', kApnsProvider),
        _ProviderDef('FCM', 'assets/ic_fcm.png', kFcmProvider),
        _ProviderDef('HMS', 'assets/ic_hms.png', kHmsProvider),
      ];
    }
    return [
      _ProviderDef('FCM', 'assets/ic_fcm.png', kFcmProvider),
      _ProviderDef('HMS', 'assets/ic_hms.png', kHmsProvider),
      _ProviderDef('Rustore', 'assets/ic_rus.png', kRustoreProvider),
    ];
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }

  Future<void> _saveConfig() async {
    final apiUrl = _apiUrlController.text.trim();
    if (apiUrl.isEmpty) {
      _toast('API URL is not set');
      return;
    }
    final config = ConfigData(
      apiUrl: apiUrl,
      rToken: _rTokenController.text.trim(),
      providerPriorityList: _providerList,
    );
    await Store.instance.saveConfig(config);
    await AltcraftCore.unlockInitialOperationsInThisSession();
    await SdkTests.initializationSDK(config);
    _toast('Config saved');
  }

  Future<void> _removeConfig() async {
    final config = ConfigData();
    await Store.instance.saveConfig(config);
    if (!mounted) return;
    setState(() {
      _apiUrlController.clear();
      _rTokenController.clear();
      _providerList = [];
    });
  }

  Future<void> _saveJwt() async {
    final anon = _jwtAnonController.text.trim();
    final reg = _jwtRegController.text.trim();
    if (anon.isEmpty && reg.isEmpty) {
      _toast('At least one JWT must be set');
      return;
    }
    await Store.instance.saveJwtAnon(anon);
    await Store.instance.saveJwtReg(reg);
    _toast('JWT saved');
  }

  Future<void> _removeJwt() async {
    await Store.instance.removeJwts();
    await Store.instance.saveAuthStatus(false);
    if (!mounted) return;
    setState(() {
      _jwtAnonController.clear();
      _jwtRegController.clear();
    });
    _toast('JWT cleared');
  }

  Future<void> _saveSubscribeSettings() async {
    final settings = SubscribeSettings(
      sync: _sync,
      replace: _replace,
      skipTriggers: _skipTriggers,
      customFields: Map.of(_customFields),
      profileFields: Map.of(_profileFields),
      cats: List.of(_cats),
    );
    await Store.instance.saveSubscribeSettings(settings);
    _toast('Subscribe settings saved');
  }

  Future<void> _resetSubscribeSettings() async {
    const settings = SubscribeSettings();
    await Store.instance.saveSubscribeSettings(settings);
    if (!mounted) return;
    setState(() {
      _sync = true;
      _replace = false;
      _skipTriggers = false;
      _customFields = {};
      _profileFields = {};
      _cats = [];
      _cFieldsController.clear();
      _pFieldsController.clear();
      _catsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _header(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _configSetting(),
                  const SizedBox(height: 24),
                  _jwtSetting(),
                  const SizedBox(height: 24),
                  _subscribeSetting(),
                ],
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
        borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
        boxShadow: [
          BoxShadow(
              color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))
        ],
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Image.asset('assets/ic_altcraft.png',
          width: 80, height: 20, fit: BoxFit.contain),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onRemove, VoidCallback onAdd,
      {String? removeIdentifier, String? addIdentifier}) {
    return Row(
      children: [
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black))),
        Semantics(
          identifier: removeIdentifier,
          button: true,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.05),
              ),
              child: const Icon(Icons.remove, size: 18, color: Colors.black),
            ),
          ),
        ),
        Semantics(
          identifier: addIdentifier,
          button: true,
          child: GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSuccessSoft.withValues(alpha: 0.4),
              ),
              child: const Icon(Icons.check, size: 18, color: Colors.black),
            ),
          ),
        ),
      ],
    );
  }

  Widget _gradientDivider() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kAccent.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.1),
            _kSuccessSoft.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _editRow(String label, TextEditingController controller,
      {String? hint, String? identifier}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(label,
                    style: const TextStyle(fontSize: 10, color: Colors.black)),
              ),
              Expanded(
                child: Semantics(
                  identifier: identifier,
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }

  // ---- Config setting ----

  Widget _configSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Config setting:', _removeConfig, _saveConfig,
            removeIdentifier: 'config_clear_button',
            addIdentifier: 'config_save_button'),
        _gradientDivider(),
        _editRow('API url', _apiUrlController,
            identifier: 'config_api_url_input'),
        _editRow('RToken', _rTokenController,
            identifier: 'config_rtoken_input'),
        _providerSelectionBox(),
      ],
    );
  }

  Widget _providerSelectionBox() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Providers',
              style: TextStyle(fontSize: 8, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 1)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_providerList.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _providerList.map((p) {
                      final def = _providers.firstWhere(
                        (d) => d.constName == p,
                        orElse: () =>
                            _ProviderDef(p, 'assets/ic_menu_config.png', p),
                      );
                      return _chip(def);
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (var i = 0; i < _providers.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            final d = _providers[i];
                            if (!_providerList.contains(d.constName)) {
                              setState(() => _providerList.add(d.constName));
                            }
                          },
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 1)
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(_providers[i].icon,
                                    width: 16, height: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _providers[i].displayName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(_ProviderDef def) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 1)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(def.icon, width: 16, height: 16),
          const SizedBox(width: 4),
          Text(def.displayName,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => setState(() => _providerList.remove(def.constName)),
            child: const Icon(Icons.close, size: 14, color: Colors.black),
          ),
        ],
      ),
    );
  }

  // ---- JWT setting ----

  Widget _jwtSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('JWT setting:', _removeJwt, _saveJwt,
            removeIdentifier: 'jwt_clear_button',
            addIdentifier: 'jwt_save_button'),
        _gradientDivider(),
        _editRow('Anon.JWT', _jwtAnonController,
            hint: _jwtHint(_jwtAnonController.text),
            identifier: 'jwt_anon_input'),
        _editRow('Reg.JWT', _jwtRegController,
            hint: _jwtHint(_jwtRegController.text),
            identifier: 'jwt_reg_input'),
      ],
    );
  }

  String? _jwtHint(String jwt) {
    if (jwt.length < 40) return null;
    return '${jwt.substring(0, 17)}...${jwt.substring(jwt.length - 17)}';
  }

  // ---- Subscribe setting ----

  Widget _subscribeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Subscribe setting:', _resetSubscribeSettings,
            _saveSubscribeSettings),
        _gradientDivider(),
        _switchRow('sync', 'It is necessary to give a synchronous response',
            _sync, (v) => setState(() => _sync = v)),
        _switchRow('replace', 'Suspends other subscriptions in the database',
            _replace, (v) => setState(() => _replace = v)),
        _switchRow('skipTriggers', 'An instruction to ignore company triggers',
            _skipTriggers, (v) => setState(() => _skipTriggers = v)),
        const Padding(
          padding: EdgeInsets.only(top: 14, bottom: 8),
          child: Text('Fields & Cats values:',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black)),
        ),
        _fieldsSection('C.Fields', _cFieldsController, _customFields, (k, v) {
          setState(() => _customFields[k] = v);
        }, (k) {
          setState(() => _customFields.remove(k));
        }),
        const SizedBox(height: 10),
        _fieldsSection('P.Fields', _pFieldsController, _profileFields, (k, v) {
          setState(() => _profileFields[k] = v);
        }, (k) {
          setState(() => _profileFields.remove(k));
        }),
        const SizedBox(height: 10),
        _catsSection(),
      ],
    );
  }

  Widget _switchRow(
      String label, String hint, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 60,
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: value ? _kSuccessSoft : _kAccent,
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black,
                        border: Border.all(
                          color: value ? _kSuccessSoft : _kAccent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.black)),
                Text(hint,
                    style: const TextStyle(fontSize: 9.5, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldsSection(
    String label,
    TextEditingController controller,
    Map<String, String> fields,
    void Function(String, String) onAdd,
    void Function(String) onRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editRow(label, controller, hint: 'Key=Value'),
        if (fields.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08), blurRadius: 1)
              ],
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: fields.keys.map((k) {
                return Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(k,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => onRemove(k),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _addKeyValueBox((k, v) => onAdd(k, v)),
        ),
      ],
    );
  }

  Widget _addKeyValueBox(void Function(String, String) onAdd) {
    final keyController = TextEditingController();
    final valueController = TextEditingController();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: keyController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Key',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: valueController,
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Value',
                hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              final k = keyController.text.trim();
              final v = valueController.text.trim();
              if (k.isNotEmpty && v.isNotEmpty) onAdd(k, v);
              keyController.clear();
              valueController.clear();
            },
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.only(left: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kSuccessSoft.withValues(alpha: 0.4),
              ),
              child: const Icon(Icons.add, size: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _editRow('Cats', _catsController, hint: 'Category name'),
        if (_cats.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08), blurRadius: 1)
              ],
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _cats.map((c) {
                return Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.name ?? '',
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _cats.remove(c)),
                        child: const Icon(Icons.close,
                            size: 13, color: Colors.black),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _catsController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    hintText: 'Category name',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final name = _catsController.text.trim();
                  if (name.isNotEmpty) {
                    setState(() {
                      _cats.add(CategoryData(name: name));
                      _catsController.clear();
                    });
                  }
                },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kSuccessSoft.withValues(alpha: 0.4),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderDef {
  final String displayName;
  final String icon;
  final String constName;

  const _ProviderDef(this.displayName, this.icon, this.constName);
}
