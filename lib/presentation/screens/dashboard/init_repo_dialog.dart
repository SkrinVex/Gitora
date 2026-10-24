import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gitora/l10n/app_localizations.dart';

class InitRepoDialog extends StatefulWidget {
  const InitRepoDialog({super.key});

  @override
  State<InitRepoDialog> createState() => _InitRepoDialogState();
}

class _InitRepoDialogState extends State<InitRepoDialog> {
  final TextEditingController _pathController = TextEditingController();

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.newRepository),
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select an existing directory on your computer to initialize as a new Git repository.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Directory Path',
                      hintText: 'C:\\Users\\...\\my-repo',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _browseFolder,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final path = _pathController.text.trim();
            if (path.isNotEmpty) {
              Navigator.of(context).pop(path);
            }
          },
          child: Text(l10n.newRepository),
        ),
      ],
    );
  }

  Future<void> _browseFolder() async {
    final path = await FilePicker.getDirectoryPath();
    if (path != null) {
      _pathController.text = path;
    }
  }
}
