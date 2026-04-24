import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/thought.dart';
import '../models/chat_message.dart';
import '../storage/thought_repository.dart';

// ── Tool definitions ──────────────────────────────────────────────────────────

const _tools = [
  {
    'type': 'function',
    'function': {
      'name': 'save_thought',
      'description':
          'Save a new thought or update an existing one. Call this when the user shares something to remember: idea, todo, thought, meeting thought, etc.',
      'parameters': {
        'type': 'object',
        'properties': {
          'title': {'type': 'string', 'description': 'Short descriptive title'},
          'content': {'type': 'string', 'description': 'Full thought content'},
          'tags': {
            'type': 'array',
            'items': {'type': 'string'},
            'description': 'Relevant tags e.g. ["idea","work","todo"]'
          },
          'folder': {
            'type': 'string',
            'description':
                'Folder e.g. "Personal", "Work/Projects", "Ideas", "Journal", "Todo"'
          },
          'thought_id': {
            'type': 'string',
            'description': 'Provide when updating an existing thought (use first 8 chars of id)'
          },
        },
        'required': ['title', 'content'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'search_thoughts',
      'description': 'Search the user\'s thoughts by topic, keyword, tag, or folder.',
      'parameters': {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'folder': {'type': 'string'},
          'tag': {'type': 'string'},
        },
        'required': ['query'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'list_thoughts',
      'description': 'List all thoughts, optionally filtered by folder.',
      'parameters': {
        'type': 'object',
        'properties': {
          'folder': {'type': 'string'},
        },
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'delete_thought',
      'description': 'Delete a thought by its id.',
      'parameters': {
        'type': 'object',
        'properties': {
          'thought_id': {'type': 'string'},
        },
        'required': ['thought_id'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'organize_thoughts',
      'description':
          'Analyze all thoughts and suggest or apply organization (folders, tags, structure). '
          'Use action=suggest first, then action=apply if user confirms.',
      'parameters': {
        'type': 'object',
        'properties': {
          'action': {
            'type': 'string',
            'enum': ['suggest', 'apply'],
          },
        },
        'required': ['action'],
      },
    },
  },
];

// ── Agent ─────────────────────────────────────────────────────────────────────

class ThoughtAgent {
  final ThoughtRepository repository;
  final String groqApiKey;

  static const _model = 'llama-3.1-8b-instant';
  static const _apiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _maxToolTurns = 5;

  ThoughtAgent({required this.repository, required this.groqApiKey});

  String get _systemPrompt => '''
You are ThoughtFlow, an intelligent personal thought-taking assistant.
Your job: help the user capture, organize, find, and make sense of their thoughts.

Behavior:
- User shares an idea/thought/task → call save_thought immediately, then confirm briefly.
- User asks to find something → call search_thoughts.
- User asks to list or overview → call list_thoughts.
- User asks to organize, simplify, restructure → call organize_thoughts with action=suggest first.
- Keep replies short and conversational. No markdown headers.
- Infer smart tags and folders from context.
- You can suggest organization frameworks (GTD, PARA, Zettelkasten) when relevant.

Current thoughts index:
${repository.getContextSummary()}
''';

  /// Main entry: takes conversation history + new user message, returns agent reply.
  /// Runs tool-calling loop internally.
  Future<String> run(List<ChatMessage> history, String userMessage) async {
    // Build messages array for API
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _systemPrompt},
      ...history.map((m) => m.toApiJson()),
      {'role': 'user', 'content': userMessage},
    ];

    // Agentic loop
    for (int turn = 0; turn < _maxToolTurns; turn++) {
      final response = await _callGroq(messages);
      final choice = response['choices'][0];
      final msg = choice['message'] as Map<String, dynamic>;

      messages.add(msg);

      final toolCalls = msg['tool_calls'] as List<dynamic>?;

      if (toolCalls == null || toolCalls.isEmpty) {
        // Final text response
        return (msg['content'] as String? ?? '').trim();
      }

      // Execute each tool call
      for (final tc in toolCalls) {
        final name = tc['function']['name'] as String;
        final rawArgs = tc['function']['arguments'];
        final args = rawArgs is String ? jsonDecode(rawArgs) : rawArgs;
        final result = await _executeTool(name, args as Map<String, dynamic>);

        messages.add({
          'role': 'tool',
          'tool_call_id': tc['id'],
          'content': result,
        });
      }
    }

    return 'I seem to be going in circles. Could you rephrase?';
  }

  // ── Tool execution ──────────────────────────────────────────────────────────

  Future<String> _executeTool(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'save_thought':
        return _saveThought(args);
      case 'search_thoughts':
        return _searchThoughts(args);
      case 'list_thoughts':
        return _listThoughts(args);
      case 'delete_thought':
        return _deleteThought(args);
      case 'organize_thoughts':
        return _organizeThoughts(args);
      default:
        return 'Unknown tool: $name';
    }
  }

  Future<String> _saveThought(Map<String, dynamic> args) async {
    final thoughtId = args['thought_id'] as String?;
    Thought? existing;

    if (thoughtId != null) {
      final all = repository.getAll();
      existing = all.firstWhere(
        (n) => n.id.startsWith(thoughtId),
        orElse: () => Thought(title: '', content: ''),
      );
      if (existing.title.isEmpty) existing = null;
    }

    final thought = existing != null
        ? existing.copyWith(
            title: args['title'],
            content: args['content'],
            tags: (args['tags'] as List?)?.cast<String>(),
            folder: args['folder'],
          )
        : Thought(
            title: args['title'] as String,
            content: args['content'] as String,
            tags: (args['tags'] as List?)?.cast<String>() ?? [],
            folder: args['folder'] as String? ?? 'Inbox',
          );

    await repository.save(thought);
    final action = existing != null ? 'Updated' : 'Saved';
    return '$action thought "${thought.title}" in ${thought.folder} (id: ${thought.id.substring(0, 8)})';
  }

  String _searchThoughts(Map<String, dynamic> args) {
    final results = repository.search(
      args['query'] as String,
      folder: args['folder'] as String?,
      tag: args['tag'] as String?,
    );
    if (results.isEmpty) return 'No thoughts found.';
    return 'Found ${results.length} thought(s): '
        '${results.map((n) => '"${n.title}"[${n.id.substring(0, 8)}]').join(', ')}';
  }

  String _listThoughts(Map<String, dynamic> args) {
    final folder = args['folder'] as String?;
    final byFolder = repository.getThoughtsByFolder();

    if (byFolder.isEmpty) return 'No thoughts yet.';

    final filtered = folder != null
        ? byFolder.entries.where((e) => e.key.toLowerCase().contains(folder.toLowerCase()))
        : byFolder.entries;

    return filtered
        .map((e) =>
            '${e.key}: ${e.value.map((n) => '"${n.title}"').join(', ')}')
        .join(' | ');
  }

  Future<String> _deleteThought(Map<String, dynamic> args) async {
    final thoughtId = args['thought_id'] as String;
    final all = repository.getAll();
    final thought = all.firstWhere(
      (n) => n.id.startsWith(thoughtId),
      orElse: () => Thought(title: '', content: ''),
    );
    if (thought.title.isEmpty) return 'Thought not found.';
    await repository.delete(thought.id);
    return 'Deleted "${thought.title}"';
  }

  String _organizeThoughts(Map<String, dynamic> args) {
    final action = args['action'] as String;
    final byFolder = repository.getThoughtsByFolder();

    if (byFolder.isEmpty) return 'No thoughts to organize yet.';

    final summary = byFolder.entries
        .map((e) => '${e.key}(${e.value.length})')
        .join(', ');

    if (action == 'suggest') {
      final total = repository.getAll().length;
      return 'You have $total thoughts across: $summary. '
          'I can suggest a cleaner structure, merge duplicates, add tags, '
          'or apply a framework like PARA or GTD. What would you like?';
    }

    return 'Organization reviewed. Current structure: $summary';
  }

  // ── HTTP ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _callGroq(List<Map<String, dynamic>> messages) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'tools': _tools,
        'tool_choice': 'auto',
        'max_tokens': 1024,
        'temperature': 0.4,
      }),
    );

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['error']?['message'] ?? 'Groq API error ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
