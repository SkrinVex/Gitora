import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitora/application/providers/current_repo_provider.dart';
import 'package:gitora/application/providers/git_service_provider.dart';
import 'package:gitora/application/providers/git_tasks_provider.dart';
import 'package:gitora/l10n/app_localizations.dart';

class CommitPanel extends ConsumerStatefulWidget {
  final String branchName;
  final int stagedCount;

  const CommitPanel({
    super.key,
    required this.branchName,
    required this.stagedCount,
  });

  @override
  ConsumerState<CommitPanel> createState() => _CommitPanelState();
}

class _CommitPanelState extends ConsumerState<CommitPanel> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isAmend = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final taskState = ref.watch(gitTaskProvider);
    final canCommit =
        widget.stagedCount > 0 &&
        _summaryController.text.trim().isNotEmpty &&
        !taskState.isRunning;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withAlpha(80),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Summary input
          KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter &&
                  HardwareKeyboard.instance.isControlPressed) {
                if (canCommit) _handleCommit();
              }
            },
            child: TextField(
              controller: _summaryController,
              decoration: InputDecoration(
                hintText: l10n.commitSummary,
                isDense: true,
                suffixIcon: IconButton(
                  icon: Icon(_isExpanded ? Icons.unfold_less : Icons.notes),
                  tooltip: _isExpanded
                      ? 'Collapse description'
                      : 'Add description',
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: l10n.commitDescription,
                isDense: true,
              ),
            ),
          ],

          const SizedBox(height: 10),

          Row(
            children: [
              // Amend checkbox
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => setState(() => _isAmend = !_isAmend),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _isAmend,
                        onChanged: (val) =>
                            setState(() => _isAmend = val ?? false),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text(
                        l10n.amendLastCommit,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Commit button
              FilledButton.icon(
                onPressed: canCommit ? _handleCommit : null,
                icon: const Icon(Icons.check, size: 18),
                label: Text(
                  l10n.commitToBranch(widget.branchName),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCommit() async {
    final repoPath = ref.read(currentRepoProvider);
    if (repoPath == null) return;

    final summary = _summaryController.text.trim();
    final description = _descriptionController.text.trim();
    if (summary.isEmpty || widget.stagedCount == 0) return;

    final fullMessage = description.isNotEmpty
        ? '$summary\n\n$description'
        : summary;

    final result = await ref
        .read(gitTaskProvider.notifier)
        .run<bool>(
          title: 'Creating commit',
          action: (progress) async {
            final gitService = ref.read(gitServiceProvider);
            await gitService.commit(
              repoPath,
              message: fullMessage,
              amend: _isAmend,
            );
            return true;
          },
        );

    if (result == true && mounted) {
      _summaryController.clear();
      _descriptionController.clear();
      setState(() {
        _isAmend = false;
        _isExpanded = false;
      });
    }
  }
}
