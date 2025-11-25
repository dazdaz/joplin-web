class Note {
  final String id;
  String parentId;
  String title;
  String body;
  int updatedTime;

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
      updatedTime: json['updated_time'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'title': title,
      'body': body,
      'updated_time': updatedTime,
    };
  }
}

class Notebook {
  final String id;
  String parentId;
  String title;

  Notebook({
    required this.id,
    required this.parentId,
    required this.title,
  });

  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      id: json['id'] ?? '',
      parentId: json['parent_id'] ?? '',
      title: json['title'] ?? 'Untitled',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'title': title,
    };
  }
}