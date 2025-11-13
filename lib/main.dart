import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// 1. MODELS (mimicking Joplin's Data Structure)
// ---------------------------------------------------------------------------
class Note {
  String id;
  String parentId; // Notebook ID
  String title;
  String body;
  DateTime updatedTime;

  Note({
    required this.id,
    required this.parentId,
    required this.title,
    required this.body,
    required this.updatedTime,
  });
}

class Notebook {
  String id;
  String title;

  Notebook({required this.id, required this.title});
}

// ---------------------------------------------------------------------------
// 2. SERVICE LAYER (The "Core Functionality" Logic)
// ---------------------------------------------------------------------------
// This mimics the API calls that 'joplin-shell' would make, but runs locally.
class JoplinService extends ChangeNotifier {
  // Mock Data Store (In-Memory for this demo)
  // In a real app, you would replace this with 'shared_preferences' or HTTP calls.
  List<Notebook> _notebooks = [
    Notebook(id: 'nb1', title: 'Personal'),
    Notebook(id: 'nb2', title: 'Work'),
    Notebook(id: 'nb3', title: 'Flutter Project'),
  ];

  List<Note> _notes = [
    Note(
      id: 'n1',
      parentId: 'nb1',
      title: 'Welcome to Joplin Web',
      body: '# Welcome!\nThis is a **Flutter** clone of the Joplin interface.\n\n- It runs entirely in your browser.\n- No desktop app required.',
      updatedTime: DateTime.now(),
    ),
    Note(
      id: 'n2',
      parentId: 'nb1',
      title: 'Todo List',
      body: '- [ ] Check out Flutter\n- [x] Clone Joplin UI\n- [ ] Connect to Cloud',
      updatedTime: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  String? _selectedNotebookId;
  String? _selectedNoteId;
  bool _isEditing = true; // Toggle between Edit/View mode

  // Getters
  List<Notebook> get notebooks => _notebooks;
  List<Note> get notes => _selectedNotebookId == null
      ? []
      : _notes.where((n) => n.parentId == _selectedNotebookId).toList();
  
  Note? get selectedNote => _selectedNoteId == null 
      ? null 
      : _notes.firstWhere((n) => n.id == _selectedNoteId, orElse: () => _notes[0]);

  String? get selectedNotebookId => _selectedNotebookId;
  String? get selectedNoteId => _selectedNoteId;
  bool get isEditing => _isEditing;

  // Actions
  void selectNotebook(String id) {
    _selectedNotebookId = id;
    _selectedNoteId = null; // Deselect note when changing notebook
    notifyListeners();
  }

  void selectNote(String id) {
    _selectedNoteId = id;
    _isEditing = false; // Default to view mode on select
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void updateNoteBody(String newBody) {
    if (_selectedNoteId != null) {
      final index = _notes.indexWhere((n) => n.id == _selectedNoteId);
      if (index != -1) {
        _notes[index].body = newBody;
        _notes[index].updatedTime = DateTime.now();
        notifyListeners();
      }
    }
  }
  
  void createNote() {
    if (_selectedNotebookId == null) return;
    
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentId: _selectedNotebookId!,
      title: 'New Note',
      body: '',
      updatedTime: DateTime.now(),
    );
    _notes.add(newNote);
    _selectedNoteId = newNote.id;
    _isEditing = true;
    notifyListeners();
  }
}

// ---------------------------------------------------------------------------
// 3. UI APPLICATION
// ---------------------------------------------------------------------------
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => JoplinService()),
      ],
      child: const JoplinCloneApp(),
    ),
  );
}

class JoplinCloneApp extends StatelessWidget {
  const JoplinCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joplin Web',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Joplin Default Theme Colors
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF106BA3), // Joplin Blue
          surface: Colors.white,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    // Initial Selection
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<JoplinService>();
      if (service.selectedNotebookId == null && service.notebooks.isNotEmpty) {
        service.selectNotebook(service.notebooks.first.id);
      }
    });

    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar (Notebooks)
          Container(
            width: 250,
            color: const Color(0xFF2D3136), // Joplin Dark Sidebar
            child: const Sidebar(),
          ),
          // 2. Note List
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: const NoteList(),
          ),
          // 3. Editor / Viewer
          const Expanded(
            child: EditorPane(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. WIDGETS (The 3 Panes)
// ---------------------------------------------------------------------------

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JoplinService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Joplin Web",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        const Divider(color: Colors.grey, height: 1),
        // Notebooks Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            "NOTEBOOKS",
            style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        // List of Notebooks
        Expanded(
          child: ListView.builder(
            itemCount: service.notebooks.length,
            itemBuilder: (context, index) {
              final nb = service.notebooks[index];
              final isSelected = nb.id == service.selectedNotebookId;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: const Color(0xFF3F454C), // Lighter grey for selection
                leading: Icon(Icons.folder, color: isSelected ? Colors.white : Colors.grey[400], size: 20),
                title: Text(
                  nb.title,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.grey[300]),
                ),
                onTap: () => service.selectNotebook(nb.id),
              );
            },
          ),
        ),
        // Sync Button (Mock)
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Sync not supported in web-only mode yet.")),
              );
            },
            icon: const Icon(Icons.sync),
            label: const Text("Synchronise"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF106BA3),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 40),
            ),
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
        // Search / Header
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Search...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              isDense: true,
            ),
            onChanged: (val) {}, // Implement search filter here
          ),
        ),
        // Create Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: OutlinedButton.icon(
            onPressed: service.createNote,
            icon: const Icon(Icons.add),
            label: const Text("New Note"),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 36)),
          ),
        ),
        const Divider(),
        // The List
        Expanded(
          child: ListView.builder(
            itemCount: service.notes.length,
            itemBuilder: (context, index) {
              final note = service.notes[index];
              final isSelected = note.id == service.selectedNoteId;
              return ListTile(
                selected: isSelected,
                selectedTileColor: const Color(0xFFE8F0F5),
                title: Text(
                  note.title.isEmpty ? "Untitled" : note.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(note.updatedTime),
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
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JoplinService>();
    final note = service.selectedNote;

    if (note == null) {
      return const Center(
        child: Text("Select a note to view or edit", style: TextStyle(color: Colors.grey)),
      );
    }

    // Update controller only if text changed externally (e.g. switching notes)
    // to avoid cursor jumping issues during typing.
    if (_controller.text != note.body) {
      _controller.text = note.body;
    }

    return Column(
      children: [
        // Toolbar
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  note.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: Icon(service.isEditing ? Icons.visibility : Icons.edit),
                tooltip: service.isEditing ? "View (Markdown)" : "Edit",
                onPressed: service.toggleEditMode,
              ),
              const IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: null,
              ),
            ],
          ),
        ),
        // Content Area
        Expanded(
          child: service.isEditing
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                    decoration: const InputDecoration(border: InputBorder.none),
                    onChanged: (val) => service.updateNoteBody(val),
                  ),
                )
              : Markdown(
                  data: note.body,
                  padding: const EdgeInsets.all(16.0),
                  selectable: true,
                ),
        ),
      ],
    );
  }
}

