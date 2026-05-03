import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'thought_agent.dart';
import '../models/chat_message.dart';
import '../models/thought.dart';
import '../storage/thought_repository.dart';
import '../embeddings/embedding_service.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  throw UnimplementedError('Must be overridden in main() after Hive init');
});

// ── API Keys ──────────────────────────────────────────────────────────────────

final groqApiKeyProvider = StateNotifierProvider<GroqApiKeyNotifier, String>((ref) {
  return GroqApiKeyNotifier();
});

class GroqApiKeyNotifier extends StateNotifier<String> {
  static const _prefsKey = 'groq_api_key';

  GroqApiKeyNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_prefsKey) ?? '';
  }

  Future<void> set(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key);
    state = key;
  }
}

final jinaApiKeyProvider = StateNotifierProvider<JinaApiKeyNotifier, String>((ref) {
  return JinaApiKeyNotifier();
});

class JinaApiKeyNotifier extends StateNotifier<String> {
  static const _prefsKey = 'jina_api_key';

  JinaApiKeyNotifier() : super('') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_prefsKey) ?? '';
  }

  Future<void> set(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, key);
    state = key;
  }
}

// ── Embedding service ─────────────────────────────────────────────────────────

final embeddingServiceProvider = Provider<EmbeddingService?>((ref) {
  final key = ref.watch(jinaApiKeyProvider);
  if (key.isEmpty) return null;
  return EmbeddingService(apiKey: key);
});

// ── Agent ─────────────────────────────────────────────────────────────────────

final agentProvider = Provider<ThoughtAgent?>((ref) {
  final groqKey = ref.watch(groqApiKeyProvider);
  final repo = ref.watch(thoughtRepositoryProvider);
  final embedder = ref.watch(embeddingServiceProvider);
  if (groqKey.isEmpty) return null;
  // embedder can be null — agent degrades gracefully to keyword search
  return ThoughtAgent(
    repository: repo,
    groqApiKey: groqKey,
    embeddingService: embedder!,
  );
});

// ── Thoughts list ─────────────────────────────────────────────────────────────

final thoughtsProvider = StateNotifierProvider<ThoughtsNotifier, List<Thought>>((ref) {
  final repo = ref.watch(thoughtRepositoryProvider);
  return ThoughtsNotifier(repo);
});

class ThoughtsNotifier extends StateNotifier<List<Thought>> {
  final ThoughtRepository _repo;

  ThoughtsNotifier(this._repo) : super(_repo.getAll());

  void refresh() => state = _repo.getAll();
}

// ── Chat ──────────────────────────────────────────────────────────────────────

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;

  ChatNotifier(this._ref)
      : super([
          ChatMessage(
            role: MessageRole.assistant,
            content:
                "Hi! I'm ThoughtManager. Tell me anything you want to remember — "
                "ideas, todos, grocery items, thoughts — and I'll save and find them for you. "
                "Search works by meaning, not just keywords.",
          ),
        ]);

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  Future<void> send(String text) async {
    if (text.trim().isEmpty || _isThinking) return;

    final agent = _ref.read(agentProvider);
    if (agent == null) return;

    final userMsg = ChatMessage(role: MessageRole.user, content: text);
    state = [...state, userMsg];

    final thinkingMsg = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isThinking: true,
    );
    state = [...state, thinkingMsg];
    _isThinking = true;

    try {
      final history = state
          .where((m) => !m.isThinking && m.role != MessageRole.system)
          .where((m) => m.id != userMsg.id)
          .toList();

      final reply = await agent.run(history, text);

      state = [
        ...state.where((m) => !m.isThinking),
        ChatMessage(role: MessageRole.assistant, content: reply),
      ];

      _ref.read(thoughtsProvider.notifier).refresh();
    } catch (e) {
      state = [
        ...state.where((m) => !m.isThinking),
        ChatMessage(
          role: MessageRole.assistant,
          content: 'Error: ${e.toString()}. Check your API keys in Settings.',
        ),
      ];
    } finally {
      _isThinking = false;
    }
  }

  void clear() {
    state = [state.first];
  }
}

// ── Voice input ───────────────────────────────────────────────────────────────

final isListeningProvider = StateProvider<bool>((ref) => false);