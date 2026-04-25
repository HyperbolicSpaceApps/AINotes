import 'package:hive_flutter/hive_flutter.dart';
import 'package:thought_manager_app/core/embeddings/embedding_service.dart';
import 'package:thought_manager_app/shared/utils/cosine_similarity.dart';
import '../models/thought.dart';

class ThoughtRepository {
  static const _boxName = 'thoughts';
  late Box<Thought> _box;

  Future<void> init() async {
    _box = await Hive.openBox<Thought>(_boxName);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<Thought> save(Thought thought, {EmbeddingService? embedder}) async {
    if (embedder != null) {
      final text = '${thought.title} ${thought.content} ${thought.tags.join(' ')}';
      thought = thought.copyWith(embedding: await embedder.embedDocument(text));
    }
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

  List<Thought> semanticSearch(List<double> queryVec, {int topK = 8}) {
    final all = _box.values.where((t) => t.embedding != null).toList();
    final scored = all.map((t) => (
      thought: t,
      score: cosineSimilarity(queryVec, t.embedding!),
    )).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return scored.take(topK).map((s) => s.thought).toList();
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
    final total = _box.values.length;
    if (total == 0) return '(no thoughts yet)';
    return '$total thoughts stored. Use search_thoughts to retrieve relevant ones.';
  }
}
