import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html; // For Web Export
import 'models.dart';

class JoplinService extends ChangeNotifier {
  List<Notebook> _allNotebooks = [];
  List<Notebook> _displayNotebooks = []; // Flattened tree for UI
  List<Note> _allNotes = [];
  
  String? _selectedNotebookId;
  String? _selectedNoteId;
  String _searchQuery = "";
  bool _isEditing = false;
  bool _isLoading = true;

  JoplinService() { _loadData(); }

  Future<void> _loadData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/db.json');
      final data = jsonDecode(jsonString);
      
      _allNotebooks = (data['notebooks'] as List).map((e) => Notebook.fromJson(e)).toList();
      _allNotes = (data['notes'] as List).map((e) => Note.fromJson(e)).toList();
      
      _organizeNotebooks();
      
      if (_displayNotebooks.isNotEmpty) {
        _selectedNotebookId = _displayNotebooks.first.id;
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Recursive Sort for Sidebar Tree
  void _organizeNotebooks() {
    _displayNotebooks.clear();
    // Find roots (no parent)
    var roots = _allNotebooks.where((n) => n.parentId.isEmpty).toList();
    roots.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    
    for (var root in roots) {
      _addNode(root, 0);
    }
  }

  void _addNode(Notebook node, int depth) {
    node.depth = depth;
    _displayNotebooks.add(node);
    var children = _allNotebooks.where((n) => n.parentId == node.id).toList();
    children.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    for (var child in children) {
      _addNode(child, depth + 1);
    }
  }

  // Getters
  List<Notebook> get notebooks => _displayNotebooks;
  
  List<Note> get notes {
    // 1. Filter by Notebook (unless searching globally)
    Iterable<Note> filtered = _selectedNotebookId == null 
        ? [] 
        : _allNotes.where((n) => n.parentId == _selectedNotebookId);
    
    // 2. Apply Search (Case-Insensitive, partial match)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      // When searching, we ignore notebook selection and search everything
      filtered = _allNotes.where((n) => 
        n.title.toLowerCase().contains(q) || 
        n.body.toLowerCase().contains(q)
      );
    }
    
    return filtered.toList();
  }

  Note? get selectedNote => _selectedNoteId == null 
      ? null 
      : _allNotes.firstWhere((n) => n.id == _selectedNoteId, orElse: () => _allNotes.first);

  String? get selectedNotebookId => _selectedNotebookId;
  String? get selectedNoteId => _selectedNoteId;
  bool get isEditing => _isEditing;
  bool get isLoading => _isLoading;

  // Actions
  void selectNotebook(String id) {
    _selectedNotebookId = id;
    _selectedNoteId = null;
    _searchQuery = ""; // Clear search on manual nav
    notifyListeners();
  }

  void selectNote(String id) {
    _selectedNoteId = id;
    _isEditing = false; // Reset to view mode
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void updateNoteBody(String newBody) {
    if (_selectedNoteId != null) {
      final index = _allNotes.indexWhere((n) => n.id == _selectedNoteId);
      if (index != -1) {
        _allNotes[index].body = newBody;
        _allNotes[index].updatedTime = DateTime.now();
        notifyListeners();
      }
    }
  }

  void search(String query) {
    _searchQuery = query;
    _selectedNoteId = null;
    notifyListeners();
  }

  // Export Logic
  void exportCurrentNote() {
    final note = selectedNote;
    if (note == null) return;
    
    final bytes = utf8.encode(note.body);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "${note.title}.md")
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
