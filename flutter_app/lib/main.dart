import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'service.dart';
import 'screens.dart';

void main() {
  runApp(const JoplinWebApp());
}

class JoplinWebApp extends StatelessWidget {
  const JoplinWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => JoplinService()..loadData(),
      child: MaterialApp(
        title: 'Joplin Web',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const MainLayout(),
      ),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Menu bar
          _MenuBar(),
          // Main content
          const Expanded(child: HomeScreen()),
        ],
      ),
    );
  }
}

class _MenuBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: Colors.grey[200],
      child: Row(
        children: [
          _MenuButton(
            label: 'File',
            items: [
              PopupMenuItem(
                child: const Text('Import Markdown (.md)'),
                onTap: () => _importMarkdown(context),
              ),
              PopupMenuItem(
                child: const Text('Import Joplin Export (.jex)'),
                onTap: () => _importJex(context),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('Export Note as Markdown'),
                onTap: () => _exportMarkdown(context),
              ),
            ],
          ),
          _MenuButton(
            label: 'Edit',
            items: [
              PopupMenuItem(
                child: const Text('New Note'),
                onTap: () {
                  context.read<JoplinService>().createNote();
                },
              ),
              PopupMenuItem(
                child: const Text('New Notebook'),
                onTap: () => _showNewNotebookDialog(context),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_bold, size: 18),
                    SizedBox(width: 8),
                    Text('Bold'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertBold(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_italic, size: 18),
                    SizedBox(width: 8),
                    Text('Italic'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertItalic(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_underlined, size: 18),
                    SizedBox(width: 8),
                    Text('Underline'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertUnderline(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_strikethrough, size: 18),
                    SizedBox(width: 8),
                    Text('Strikethrough'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertStrikethrough(),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.code, size: 18),
                    SizedBox(width: 8),
                    Text('Inline Code'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertInlineCode(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.integration_instructions, size: 18),
                    SizedBox(width: 8),
                    Text('Code Block'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertCodeBlock(),
              ),
            ],
          ),
          _MenuButton(
            label: 'Format',
            items: [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.title, size: 18),
                    SizedBox(width: 8),
                    Text('Heading 1'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertHeading1(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.title, size: 16),
                    SizedBox(width: 8),
                    Text('Heading 2'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertHeading2(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.title, size: 14),
                    SizedBox(width: 8),
                    Text('Heading 3'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertHeading3(),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_list_bulleted, size: 18),
                    SizedBox(width: 8),
                    Text('Bullet List'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertBulletList(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_list_numbered, size: 18),
                    SizedBox(width: 8),
                    Text('Numbered List'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertNumberedList(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.check_box, size: 18),
                    SizedBox(width: 8),
                    Text('Task List'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertTaskList(),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.format_quote, size: 18),
                    SizedBox(width: 8),
                    Text('Quote'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertQuote(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.horizontal_rule, size: 18),
                    SizedBox(width: 8),
                    Text('Horizontal Rule'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertHorizontalRule(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.table_chart, size: 18),
                    SizedBox(width: 8),
                    Text('Insert Table'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertTable(),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.link, size: 18),
                    SizedBox(width: 8),
                    Text('Insert Link'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertLink(),
              ),
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.image, size: 18),
                    SizedBox(width: 8),
                    Text('Insert Image'),
                  ],
                ),
                onTap: () => editorKey.currentState?.insertImage(),
              ),
            ],
          ),
          _MenuButton(
            label: 'Help',
            items: [
              PopupMenuItem(
                child: const Text('View Import Log'),
                onTap: () => _showDebugLog(context),
              ),
              PopupMenuItem(
                child: const Text('Download Debug Log'),
                onTap: () => _downloadDebugLog(context),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                child: const Text('Keyboard Shortcuts'),
                onTap: () => _showKeyboardShortcuts(context),
              ),
              PopupMenuItem(
                child: const Text('About'),
                onTap: () => _showAbout(context),
              ),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Joplin Web',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _importMarkdown(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        final content = utf8.decode(file.bytes!);
        if (context.mounted) {
          context.read<JoplinService>().importMarkdownFile(
                file.name,
                content,
              );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported: ${file.name}')),
          );
        }
      }
    }
  }

  void _importJex(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jex'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null && context.mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Importing JEX file...'),
              ],
            ),
          ),
        );

        final service = context.read<JoplinService>();
        final stats = await service.importJexFile(file.bytes!);

        if (context.mounted) {
          Navigator.pop(context); // Close loading dialog

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Import Complete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notebooks imported: ${stats['notebooks']}'),
                  Text('Notes imported: ${stats['notes']}'),
                  if (stats['errors']! > 0)
                    Text(
                      'Errors: ${stats['errors']}',
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDebugLog(context);
                  },
                  child: const Text('View Log'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _exportMarkdown(BuildContext context) {
    final service = context.read<JoplinService>();
    final note = service.selectedNote;

    if (note == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No note selected')),
      );
      return;
    }

    final content = service.exportNoteAsMarkdown(note);
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', '${note.title}.md')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported: ${note.title}.md')),
    );
  }

  void _showNewNotebookDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Notebook'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Notebook name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<JoplinService>().createNotebook(
                      title: controller.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDebugLog(BuildContext context) {
    final service = context.read<JoplinService>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Text('Import Log'),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                service.clearDebugLog();
                Navigator.pop(context);
              },
              tooltip: 'Clear Log',
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 400,
          child: Consumer<JoplinService>(
            builder: (context, service, child) {
              final log = service.debugLog;
              if (log.isEmpty) {
                return const Center(
                  child: Text('No log entries'),
                );
              }
              return ListView.builder(
                itemCount: log.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _downloadDebugLog(BuildContext context) {
    final service = context.read<JoplinService>();
    final log = service.debugLog.join('\n');
    final bytes = utf8.encode(log);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'joplin_web_debug.log')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug log downloaded')),
    );
  }

  void _showKeyboardShortcuts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Markdown Formatting'),
        content: const SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Text Formatting:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _ShortcutRow(label: 'Bold', shortcut: '**text**'),
              _ShortcutRow(label: 'Italic', shortcut: '*text*'),
              _ShortcutRow(label: 'Underline', shortcut: '<u>text</u>'),
              _ShortcutRow(label: 'Strikethrough', shortcut: '~~text~~'),
              SizedBox(height: 16),
              Text('Headings:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _ShortcutRow(label: 'Heading 1', shortcut: '# text'),
              _ShortcutRow(label: 'Heading 2', shortcut: '## text'),
              _ShortcutRow(label: 'Heading 3', shortcut: '### text'),
              SizedBox(height: 16),
              Text('Lists:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _ShortcutRow(label: 'Bullet List', shortcut: '- item'),
              _ShortcutRow(label: 'Numbered List', shortcut: '1. item'),
              _ShortcutRow(label: 'Task List', shortcut: '- [ ] task'),
              SizedBox(height: 16),
              Text('Other:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              _ShortcutRow(label: 'Link', shortcut: '[text](url)'),
              _ShortcutRow(label: 'Image', shortcut: '![alt](url)'),
              _ShortcutRow(label: 'Inline Code', shortcut: '`code`'),
              _ShortcutRow(label: 'Code Block', shortcut: '```code```'),
              _ShortcutRow(label: 'Quote', shortcut: '> text'),
              _ShortcutRow(label: 'Horizontal Rule', shortcut: '---'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Joplin Web'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Joplin Web Clone'),
            SizedBox(height: 8),
            Text('A web-based note-taking application inspired by Joplin.'),
            SizedBox(height: 16),
            Text('Features:'),
            Text('• Create and organize notes in notebooks'),
            Text('• Markdown editing with live preview'),
            Text('• Full formatting toolbar'),
            Text('• Import/Export Markdown files'),
            Text('• Import Joplin JEX archives'),
            Text('• Hierarchical notebook structure'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final List<PopupMenuEntry> items;

  const _MenuButton({
    required this.label,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ),
      itemBuilder: (context) => items,
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final String label;
  final String shortcut;

  const _ShortcutRow({required this.label, required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label)),
          Text(
            shortcut,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
