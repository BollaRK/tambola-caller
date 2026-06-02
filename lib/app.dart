import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';

class PickleballApp extends StatefulWidget {
  final bool initialDark;
  final String initialThemeId;

  const PickleballApp({
    super.key,
    this.initialDark = false,
    this.initialThemeId = themeGreen,
  });

  @override
  State<PickleballApp> createState() => _PickleballAppState();
}

class _PickleballAppState extends State<PickleballApp> {
  late bool _darkMode;
  late String _themeId;
  bool _showTournament = false;
  bool _resumedTournament = false;

  @override
  void initState() {
    super.initState();
    _darkMode = widget.initialDark;
    _themeId = widget.initialThemeId;
  }

  void _setTheme(String themeId) {
    setState(() => _themeId = themeId);
    SharedPreferences.getInstance()
        .then((p) => p.setString('pickleball_theme', themeId));
  }

  void _toggleDarkMode() {
    setState(() {
      _darkMode = !_darkMode;
      SharedPreferences.getInstance()
          .then((p) => p.setBool('pickleball_dark_mode', _darkMode));
    });
  }

  void _openTournament({bool resume = false}) {
    setState(() {
      _showTournament = true;
      _resumedTournament = resume;
    });
  }

  void _closeTournament() {
    setState(() {
      _showTournament = false;
      _resumedTournament = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pickleball League',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: getTheme(_themeId, false),
      darkTheme: getTheme(_themeId, true),
      home: _showTournament
          ? GameScreen(
              resumed: _resumedTournament,
              onExit: _closeTournament,
              darkMode: _darkMode,
              onToggleDark: _toggleDarkMode,
              themeId: _themeId,
              onThemeChanged: _setTheme,
            )
          : HomeScreen(
              onNewTournament: () => _openTournament(),
              onResume: () => _openTournament(resume: true),
              darkMode: _darkMode,
              onToggleDark: _toggleDarkMode,
              themeId: _themeId,
              onThemeChanged: _setTheme,
            ),
    );
  }
}
