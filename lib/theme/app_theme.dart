import 'package:flutter/material.dart';

// --- Color-only themes ---
const String themeOrange = 'orange';
const String themeBlue = 'blue';
const String themeGreen = 'green';
const String themePurple = 'purple';
const String themeTeal = 'teal';

// --- Themes with distinct designs (color + shape/elevation) ---
const String themeOrangeRounded = 'orange_rounded'; // Softer, very rounded
const String themeBlueFlat = 'blue_flat'; // Flat, minimal shadows
const String themeGreenElevated = 'green_elevated'; // Strong depth, shadows
const String themeMinimal = 'minimal'; // Neutral, clean

const List<String> themeIds = [
  themeOrange,
  themeBlue,
  themeGreen,
  themePurple,
  themeTeal,
  themeOrangeRounded,
  themeBlueFlat,
  themeGreenElevated,
  themeMinimal,
];

String themeDisplayName(String id) {
  switch (id) {
    case themeOrange:
      return 'Orange';
    case themeBlue:
      return 'Blue';
    case themeGreen:
      return 'Green';
    case themePurple:
      return 'Purple';
    case themeTeal:
      return 'Teal';
    case themeOrangeRounded:
      return 'Orange (Rounded)';
    case themeBlueFlat:
      return 'Blue (Flat)';
    case themeGreenElevated:
      return 'Green (Elevated)';
    case themeMinimal:
      return 'Minimal';
    default:
      return 'Orange';
  }
}

Color themePreviewColor(String id, bool isDark) {
  switch (id) {
    case themeOrange:
    case themeOrangeRounded:
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
    case themeBlue:
    case themeBlueFlat:
      return isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
    case themeGreen:
    case themeGreenElevated:
      return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    case themePurple:
      return isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2);
    case themeTeal:
      return isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B);
    case themeMinimal:
      return isDark ? Colors.grey : Colors.grey.shade700;
    default:
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
  }
}

/// Design style: corner radius, elevation, button style.
class _Design {
  const _Design({
    required this.cardRadius,
    required this.buttonRadius,
    required this.cardElevation,
    required this.buttonElevation,
    this.outlinedButtons = false,
  });
  final double cardRadius;
  final double buttonRadius;
  final double cardElevation;
  final double buttonElevation;
  final bool outlinedButtons;
}

_Design _designFor(String themeId) {
  switch (themeId) {
    case themeOrangeRounded:
      return const _Design(
        cardRadius: 28,
        buttonRadius: 24,
        cardElevation: 2,
        buttonElevation: 1,
      );
    case themeBlueFlat:
      return const _Design(
        cardRadius: 10,
        buttonRadius: 8,
        cardElevation: 0,
        buttonElevation: 0,
        outlinedButtons: true,
      );
    case themeGreenElevated:
      return const _Design(
        cardRadius: 16,
        buttonRadius: 14,
        cardElevation: 8,
        buttonElevation: 6,
      );
    case themeMinimal:
      return const _Design(
        cardRadius: 12,
        buttonRadius: 10,
        cardElevation: 0,
        buttonElevation: 0,
        outlinedButtons: true,
      );
    default:
      return const _Design(
        cardRadius: 16,
        buttonRadius: 14,
        cardElevation: 4,
        buttonElevation: 3,
      );
  }
}

/// Returns a Future that completes when the dialog is closed.
Future<void> showThemePickerDialog(
  BuildContext context, {
  required String currentThemeId,
  required bool isDark,
  required void Function(String themeId) onThemeSelected,
}) {
  final theme = Theme.of(context);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.palette_outlined),
          SizedBox(width: 10),
          Text('Theme'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: themeIds.map((id) {
            final selected = id == currentThemeId;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: themePreviewColor(id, isDark),
                radius: 18,
              ),
              title: Text(themeDisplayName(id)),
              trailing: selected
                  ? Icon(Icons.check, color: theme.colorScheme.primary)
                  : null,
              onTap: () {
                onThemeSelected(id);
                Navigator.of(ctx).pop();
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

ThemeData getTheme(String themeId, bool isDark) {
  Color seedColor;
  switch (themeId) {
    case themeBlue:
    case themeBlueFlat:
      seedColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1976D2);
      break;
    case themeGreen:
    case themeGreenElevated:
      seedColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      break;
    case themePurple:
      seedColor = isDark ? const Color(0xFFBA68C8) : const Color(0xFF7B1FA2);
      break;
    case themeTeal:
      seedColor = isDark ? const Color(0xFF4DD0E1) : const Color(0xFF00897B);
      break;
    case themeMinimal:
      seedColor = isDark ? Colors.blueGrey : const Color(0xFF546E7A);
      break;
    case themeOrange:
    case themeOrangeRounded:
    default:
      seedColor = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      break;
  }

  final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: isDark ? Brightness.dark : Brightness.light);
  final d = _designFor(themeId);

  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    cardTheme: CardThemeData(
      elevation: d.cardElevation + (isDark ? 2 : 0),
      shadowColor: isDark ? Colors.black45 : Colors.black26,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(d.cardRadius)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: d.buttonElevation,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(d.buttonRadius)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: d.buttonElevation,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(d.buttonRadius)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(d.buttonRadius)),
      ),
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(d.cardRadius)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(d.buttonRadius)),
      filled: true,
    ),
  );
}
