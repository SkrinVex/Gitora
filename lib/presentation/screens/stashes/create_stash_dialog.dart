import 'package:flutter/material.dart';
import 'package:gitora/l10n/app_localizations.dart';

class CreateStashDialog extends StatefulWidget {
  const CreateStashDialog({super.key});

  @override
  State<CreateStashDialog> createState() => _CreateStashDialogState();
}

class _CreateStashDialogState extends State<CreateStashDialog> {
  final TextEditingController _messageController = TextEditingController();
  bool _includeUntracked = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.createStash),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _messageController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.stashMessage,
              hintText: 'WIP on my feature...',
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _includeUntracked,
            title: Text(l10n.includeUntracked),
            contentPadding: EdgeInsets.zero,
            onChanged: (val) =>
                setState(() => _includeUntracked = val ?? false),
          ),
        ],
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'message': _messageController.text.trim(),
              'includeUntracked': _includeUntracked,
            });
          },
          child: Text(l10n.createStash),
        ),
      ],
    );
  }
}
