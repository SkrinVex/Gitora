import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitora/l10n/app_localizations.dart';

class CommandItem {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? shortcut;
  final VoidCallback onSelect;

  const CommandItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    this.shortcut,
    required this.onSelect,
  });
}

class CommandPalette extends StatefulWidget {
  final List<CommandItem> commands;

  const CommandPalette({super.key, required this.commands});

  static Future<void> show(BuildContext context, List<CommandItem> commands) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) => CommandPalette(commands: commands),
    );
  }

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;
  List<CommandItem> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.commands;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.commands;
      } else {
        _filtered = widget.commands.where((cmd) {
          final titleMatches = cmd.title.toLowerCase().contains(query);
          final subtitleMatches =
              cmd.subtitle?.toLowerCase().contains(query) ?? false;
          return titleMatches || subtitleMatches;
        }).toList();
      }
      _selectedIndex = 0;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 80, left: 24, right: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (_selectedIndex < _filtered.length - 1) {
                setState(() => _selectedIndex++);
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (_selectedIndex > 0) {
                setState(() => _selectedIndex--);
              }
            } else if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_filtered.isNotEmpty && _selectedIndex < _filtered.length) {
                Navigator.of(context).pop();
                _filtered[_selectedIndex].onSelect();
              }
            } else if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 460),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withAlpha(100),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search input box
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 22,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: l10n.commandPalettePlaceholder,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'ESC',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withAlpha(80),
              ),

              // Commands list
              Flexible(
                child: _filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          l10n.noCommandsFound,
                          style: TextStyle(color: theme.colorScheme.outline),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final cmd = _filtered[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              cmd.onSelect();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: isSelected
                                  ? theme.colorScheme.secondaryContainer
                                        .withAlpha(120)
                                  : null,
                              child: Row(
                                children: [
                                  Icon(
                                    cmd.icon,
                                    size: 20,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cmd.title,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? theme
                                                      .colorScheme
                                                      .onSecondaryContainer
                                                : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        if (cmd.subtitle != null)
                                          Text(
                                            cmd.subtitle!,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: theme.colorScheme.outline,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (cmd.shortcut != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        cmd.shortcut!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
