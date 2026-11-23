import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:altcraft_inapp/altcraft_inapp.dart';
import 'package:altcraft_sdk_example/screens/home_screen.dart';
import 'package:altcraft_sdk_example/screens/logs_screen.dart';
import 'package:altcraft_sdk_example/screens/config_screen.dart';
import 'package:altcraft_sdk_example/screens/example_screen.dart';
import 'package:altcraft_sdk_example/screens/inapp_screen.dart';
import 'package:altcraft_sdk_example/services/app_state.dart';
import 'package:altcraft_sdk_example/services/event_bus.dart';
import 'package:altcraft_sdk_example/services/sdk_tests.dart';
import 'package:altcraft_sdk_example/services/store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Android status and navigation bars.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize application event handling.
  EventBus.instance.init();

  // Connect SDK token updates to the application state.
  AppStateHolder.bind(AppState.instance.updateTokenUi);

  // Initialize the SDK using the saved configuration.
  unawaited(_bootstrap());

  runApp(const AltcraftExampleApp());
}

/// Initializes the SDK with the configuration saved on the Config screen.
Future<void> _bootstrap() async {
  await AppState.instance.init();

  final config = await Store.instance.getConfig();

  if (config.apiUrl?.trim().isNotEmpty ?? false) {
    try {
      await SdkTests.initializationSDK(config);
    } catch (_) {
      // SDK initialization errors are handled by the event system.
    }
  }
}

/// Root application widget.
class AltcraftExampleApp extends StatelessWidget {
  const AltcraftExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AltcraftFlutter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

/// Main application navigation container.
///
/// All five screens remain mounted in IndexedStack.
/// Switching tabs does not recreate their widget state.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  /// Screens displayed by the bottom navigation menu.
  final List<Widget> _screens = const [
    HomeScreen(),
    ExampleScreen(),
    LogsScreen(),
    InAppScreen(),
    ConfigScreen(),
  ];

  /// Original Android Compose navigation icons.
  static const List<String> _icons = [
    'assets/ic_menu_home.png',
    'assets/ic_menu_example.png',
    'assets/ic_menu_log.png',
    'assets/ic_in_app.png',
    'assets/ic_menu_config.png',
  ];

  /// Navigation labels matching Android UIMenu.
  static const List<String> _labels = [
    'Home',
    'Example',
    'Logs',
    'InApp',
    'Config',
  ];

  /// Handles tab navigation and SDK screen tracking.
  ///
  /// Home and InApp notify the SDK when opened,
  /// matching the original Android navigation behavior.
  void _onTabTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      AltcraftInApp.setScreen('home');
    } else if (index == 3) {
      AltcraftInApp.setScreen('inapp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Keep the content below the system status bar.
      body: SafeArea(
        top: true,
        bottom: false,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),

      // Bottom navigation matching Android Compose UIMenu.
      bottomNavigationBar: _bottomNavigationBar(context),
    );
  }

  /// Creates the bottom navigation bar.
  ///
  /// Solid white background without gradient, shadow or transparency.
  Widget _bottomNavigationBar(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _icons.length,
            (index) => _navigationButton(
              icon: _icons[index],
              label: _labels[index],
              onTap: () => _onTabTap(index),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates one bottom navigation button.
  ///
  /// Matches Android Compose NavigationButton:
  /// - 8dp internal padding
  /// - 23dp image
  /// - 10sp text
  /// - Centered vertical alignment
  ///
  /// Images always retain their original colors.
  /// Inactive tabs do not use reduced opacity.
  Widget _navigationButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Original Android navigation icon size.
              Image.asset(
                icon,
                width: 23,
                height: 23,
                fit: BoxFit.contain,
              ),

              // Android places the label immediately below the icon.
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
