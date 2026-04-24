import 'package:hive_flutter/hive_flutter.dart';
import '../models/thought.dart';

class ThoughtRepository {
  static const _boxName = 'thoughts';
  late Box<Thought> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Thought>(_boxName);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<Thought> save(Thought thought) async {
    await _box.put(thought.id, thought);
    return thought;
  }

  Future<Thought?> getById(String id) async {
    return _box.get(id);
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<Thought> getAll() {
    return _box.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  List<Thought> search(String query, {String? folder, String? tag}) {
    final q = query.toLowerCase();
    return _box.values.where((thought) {
      final matchesQuery = thought.title.toLowerCase().contains(q) ||
          thought.content.toLowerCase().contains(q) ||
          thought.tags.any((t) => t.toLowerCase().contains(q));

      final matchesFolder =
          folder == null || thought.folder.toLowerCase().contains(folder.toLowerCase());

      final matchesTag = tag == null ||
          thought.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()));

      return matchesQuery && matchesFolder && matchesTag;
    }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  List<String> getFolders() {
    final folders = _box.values.map((n) => n.folder).toSet().toList();
    folders.sort();
    return folders;
  }

  Map<String, List<Thought>> getThoughtsByFolder() {
    final result = <String, List<Thought>>{};
    for (final thought in _box.values) {
      result.putIfAbsent(thought.folder, () => []).add(thought);
    }
    result.forEach((_, thoughts) {
      thoughts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
    return result;
  }

  // ── Context string for agent ───────────────────────────────────────────────

  String getContextSummary() {
    final thoughts = getAll();
    if (thoughts.isEmpty) return '(no thoughts yet)';
    return thoughts
        .take(50) // cap context size
        .map((n) =>
            '[${n.id.substring(0, 8)}] "${n.title}" (${n.folder}) tags:${n.tags.join(",")}')
        .join(' | ');
  }
}
