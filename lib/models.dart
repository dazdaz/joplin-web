class Note {
  String id;
  String parentId;
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

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] ?? '',
      parentId: json['parent_id'] ?? '',
      title: json['title'] ?? 'Untitled',
      body: json['body'] ?? '',
      updatedTime: DateTime.fromMillisecondsSinceEpoch(json['updated_time'] ?? 0),
    );
  }
}

class Notebook {
  String id;
  String title;
  String parentId;
  int depth; // For visual tree indentation

  Notebook({
    required this.id, 
    required this.title, 
    required this.parentId, 
    this.depth = 0
  });

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Untitled',
      parentId: json['parent_id'] ?? '',
    );
  }
}
