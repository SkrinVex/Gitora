import 'package:flutter/material.dart';
import 'package:gitora/l10n/app_localizations.dart';

class CreateBranchDialog extends StatefulWidget {
  const CreateBranchDialog({super.key});

  @override
  State<CreateBranchDialog> createState() => _CreateBranchDialogState();
}

class _CreateBranchDialogState extends State<CreateBranchDialog> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.createBranch),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: l10n.branchName,
          hintText: 'feature/new-feature',
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop(name);
            }
          },
          child: Text(l10n.createBranch),
        ),
      ],
    );
  }
}

class RenameBranchDialog extends StatefulWidget {
  final String currentName;

  const RenameBranchDialog({super.key, required this.currentName});

  @override
  State<RenameBranchDialog> createState() => _RenameBranchDialogState();
}

class _RenameBranchDialogState extends State<RenameBranchDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.renameBranch),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.branchName),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isNotEmpty && name != widget.currentName) {
              Navigator.of(context).pop(name);
            }
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
