import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/game_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onNewTournament;
  final VoidCallback onResume;
  final bool darkMode;
  final VoidCallback onToggleDark;
  final String themeId;
  final void Function(String) onThemeChanged;

  const HomeScreen({
    super.key,
    required this.onNewTournament,
    required this.onResume,
    required this.darkMode,
    required this.onToggleDark,
    required this.themeId,
    required this.onThemeChanged,
  });

  Future<void> _confirmNewTournament(BuildContext context) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.sports_tennis,
            color: Theme.of(ctx).colorScheme.primary, size: 42),
        title: const Text('Start new tournament?'),
        content: const Text(
          'This creates a fresh pickleball tournament. Any saved tournament can be replaced after you continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.add),
            label: const Text('Start'),
          ),
        ],
      ),
    );
    if (start == true) {
      onNewTournament();
    }
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              foregroundColor: theme.colorScheme.onPrimaryContainer,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withValues(alpha: 0.97),
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.15),
                  ]
                : [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                    theme.colorScheme.surface,
                    theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  'Pickleball League',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  IconButton(
                    icon: Icon(Icons.palette_outlined,
                        color: theme.colorScheme.primary),
                    onPressed: () => showThemePickerDialog(
                      context,
                      currentThemeId: themeId,
                      isDark: darkMode,
                      onThemeSelected: onThemeChanged,
                    ),
                    tooltip: 'Theme',
                  ),
                  IconButton(
                    icon: Icon(darkMode ? Icons.dark_mode : Icons.light_mode),
                    onPressed: onToggleDark,
                    tooltip: darkMode ? 'Light mode' : 'Dark mode',
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<bool>(
                  future: GameService().loadGame().then((s) => s != null),
                  builder: (context, snapshot) {
                    final canResume = snapshot.data == true;
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Title card
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 32, vertical: 28),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface
                                        .withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.sports_tennis,
                                          size: 56,
                                          color: theme.colorScheme.primary),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Pickleball',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'League Tournament',
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Enter players, choose partners, score every league match, and let the app advance qualifiers into quarters, semis, and the final.',
                                        style: theme.textTheme.bodyLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildFeatureCard(
                              context,
                              icon: Icons.groups,
                              title: 'Create doubles teams',
                              subtitle:
                                  'Add player names and select partners before play starts.',
                            ),
                            _buildFeatureCard(
                              context,
                              icon: Icons.table_chart,
                              title: 'Round-robin league',
                              subtitle:
                                  'Every team plays each other once, with standings sorted automatically.',
                            ),
                            _buildFeatureCard(
                              context,
                              icon: Icons.emoji_events,
                              title: 'Automatic knockouts',
                              subtitle:
                                  'Top teams advance to finals, semis, or quarters based on team count.',
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () => _confirmNewTournament(context),
                              icon: const Icon(Icons.add_circle_outline,
                                  size: 26),
                              label: const Text('New Tournament'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 18),
                                textStyle: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w600),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                            ),
                            if (canResume) ...[
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => onResume(),
                                icon: const Icon(Icons.play_arrow, size: 24),
                                label: const Text('Resume Tournament'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 18),
                                  textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500),
                                  side: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2),
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                            TextButton.icon(
                              onPressed: () async {
                                final exit = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Close app?'),
                                    content: const Text(
                                        'Do you want to exit Pickleball League?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(true),
                                        child: const Text('Exit'),
                                      ),
                                    ],
                                  ),
                                );
                                if (exit == true) SystemNavigator.pop();
                              },
                              icon: Icon(Icons.logout_rounded,
                                  size: 22, color: theme.colorScheme.error),
                              label: Text('Exit',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.error)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
