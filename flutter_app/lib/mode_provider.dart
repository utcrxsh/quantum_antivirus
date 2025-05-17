import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppMode { quantum }

class ModeProvider extends ChangeNotifier {
  AppMode _mode = AppMode.quantum;
  bool _initialized = true;

  AppMode get mode => _mode;
  bool get isQuantum => true;
  bool get initialized => _initialized;

  ModeProvider();
} 