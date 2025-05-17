import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scanner_service.dart';
import 'dashboard_screen.dart';
import 'scan_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'mode_provider.dart';

// --- Theme Definitions ---
final ThemeData classicTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: const Color(0xFF2EC4F1),
  scaffoldBackgroundColor: const Color(0xFF0A192F),
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2EC4F1),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFFF5F7FA),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A192F),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
  ),
  iconTheme: const IconThemeData(color: Color(0xFF2EC4F1)),
  colorScheme: ColorScheme.light(
    primary: Color(0xFF2EC4F1),
    secondary: Color(0xFF2ED47A),
    background: Color(0xFF0A192F),
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.black,
    onSurface: Colors.black,
  ),
);

final ThemeData quantumTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: const Color(0xFF7C3AED), // Deep purple
  scaffoldBackgroundColor: const Color(0xFF09090F),
  fontFamily: 'Inter',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green),
    headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
    headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.green),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.green),
    labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF18181B),
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF7C3AED),
      foregroundColor: Colors.green,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      elevation: 2,
    ),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF27272A),
    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF18181B),
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.green),
    titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
  ),
  iconTheme: const IconThemeData(color: Colors.green),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF7C3AED),
    secondary: Color(0xFF60A5FA),
    background: Color(0xFF09090F),
    surface: Color(0xFF18181B),
    onPrimary: Colors.green,
    onSecondary: Colors.green,
    onBackground: Colors.green,
    onSurface: Colors.green,
  ),
);

void main() {
  runApp(const QuantumAntivirusRoot());
}

class QuantumAntivirusRoot extends StatefulWidget {
  const QuantumAntivirusRoot({Key? key}) : super(key: key);

  @override
  State<QuantumAntivirusRoot> createState() => _QuantumAntivirusRootState();
}

class _QuantumAntivirusRootState extends State<QuantumAntivirusRoot> {
  final ModeProvider _modeProvider = ModeProvider();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _modeProvider,
      builder: (context, _) {
        if (!_modeProvider.initialized) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
            debugShowCheckedModeBanner: false,
          );
        }
        return MaterialApp(
          title: 'Quantum Antivirus',
          theme: quantumTheme,
          home: MainNavigation(modeProvider: _modeProvider),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  final ModeProvider modeProvider;
  const MainNavigation({Key? key, required this.modeProvider}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(modeProvider: widget.modeProvider),
      ScanScreen(modeProvider: widget.modeProvider),
      HistoryScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: SafeArea(child: screens[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
} 