import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/agent/providers.dart';
import '../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _keyController;
  bool _obscure = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: ref.read(apiKeyProvider));
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(apiKeyProvider.notifier).set(_keyController.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final thoughtCount = ref.watch(thoughtsProvider).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),

        // API Key section
        _SectionHeader('Groq API Key'),
        const SizedBox(height: 8),
        Text(
          'Get a free key at console.groq.com — stored locally on your device only.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _keyController,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'gsk_...',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _saved ? AppTheme.teal : AppTheme.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_saved ? 'Saved!' : 'Save API Key'),
          ),
        ),

        const SizedBox(height: 32),

        // Stats section
        _SectionHeader('Your thoughts'),
        const SizedBox(height: 12),
        _StatRow(label: 'Total thoughts', value: '$thoughtCount'),

        const SizedBox(height: 32),

        // Model info
        _SectionHeader('Agent'),
        const SizedBox(height: 8),
        _InfoRow('Model', 'llama-3.1-8b-instant (Groq)'),
        _InfoRow('Context window', '128k tokens'),
        _InfoRow('Speed', '~500 tokens/sec'),
        _InfoRow('Cost', 'Free tier available'),

        const SizedBox(height: 32),

        // About
        _SectionHeader('About'),
        const SizedBox(height: 8),
        Text(
          'ThoughtFlow is your AI-powered second brain. '
          'Chat naturally to capture ideas, and let the agent organize, '
          'search and surface them for you.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.purple,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
