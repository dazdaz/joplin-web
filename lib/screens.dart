import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'service.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JoplinService>();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.terminal, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text("Joplin Shell", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Divider(color: Colors.grey, height: 1),
        
        // Notebook Tree
        Expanded(
          child: ListView.builder(
            itemCount: service.notebooks.length,
            itemBuilder: (context, index) {
              final nb = service.notebooks[index];
              final isSelected = nb.id == service.selectedNotebookId;
              final isRoot = nb.depth == 0;
              
              return InkWell(
                onTap: () => service.selectNotebook(nb.id),
                child: Container(
                  color: isSelected ? const Color(0xFF3F454C) : null,
                  // Indentation based on depth
                  padding: EdgeInsets.fromLTRB(16.0 + (nb.depth * 12), 10, 8, 10),
                  child: Row(
                    children: [
                      Text(isRoot ? "📁" : "📂", style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nb.title,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[300],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
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
    );
  }
}

class NoteList extends StatelessWidget {
  const NoteList({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JoplinService>();
    
    return Column(
      children: [
        // Case-Insensitive Search Bar
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search notes...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
            ),
            onChanged: (val) => service.search(val),
          ),
        ),
        const Divider(height: 1),
        
        // List
        Expanded(
          child: ListView.builder(
            itemCount: service.notes.length,
            itemBuilder: (context, index) {
              final note = service.notes[index];
              final isSelected = note.id == service.selectedNoteId;
              
              return ListTile(
                selected: isSelected,
                selectedTileColor: const Color(0xFFE8F0F5),
                leading: const Text("📄", style: TextStyle(fontSize: 20)),
                title: Text(
                  note.title.isEmpty ? "Untitled" : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('yyyy-MM-dd').format(note.updatedTime),
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => service.selectNote(note.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class EditorPane extends StatefulWidget {
  const EditorPane({super.key});
  @override
  State<EditorPane> createState() => _EditorPaneState();
}

class _EditorPaneState extends State<EditorPane> {
  late TextEditingController _controller;
  
  @override
  void initState() { super.initState(); _controller = TextEditingController(); }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JoplinService>();
    final note = service.selectedNote;

    if (note == null) {
      return const Center(child: Text("Select a note to view", style: TextStyle(color: Colors.grey)));
    }

    if (_controller.text != note.body) _controller.text = note.body;

    return Column(
      children: [
        // Toolbar
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(note.title, style: Theme.of(context).textTheme.titleMedium),
              ),
              // Toggle Read/Edit
              ToggleButtons(
                isSelected: [!service.isEditing, service.isEditing],
                onPressed: (index) => service.toggleEditMode(),
                borderRadius: BorderRadius.circular(8),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 48),
                children: const [Icon(Icons.visibility, size: 18), Icon(Icons.edit, size: 18)],
              ),
              const SizedBox(width: 12),
              // Export
              ElevatedButton.icon(
                onPressed: service.exportCurrentNote,
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Export MD"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF106BA3),
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
        
        // Body
        Expanded(
          child: service.isEditing
              // Write Mode (Vim-ish Dark)
              ? Container(
                  color: const Color(0xFF282c34), 
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 14, color: Color(0xFFabb2bf)),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (val) => service.updateNoteBody(val),
                  ),
                )
              // Read Mode
              : Markdown(
                  data: note.body,
                  padding: const EdgeInsets.all(24.0),
                  selectable: true,
                  // Image Handler for Attachments
                  imageBuilder: (uri, title, alt) {
                    String path = uri.toString();
                    // If path is not http, assume local resource
                    if (!path.startsWith('http')) {
                       // Clean path to match assets/resources/filename
                       final filename = path.split('/').last;
                       path = 'assets/resources/$filename';
                    }
                    return Image.asset(path, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, color: Colors.grey));
                  },
                ),
        ),
      ],
    );
  }
}
