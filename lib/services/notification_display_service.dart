import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NotificationDisplayService {
  // Affiche notification
  static Future<void> showNotification(
      BuildContext context, {
        required String title,
        required String body,
      }) async {
    // Web ou Desktop
    if (kIsWeb || (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title\n$body'),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      // Mobile → utiliser un dialogue simple
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }

  static Future<void> init() async {}
}