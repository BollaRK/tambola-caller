import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  final prefs = await SharedPreferences.getInstance();
  final dark = prefs.getBool('pickleball_dark_mode') ?? false;
  final themeId = prefs.getString('pickleball_theme') ?? 'green';
  runApp(PickleballApp(initialDark: dark, initialThemeId: themeId));
}
