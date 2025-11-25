import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:archive/archive.dart';
import 'models.dart';

class JoplinService extends ChangeNotifier {
  List<Note> _allNotes = [];
  List<Notebook> _allNotebooks = [];
  List<Notebook> _notebooks = [];
  List<Note> _notes = [];
  Note? _selectedNote;
  String? _selectedNotebookId;
  String _searchQuery = '';
  final List<String> _debugLog = [];
  
  // Debug logging is disabled by default
  bool _debugLoggingEnabled = false;
  
  // Track collapsed notebooks for expand/collapse feature
  final Set<String> _collapsedNotebooks = {};

  List<Notebook> get notebooks => _notebooks;
  List<Note> get notes => _notes;
  Note? get selectedNote => _selectedNote;
  String? get selectedNotebookId => _selectedNotebookId;
  List<String> get debugLog => List.unmodifiable(_debugLog);
  bool get debugLoggingEnabled => _debugLoggingEnabled;

  void setDebugLogging(bool enabled) {
    _debugLoggingEnabled = enabled;
    notifyListeners();
  }

  void _log(String message) {
    if (!_debugLoggingEnabled) return;
    final timestamp = DateTime.now().toIso8601String();
    _debugLog.add('[$timestamp] $message');
    debugPrint(message);
  }

  void clearDebugLog() {
    _debugLog.clear();
    notifyListeners();
  }
  
  bool isNotebookCollapsed(String id) => _collapsedNotebooks.contains(id);
  
  bool notebookHasChildren(String id) {
    return _allNotebooks.any((n) => n.parentId == id);
  }
  
