class Note {
  final int? id;
  final String title;
  final String content;
  final String? createdAt;
  final String? category;
  final int? color;
  final bool isPinned;

  Note({
    this.id,
    required this.title,
    required this.content,
    this.createdAt,
    this.category,
    this.color,
    this.isPinned = false,
  });

  // Konversi objek Note ke Map untuk disimpan di SQLite
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'content': content,
      'created_at': createdAt,
      'category': category,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Membuat objek Note dari Map hasil query SQLite
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      createdAt: map['created_at'] as String?,
      category: (map['category'] as String?) ?? 'Kuliah',
      color: map['color'] as int?,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
    );
  }

  // CopyWith untuk kemudahan update immutable state
  Note copyWith({
    int? id,
    String? title,
    String? content,
    String? createdAt,
    String? category,
    int? color,
    bool? isPinned,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      category: category ?? this.category,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
    );
  }
}
