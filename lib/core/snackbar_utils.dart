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

void showDeleteSnackBarWithDelayedUndo(
  BuildContext context, {
  required Widget deletedContent,
  Widget? undoContent,
  required String undoLabel,
  required VoidCallback onUndo,
  Duration deletedDuration = const Duration(seconds: 2),
  Duration undoDuration = const Duration(seconds: 4),
  SnackBarBehavior behavior = SnackBarBehavior.floating,
  Color? backgroundColor,
  Color? undoTextColor,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  var undoVisible = false;
  messenger.showSnackBar(
    SnackBar(
      content: deletedContent,
      duration: deletedDuration,
      behavior: behavior,
      backgroundColor: backgroundColor,
    ),
  );
  Future.delayed(deletedDuration, () {
    if (!context.mounted) return;
    final mountedMessenger = ScaffoldMessenger.maybeOf(context);
    if (mountedMessenger == null) return;
    mountedMessenger.hideCurrentSnackBar();
    undoVisible = true;
    mountedMessenger.showSnackBar(
      SnackBar(
        content: undoContent ?? const Text('Batalkan penghapusan?'),
        duration: undoDuration,
        behavior: behavior,
        backgroundColor: backgroundColor,
        action: SnackBarAction(
          label: undoLabel,
          textColor: undoTextColor,
          onPressed: () {
            undoVisible = false;
            mountedMessenger.hideCurrentSnackBar();
            onUndo();
          },
        ),
      ),
    );
    Future.delayed(undoDuration, () {
      if (!context.mounted || !undoVisible) return;
      final dismissMessenger = ScaffoldMessenger.maybeOf(context);
      dismissMessenger?.hideCurrentSnackBar();
      undoVisible = false;
    });
  });
}
