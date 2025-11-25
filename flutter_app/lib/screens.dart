import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'service.dart';
import 'models.dart';

// Global key for accessing editor state from menu
final GlobalKey<EditorPaneState> editorKey = GlobalKey<EditorPaneState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar with notebooks
          SizedBox(
            width: 250,
            child: Sidebar(),
          ),
          const VerticalDivider(width: 1),
          // Notes list
          SizedBox(
            width: 300,
            child: NotesList(),
          ),
          const VerticalDivider(width: 1),
          // Editor
          Expanded(
            child: EditorPane(key: editorKey),
          ),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoplinService>(
      builder: (context, service, child) {
        return Container(
          color: Colors.grey[100],
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    const Icon(Icons.folder, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Notebooks',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.create_new_folder, size: 20),
                      onPressed: () {
                        _showCreateNotebookDialog(context, service);
                      },
                      tooltip: 'New Notebook',
                    ),
                  ],
                ),
              ),
              // All Notes option
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('All Notes'),
                selected: service.selectedNotebookId == null,
                onTap: () => service.selectNotebook(null),
              ),
              const Divider(),
              // Notebooks list
              Expanded(
                child: ListView.builder(
                  itemCount: service.notebooks.length,
                  itemBuilder: (context, index) {
                    final notebook = service.notebooks[index];
                    final depth = service.getNotebookDepth(notebook.id);
                    final hasChildren = service.notebookHasChildren(notebook.id);
                    final isCollapsed = service.isNotebookCollapsed(notebook.id);
                    
                    return GestureDetector(
                      onDoubleTap: hasChildren
                          ? () => service.toggleNotebookCollapse(notebook.id)
                          : null,
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 8),
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasChildren)
                              Icon(
                                isCollapsed
                                    ? Icons.arrow_right
                                    : Icons.arrow_drop_down,
                                size: 20,
                                color: Colors.grey[600],
                              )
                            else
                              const SizedBox(width: 20),
                            const SizedBox(width: 4),
                            const Icon(Icons.folder_outlined),
                          ],
                        ),
                        title: Text(
                          notebook.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        selected: service.selectedNotebookId == notebook.id,
                        onTap: () => service.selectNotebook(notebook.id),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            const PopupMenuItem(
                              value: 'new_sub',
                              child: Text('New Sub-notebook'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenameDialog(context, service, notebook);
                            } else if (value == 'new_sub') {
                              _showCreateNotebookDialog(context, service,
                                  parentId: notebook.id);
                            } else if (value == 'delete') {
                              _showDeleteConfirmDialog(context, service, notebook);
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateNotebookDialog(BuildContext context, JoplinService service,
      {String? parentId}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parentId != null ? 'New Sub-notebook' : 'New Notebook'),
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
                service.createNotebook(
                  parentId: parentId,
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

  void _showRenameDialog(
      BuildContext context, JoplinService service, Notebook notebook) {
    final controller = TextEditingController(text: notebook.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Notebook'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'New name',
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
                service.renameNotebook(notebook, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
      BuildContext context, JoplinService service, Notebook notebook) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notebook'),
        content: Text(
            'Are you sure you want to delete "${notebook.title}" and all its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteNotebook(notebook);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class NotesList extends StatelessWidget {
  const NotesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<JoplinService>(
      builder: (context, service, child) {
        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: service.updateSearch,
                ),
              ),
              // New note button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('New Note'),
                    onPressed: () {
                      service.createNote();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Notes list
              Expanded(
                child: service.notes.isEmpty
                    ? const Center(
                        child: Text(
                          'No notes yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: service.notes.length,
                        itemBuilder: (context, index) {
                          final note = service.notes[index];
                          return NoteCard(
                            note: note,
                            isSelected: service.selectedNote?.id == note.id,
                            onTap: () => service.selectNote(note),
                            onDelete: () =>
                                _showDeleteNoteDialog(context, service, note),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteNoteDialog(
      BuildContext context, JoplinService service, Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              service.deleteNote(note);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(note.updatedTime);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.body.isEmpty ? 'No content' : note.body.split('\n').first,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 10,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}

class EditorPane extends StatefulWidget {
  const EditorPane({super.key});

  @override
  State<EditorPane> createState() => EditorPaneState();
}

class EditorPaneState extends State<EditorPane> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _isPreview = false;
  String? _currentNoteId;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // Public methods for menu access
  void insertBold() => _insertMarkdown('**', '**');
  void insertItalic() => _insertMarkdown('*', '*');
  void insertUnderline() => _insertMarkdown('<u>', '</u>');
  void insertStrikethrough() => _insertMarkdown('~~', '~~');
  void insertHeading1() => _insertMarkdown('# ', '');
  void insertHeading2() => _insertMarkdown('## ', '');
  void insertHeading3() => _insertMarkdown('### ', '');
  void insertBulletList() => _insertMarkdown('- ', '');
  void insertNumberedList() => _insertMarkdown('1. ', '');
  void insertTaskList() => _insertMarkdown('- [ ] ', '');
  void insertLink() => _insertMarkdown('[', '](url)');
  void insertImage() => _insertMarkdown('![alt text](', ')');
  void insertInlineCode() => _insertMarkdown('`', '`');
  void insertCodeBlock() => _insertMarkdown('```\n', '\n```');
  void insertQuote() => _insertMarkdown('> ', '');
  void insertHorizontalRule() => _insertMarkdown('\n---\n', '');
  void insertTable() => _insertMarkdown(
      '\n| Column 1 | Column 2 | Column 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |\n',
      '');

  @override
  Widget build(BuildContext context) {
    return Consumer<JoplinService>(
      builder: (context, service, child) {
        final note = service.selectedNote;

        if (note == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Select a note to view',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Update controllers when note changes
        if (_currentNoteId != note.id) {
          _currentNoteId = note.id;
          _titleController.text = note.title;
          _contentController.text = note.body;
        }

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Text formatting
                      _ToolbarButton(
                        icon: Icons.format_bold,
                        tooltip: 'Bold (Ctrl+B)',
                        onPressed: insertBold,
                      ),
                      _ToolbarButton(
                        icon: Icons.format_italic,
                        tooltip: 'Italic (Ctrl+I)',
                        onPressed: insertItalic,
                      ),
                      _ToolbarButton(
                        icon: Icons.format_underlined,
                        tooltip: 'Underline (Ctrl+U)',
                        onPressed: insertUnderline,
                      ),
                      _ToolbarButton(
                        icon: Icons.format_strikethrough,
                        tooltip: 'Strikethrough',
                        onPressed: insertStrikethrough,
                      ),
                      const _ToolbarDivider(),
                      
                      // Headings
                      PopupMenuButton<String>(
                        tooltip: 'Headings',
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.title, size: 20),
                              Icon(Icons.arrow_drop_down, size: 16),
                            ],
                          ),
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'h1', child: Text('Heading 1')),
                          const PopupMenuItem(value: 'h2', child: Text('Heading 2')),
                          const PopupMenuItem(value: 'h3', child: Text('Heading 3')),
                        ],
                        onSelected: (value) {
                          if (value == 'h1') insertHeading1();
                          if (value == 'h2') insertHeading2();
                          if (value == 'h3') insertHeading3();
                        },
                      ),
                      const _ToolbarDivider(),
                      
                      // Lists
                      _ToolbarButton(
                        icon: Icons.format_list_bulleted,
                        tooltip: 'Bullet List',
                        onPressed: insertBulletList,
                      ),
                      _ToolbarButton(
                        icon: Icons.format_list_numbered,
                        tooltip: 'Numbered List',
                        onPressed: insertNumberedList,
                      ),
                      _ToolbarButton(
                        icon: Icons.check_box,
                        tooltip: 'Task List',
                        onPressed: insertTaskList,
                      ),
                      const _ToolbarDivider(),
                      
                      // Links and media
                      _ToolbarButton(
                        icon: Icons.link,
                        tooltip: 'Insert Link',
                        onPressed: insertLink,
                      ),
                      _ToolbarButton(
                        icon: Icons.image,
                        tooltip: 'Insert Image',
                        onPressed: insertImage,
                      ),
                      const _ToolbarDivider(),
                      
                      // Code
                      _ToolbarButton(
                        icon: Icons.code,
                        tooltip: 'Inline Code',
                        onPressed: insertInlineCode,
                      ),
                      _ToolbarButton(
                        icon: Icons.integration_instructions,
                        tooltip: 'Code Block',
                        onPressed: insertCodeBlock,
                      ),
                      const _ToolbarDivider(),
                      
                      // Other
                      _ToolbarButton(
                        icon: Icons.format_quote,
                        tooltip: 'Quote',
                        onPressed: insertQuote,
                      ),
                      _ToolbarButton(
                        icon: Icons.horizontal_rule,
                        tooltip: 'Horizontal Rule',
                        onPressed: insertHorizontalRule,
                      ),
                      _ToolbarButton(
                        icon: Icons.table_chart,
                        tooltip: 'Insert Table',
                        onPressed: insertTable,
                      ),
                      const SizedBox(width: 16),
                      
                      // Preview toggle
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text('Edit'),
                            icon: Icon(Icons.edit),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text('Preview'),
                            icon: Icon(Icons.visibility),
                          ),
                        ],
                        selected: {_isPreview},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _isPreview = selection.first;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Title field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Note title',
                  ),
                  onChanged: (value) {
                    service.updateNoteTitle(value);
                  },
                ),
              ),
              const Divider(height: 1),
              // Content area
              Expanded(
                child: _isPreview
                    ? Markdown(
                        data: _contentController.text,
                        padding: const EdgeInsets.all(16),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _contentController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Start writing...',
                          ),
                          onChanged: (value) {
                            service.updateNoteContent(value);
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _insertMarkdown(String prefix, String suffix) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    if (selection.isCollapsed) {
      // No selection, just insert at cursor
      final newText =
          text.substring(0, selection.start) + prefix + suffix + text.substring(selection.start);
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(
        offset: selection.start + prefix.length,
      );
    } else {
      // Wrap selection
      final selectedText = text.substring(selection.start, selection.end);
      final newText =
          text.substring(0, selection.start) + prefix + selectedText + suffix + text.substring(selection.end);
      _contentController.text = newText;
      _contentController.selection = TextSelection(
        baseOffset: selection.start + prefix.length,
        extentOffset: selection.end + prefix.length,
      );
    }

    // Notify service of change
    context.read<JoplinService>().updateNoteContent(_contentController.text);
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.grey[400],
    );
  }
}