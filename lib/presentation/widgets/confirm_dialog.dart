import 'package:flutter/material.dart';
import 'package:gitora/l10n/app_localizations.dart';

enum ConfirmDialogType { normal, warning, danger }

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? confirmLabel;
  final String? cancelLabel;
  final ConfirmDialogType type;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel,
    this.cancelLabel,
    this.type = ConfirmDialogType.normal,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
    ConfirmDialogType type = ConfirmDialogType.normal,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Color buttonColor = theme.colorScheme.primary;
    IconData icon = Icons.info_outline;

    if (type == ConfirmDialogType.warning) {
      buttonColor = Colors.amber.shade800;
      icon = Icons.warning_amber_rounded;
    } else if (type == ConfirmDialogType.danger) {
      buttonColor = theme.colorScheme.error;
      icon = Icons.dangerous_outlined;
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(icon, color: buttonColor, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        ],
      ),
      content: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel ?? l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel ?? l10n.confirm),
        ),
      ],
    );
  }
}
