import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/agent/providers.dart';
import '../../core/models/thought.dart';
import '../../shared/theme/app_theme.dart';

class ThoughtsScreen extends ConsumerStatefulWidget {
  const ThoughtsScreen({super.key});

  @override
  ConsumerState<ThoughtsScreen> createState() => _ThoughtsScreenState();
}

class _ThoughtsScreenState extends ConsumerState<ThoughtsScreen> {
  String? _selectedFolder;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final allThoughts = ref.watch(thoughtsProvider);
    final repo = ref.watch(thoughtRepositoryProvider);
    final folders = repo.getFolders();

    // Filter
    final thoughts = _searchQuery.isNotEmpty
        ? repo.search(_searchQuery, folder: _selectedFolder)
        : _selectedFolder != null
            ? allThoughts.where((n) => n.folder == _selectedFolder).toList()
            : allThoughts;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search thoughts…',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Folder chips
        if (folders.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: [
                _FolderChip(
                  label: 'All',
                  selected: _selectedFolder == null,
                  onTap: () => setState(() => _selectedFolder = null),
                ),
                ...folders.map((f) => _FolderChip(
                      label: f,
                      selected: _selectedFolder == f,
                      onTap: () => setState(
                          () => _selectedFolder = _selectedFolder == f ? null : f),
                    )),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Thoughts list
        Expanded(
          child: thoughts.isEmpty
              ? _EmptyState(_searchQuery)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: thoughts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _ThoughtCard(
                    thought: thoughts[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThoughtDetailScreen(thought: thoughts[i]),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _FolderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FolderChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppTheme.purple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _ThoughtCard extends StatelessWidget {
  final Thought thought;
  final VoidCallback onTap;

  const _ThoughtCard({required this.thought, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    thought.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  thought.folder,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              thought.content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (thought.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: thought.tags
                    .map((t) => _Tag(label: t))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.purpleLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppTheme.purpleDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState(this.query);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notes, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            query.isNotEmpty ? 'No thoughts match "$query"' : 'No thoughts yet',
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 6),
          Text(
            'Chat with the agent to add your first one',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ── Thought detail ───────────────────────────────────────────────────────────────

class ThoughtDetailScreen extends ConsumerWidget {
  final Thought thought;
  const ThoughtDetailScreen({super.key, required this.thought});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(thought.folder),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final repo = ref.read(thoughtRepositoryProvider);
              await repo.delete(thought.id);
              ref.read(thoughtsProvider.notifier).refresh();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              thought.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            if (thought.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                children: thought.tags.map((t) => _Tag(label: t)).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              thought.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Created ${_formatDate(thought.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year} at ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