  void toggleNotebookCollapse(String id) {
    if (_collapsedNotebooks.contains(id)) {
      _collapsedNotebooks.remove(id);
    } else {
      _collapsedNotebooks.add(id);
    }
    _organizeNotebooks();
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/db.json');
      final data = json.decode(jsonString);

      _allNotebooks = (data['notebooks'] as List)
          .map((n) => Notebook.fromJson(n))
          .toList();
      _allNotes =
          (data['notes'] as List).map((n) => Note.fromJson(n)).toList();

      _organizeNotebooks();
      _filterNotes();
      notifyListeners();
    } catch (e) {
      _log('Error loading data: $e');
    }
  }

  void _organizeNotebooks() {
    // Build hierarchy - show all notebooks with proper indentation
    _notebooks = [];
    _addNotebooksRecursively('', 0);
  }

  void _addNotebooksRecursively(String parentId, int depth) {
    final children =
        _allNotebooks.where((n) => n.parentId == parentId).toList();
    children.sort((a, b) => a.title.compareTo(b.title));
    for (final notebook in children) {
      _notebooks.add(notebook);
      // Only add children if notebook is not collapsed
      if (!_collapsedNotebooks.contains(notebook.id)) {
        _addNotebooksRecursively(notebook.id, depth + 1);
      }
    }
  }

  int getNotebookDepth(String notebookId) {
    int depth = 0;
    String? currentId = notebookId;
    while (currentId != null && currentId.isNotEmpty) {
      final notebook = _allNotebooks.cast<Notebook?>().firstWhere(
            (n) => n?.id == currentId,
            orElse: () => null,
          );
      if (notebook == null || notebook.parentId.isEmpty) break;
      depth++;
      currentId = notebook.parentId;
    }
    return depth;
  }

  void selectNotebook(String? notebookId) {
    _selectedNotebookId = notebookId;
    _selectedNote = null;
    _filterNotes();
    notifyListeners();
  }

  void _filterNotes() {
    _notes = _allNotes.where((note) {
      final matchesNotebook =
          _selectedNotebookId == null || note.parentId == _selectedNotebookId;
      final matchesSearch = _searchQuery.isEmpty ||
          note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          note.body.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesNotebook && matchesSearch;
    }).toList();
    _notes.sort((a, b) => b.updatedTime.compareTo(a.updatedTime));
  }

  void selectNote(Note note) {
    _selectedNote = note;
    notifyListeners();
  }

  void updateSearch(String query) {
    _searchQuery = query;
    _filterNotes();
    notifyListeners();
  }

  void updateNoteContent(String content) {
    if (_selectedNote != null) {
      _selectedNote!.body = content;
      _selectedNote!.updatedTime = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    }
  }

  void updateNoteTitle(String title) {
    if (_selectedNote != null) {
      _selectedNote!.title = title;
      _selectedNote!.updatedTime = DateTime.now().millisecondsSinceEpoch;
      notifyListeners();
    }
  }

  Note createNote({String? parentId}) {
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentId: parentId ?? _selectedNotebookId ?? '',
      title: 'New Note',
      body: '',
      updatedTime: DateTime.now().millisecondsSinceEpoch,
    );
    _allNotes.add(newNote);
    _filterNotes();
    _selectedNote = newNote;
    notifyListeners();
    return newNote;
  }

  void deleteNote(Note note) {
    _allNotes.remove(note);
    if (_selectedNote == note) {
      _selectedNote = null;
    }
    _filterNotes();
    notifyListeners();
  }

  Notebook createNotebook({String? parentId, String title = 'New Notebook'}) {
    final newNotebook = Notebook(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentId: parentId ?? '',
      title: title,
    );
    _allNotebooks.add(newNotebook);
    _organizeNotebooks();
    notifyListeners();
    return newNotebook;
  }

  void deleteNotebook(Notebook notebook) {
    // Delete all notes in this notebook
    _allNotes.removeWhere((n) => n.parentId == notebook.id);
    // Delete all child notebooks recursively
    _deleteChildNotebooks(notebook.id);
    // Delete the notebook itself
    _allNotebooks.remove(notebook);
    if (_selectedNotebookId == notebook.id) {
      _selectedNotebookId = null;
      _selectedNote = null;
    }
    _organizeNotebooks();
    _filterNotes();
    notifyListeners();
  }

  void _deleteChildNotebooks(String parentId) {
    final children =
        _allNotebooks.where((n) => n.parentId == parentId).toList();
    for (final child in children) {
      _allNotes.removeWhere((n) => n.parentId == child.id);
      _deleteChildNotebooks(child.id);
      _allNotebooks.remove(child);
    }
  }

  void renameNotebook(Notebook notebook, String newTitle) {
    notebook.title = newTitle;
    _organizeNotebooks();
    notifyListeners();
  }

  // Import markdown file
  void importMarkdownFile(String filename, String content) {
    final title = filename.replaceAll('.md', '');
    final newNote = Note(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      parentId: _selectedNotebookId ?? '',
      title: title,
      body: content,
      updatedTime: DateTime.now().millisecondsSinceEpoch,
    );
    _allNotes.add(newNote);
    _filterNotes();
    _selectedNote = newNote;
    notifyListeners();
  }

  // Export note as markdown
  String exportNoteAsMarkdown(Note note) {
    return note.body;
  }

  // Import JEX file (Joplin Export)
  Future<Map<String, int>> importJexFile(Uint8List bytes) async {
    _log('=== Starting JEX Import ===');
    _log('File size: ${bytes.length} bytes');

    int notebooksImported = 0;
    int notesImported = 0;
    int errors = 0;

    try {
      Archive? archive;

      // Check file signature
      String signature = '';
      if (bytes.length >= 4) {
        signature = bytes
            .sublist(0, 4)
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join(' ');
        _log('File signature: $signature');
      }

      // Check if it looks like a TAR file (checks various positions for 'ustar')
      bool looksLikeTar = false;
      if (bytes.length > 262) {
        final ustarCheck = String.fromCharCodes(bytes.sublist(257, 262));
        if (ustarCheck == 'ustar') {
          looksLikeTar = true;
          _log('Found ustar signature at position 257 - this is a TAR file');
        }
      }

      // Try to decode based on detection
      if (looksLikeTar) {
        _log('Attempting TAR decode first (detected TAR signature)...');
        try {
          archive = TarDecoder().decodeBytes(bytes);
          _log('TAR decode successful! Found ${archive.files.length} files');
        } catch (e) {
          _log('TAR decode failed: $e');
        }
      }

      // If TAR didn't work or wasn't detected, try other formats
      if (archive == null) {
        // Try GZip
        if (bytes.length >= 2 && bytes[0] == 0x1f && bytes[1] == 0x8b) {
          _log('Detected GZip signature, attempting GZip decode...');
          try {
            final decompressed = GZipDecoder().decodeBytes(bytes);
            _log('GZip decompressed to ${decompressed.length} bytes');
            archive = TarDecoder().decodeBytes(decompressed);
            _log('TAR decode of GZip content successful!');
          } catch (e) {
            _log('GZip/TAR decode failed: $e');
          }
        }
      }

      if (archive == null) {
        // Try ZIP
        _log('Attempting ZIP decode...');
        try {
          archive = ZipDecoder().decodeBytes(bytes);
          _log('ZIP decode successful! Found ${archive.files.length} files');
        } catch (e) {
          _log('ZIP decode failed: $e');
        }
      }

      if (archive == null && !looksLikeTar) {
        // Last resort: try TAR anyway
        _log('Last resort: Attempting TAR decode...');
        try {
          archive = TarDecoder().decodeBytes(bytes);
          _log('TAR decode successful! Found ${archive.files.length} files');
        } catch (e) {
          _log('TAR decode failed: $e');
        }
      }

      if (archive == null) {
        _log('ERROR: Could not decode archive with any method');
        return {
          'notebooks': 0,
          'notes': 0,
          'errors': 1,
        };
      }

      _log('Processing ${archive.files.length} files from archive...');

      // First pass: collect all items
      final Map<String, Map<String, dynamic>> items = {};

      for (final file in archive.files) {
        if (!file.isFile) continue;

        final filename = file.name;
        if (!filename.endsWith('.md')) continue;

        try {
          final content = utf8.decode(file.content as List<int>);
          final parsed = _parseJoplinFile(content);

          if (parsed != null) {
            items[parsed['id']] = parsed;
          }
        } catch (e) {
          _log('Error processing $filename: $e');
          errors++;
        }
      }

      _log('Parsed ${items.length} valid items');

      // Second pass: create notebooks first
      for (final item in items.values) {
        if (item['type_'] == 2) {
          // Notebook
          final notebook = Notebook(
            id: item['id'],
            parentId: item['parent_id'] ?? '',
            title: item['title'] ?? 'Untitled Notebook',
          );
          _allNotebooks.add(notebook);
          notebooksImported++;
        }
      }

      _log('Imported $notebooksImported notebooks');

      // Third pass: create notes
      for (final item in items.values) {
        if (item['type_'] == 1) {
          // Note
          final note = Note(
            id: item['id'],
            parentId: item['parent_id'] ?? '',
            title: item['title'] ?? 'Untitled Note',
            body: item['body'] ?? '',
            updatedTime: item['updated_time'] ?? 0,
          );
          _allNotes.add(note);
          notesImported++;
        }
      }

      _log('Imported $notesImported notes');

      _organizeNotebooks();
      _filterNotes();
      notifyListeners();

      _log('=== Import Complete ===');
      _log('Notebooks: $notebooksImported, Notes: $notesImported, Errors: $errors');
    } catch (e, stack) {
      _log('FATAL ERROR during import: $e');
      _log('Stack trace: $stack');
      errors++;
    }

    return {
      'notebooks': notebooksImported,
      'notes': notesImported,
      'errors': errors,
    };
  }

  Map<String, dynamic>? _parseJoplinFile(String content) {
    final lines = content.split('\n');
    final metadata = <String, dynamic>{};
    final bodyLines = <String>[];

    bool inMetadata = false;

    // All known Joplin metadata keys
    final metadataKeys = {
      'id',
      'parent_id',
      'type_',
      'title',
      'created_time',
      'updated_time',
      'is_conflict',
      'latitude',
      'longitude',
      'altitude',
      'author',
      'source_url',
      'is_todo',
      'todo_due',
      'todo_completed',
      'source',
      'source_application',
      'application_data',
      'order',
      'user_created_time',
      'user_updated_time',
      'encryption_cipher_text',
      'encryption_applied',
      'markup_language',
      'is_shared',
      'share_id',
      'conflict_original_id',
      'master_key_id',
      'icon',
      'deleted_time',
      'user_data',
    };

    for (final line in lines) {
      // Check if this line is metadata
      bool isMetadataLine = false;
      for (final key in metadataKeys) {
        if (line.startsWith('$key:')) {
          isMetadataLine = true;
          inMetadata = true;

          final value = line.substring(key.length + 1).trim();
          if (key == 'type_' ||
              key == 'updated_time' ||
              key == 'created_time' ||
              key == 'is_conflict' ||
              key == 'is_todo' ||
              key == 'todo_due' ||
              key == 'todo_completed' ||
              key == 'encryption_applied' ||
              key == 'markup_language' ||
              key == 'is_shared' ||
              key == 'order' ||
              key == 'deleted_time') {
            metadata[key] = int.tryParse(value) ?? 0;
          } else {
            metadata[key] = value;
          }
          break;
        }
      }

      if (!isMetadataLine && !inMetadata) {
        bodyLines.add(line);
      }
    }

    // Title is the first non-empty line of the body
    String title = 'Untitled';
    for (final line in bodyLines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        title = trimmed;
        break;
      }
    }

    if (!metadata.containsKey('id')) {
      return null;
    }

    // For notes, store the body (excluding first line which is title)
    if (metadata['type_'] == 1) {
      // Find first non-empty line index
      int titleIndex = -1;
      for (int i = 0; i < bodyLines.length; i++) {
        if (bodyLines[i].trim().isNotEmpty) {
          titleIndex = i;
          break;
        }
      }
      if (titleIndex >= 0 && titleIndex < bodyLines.length - 1) {
        metadata['body'] = bodyLines.sublist(titleIndex + 1).join('\n').trim();
      } else {
        metadata['body'] = '';
      }
    }

    metadata['title'] = title;

    return metadata;
  }

  // Get all notes (for export)
  List<Note> get allNotes => _allNotes;
  List<Notebook> get allNotebooks => _allNotebooks;
}