import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:gitora/l10n/app_localizations.dart';

class CloneRepoDialog extends StatefulWidget {
  const CloneRepoDialog({super.key});

  @override
  State<CloneRepoDialog> createState() => _CloneRepoDialogState();
}

class _CloneRepoDialogState extends State<CloneRepoDialog> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _pathController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.cloneRepository),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Repository URL (HTTPS or SSH)',
                hintText: 'https://github.com/user/project.git',
              ),
              onChanged: (val) {
                if (_pathController.text.isEmpty && val.isNotEmpty) {
                  final segments = val.split('/');
                  if (segments.isNotEmpty) {
                    final last = segments.last.replaceAll('.git', '');
                    if (last.isNotEmpty) {
                      // Suggested directory name
                    }
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Directory',
                      hintText: 'C:\\Users\\...\\project',
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
            final url = _urlController.text.trim();
            final path = _pathController.text.trim();
            if (url.isNotEmpty && path.isNotEmpty) {
              Navigator.of(context).pop({'url': url, 'path': path});
            }
          },
          child: Text(l10n.cloneRepository),
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
