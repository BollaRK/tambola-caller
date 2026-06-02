import 'package:flutter/material.dart';

/// Shows a friendly dialog explaining how to cast the app to a TV.
/// Returns a Future that completes when the dialog is closed.
Future<void> showCastDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(Icons.cast_connected,
          size: 48, color: Theme.of(ctx).colorScheme.primary),
      title: const Text('Cast to TV'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This button does not start casting by itself. Use your device\'s built-in casting to mirror the app to your TV:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text('• Android: Swipe down → tap Cast or Screen cast'),
            SizedBox(height: 4),
            Text(
                '• iPhone / iPad: Swipe down → tap Screen Mirroring → choose your TV'),
            SizedBox(height: 4),
            Text('• Windows: Settings → System → Projecting to this PC'),
            SizedBox(height: 16),
            Text(
              'This screen is designed with large numbers and a clean layout so it looks great on the big screen!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Got it'),
        ),
      ],
    ),
  );
}
