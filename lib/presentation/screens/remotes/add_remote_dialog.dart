import 'package:flutter/material.dart';
import 'package:gitora/l10n/app_localizations.dart';

class AddRemoteDialog extends StatefulWidget {
  const AddRemoteDialog({super.key});

  @override
  State<AddRemoteDialog> createState() => _AddRemoteDialogState();
}

class _AddRemoteDialogState extends State<AddRemoteDialog> {
  final TextEditingController _nameController = TextEditingController(
    text: 'origin',
  );
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.addRemote),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: l10n.remoteName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            decoration: InputDecoration(
              labelText: l10n.remoteUrl,
              hintText: 'https://github.com/user/repo.git',
            ),
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
            final name = _nameController.text.trim();
            final url = _urlController.text.trim();
            if (name.isNotEmpty && url.isNotEmpty) {
              Navigator.of(context).pop({'name': name, 'url': url});
            }
          },
          child: Text(l10n.addRemote),
        ),
      ],
    );
  }
}
