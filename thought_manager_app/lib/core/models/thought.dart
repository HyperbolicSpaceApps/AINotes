import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'thought.g.dart';

@HiveType(typeId: 0)
class Thought extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late List<String> tags;

  @HiveField(4)
  late String folder;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  @HiveField(7)
  List<double>? embedding;

  Thought({
    String? id,
    required this.title,
    required this.content,
    List<String>? tags,
    String? folder,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.embedding
  }) {
    this.id = id ?? const Uuid().v4();
    this.tags = tags ?? [];
    this.folder = folder ?? 'Inbox';
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }

  Thought copyWith({
    String? title,
    String? content,
    List<String>? tags,
    String? folder,
    List<double>? embedding,
  }) {
    return Thought(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      folder: folder ?? this.folder,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      embedding: this.embedding,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'tags': tags,
        'folder': folder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'embedding': embedding,
      };

  @override
  String toString() => 'Thought(id: $id, title: $title, folder: $folder)';
}
