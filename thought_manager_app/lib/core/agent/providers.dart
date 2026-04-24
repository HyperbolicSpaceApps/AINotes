import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'thought_agent.dart';
import '../models/chat_message.dart';
import '../models/thought.dart';
import '../storage/thought_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final thoughtRepositoryProvider = Provider<ThoughtRepository>((ref) {
  throw UnimplementedError('Must be overridden in main() after Hive init');
});

// ── API Key ───────────────────────────────────────────────────────────────────

final apiKeyProvider = StateNotifierProvider<ApiKeyNotifier, String>((ref) {
  return ApiKeyNotifier();
});

class ApiKeyNotifier extends StateNotifier<String> {
  static const _prefsKey = 'groq_api_key';

  ApiKeyNotifier() : super('') {
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

// ── Agent ─────────────────────────────────────────────────────────────────────

final agentProvider = Provider<ThoughtAgent?>((ref) {
  final key = ref.watch(apiKeyProvider);
  final repo = ref.watch(thoughtRepositoryProvider);
  if (key.isEmpty) return null;
  return ThoughtAgent(repository: repo, groqApiKey: key);
});

// ── Thoughts list ────────────────────────────────────────────────────────────────

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
                "ideas, todos, thoughts — and I'll save and organize it for you. "
                "You can also ask me to find thoughts, summarize, or reorganize your collection.",
          ),
        ]);

  bool _isThinking = false;
  bool get isThinking => _isThinking;

  Future<void> send(String text) async {
    if (text.trim().isEmpty || _isThinking) return;

    final agent = _ref.read(agentProvider);
    if (agent == null) return;

    // Add user message
    final userMsg = ChatMessage(role: MessageRole.user, content: text);
    state = [...state, userMsg];

    // Add thinking indicator
    final thinkingMsg = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isThinking: true,
    );
    state = [...state, thinkingMsg];
    _isThinking = true;

    try {
      // Build history (exclude thinking bubble and welcome message for API)
      final history = state
          .where((m) => !m.isThinking && m.role != MessageRole.system)
          .where((m) => m.id != userMsg.id) // exclude current user msg (added separately in agent)
          .toList();

      final reply = await agent.run(history, text);

      // Replace thinking with real response
      state = [
        ...state.where((m) => !m.isThinking),
        ChatMessage(role: MessageRole.assistant, content: reply),
      ];

      // Refresh thoughts list (agent may have saved/deleted thoughts)
      _ref.read(thoughtsProvider.notifier).refresh();
    } catch (e) {
      state = [
        ...state.where((m) => !m.isThinking),
        ChatMessage(
          role: MessageRole.assistant,
          content: 'Error: ${e.toString()}. Check your Groq API key in Settings.',
        ),
      ];
    } finally {
      _isThinking = false;
    }
  }

  void clear() {
    state = [state.first]; // keep welcome message
  }
}

// ── Voice input ───────────────────────────────────────────────────────────────

final isListeningProvider = StateProvider<bool>((ref) => false);
