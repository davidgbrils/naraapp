import 'package:flutter/material.dart';

void showAppSnackBar(
  BuildContext context, {
  required Widget content,
  SnackBarAction? action,
  Duration duration = const Duration(seconds: 3),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
  Color? backgroundColor,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: content,
      action: action,
      duration: duration,
      behavior: behavior,
      backgroundColor: backgroundColor,
    ),
  );
}

