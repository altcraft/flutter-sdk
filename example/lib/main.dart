import 'package:flutter/material.dart';
import 'package:altcraft_sdk_example/screens/home_screen.dart';
import 'package:altcraft_sdk_example/screens/logs_screen.dart';
import 'package:altcraft_sdk_example/screens/config_screen.dart';
import 'package:altcraft_sdk_example/screens/example_screen.dart';
import 'package:altcraft_sdk_example/services/event_bus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();
  EventBus.instance.init();
  runApp(const AltcraftExampleApp());
}

class AltcraftExampleApp extends StatelessWidget {
  const AltcraftExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Altcraft Flutter SDK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LogsScreen(),
    ConfigScreen(),
    ExampleScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/ic_altcraft.png',
              height: 22,
              width: 84,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            const Text(
              'Flutter',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFF666666),
        backgroundColor: Colors.white,
        elevation: 0,
        iconSize: 23,
        items: [
          BottomNavigationBarItem(
            icon: Image(image: AssetImage('assets/tabs/ic_menu_home.png'), width: 23, height: 23),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Image(image: AssetImage('assets/tabs/ic_menu_log.png'), width: 23, height: 23),
            label: 'Logs',
          ),
          BottomNavigationBarItem(
            icon: Image(image: AssetImage('assets/tabs/ic_menu_config.png'), width: 23, height: 23),
            label: 'Config',
          ),
          BottomNavigationBarItem(
            icon: Image(image: AssetImage('assets/tabs/ic_menu_example.png'), width: 23, height: 23),
            label: 'Example',
          ),
        ],
      ),
    );
  }
}
