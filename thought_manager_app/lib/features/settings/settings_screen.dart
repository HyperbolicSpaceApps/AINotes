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
  late TextEditingController _groqController;
  late TextEditingController _jinaController;
  bool _obscureGroq = true;
  bool _obscureJina = true;
  bool _savedGroq = false;
  bool _savedJina = false;

  @override
  void initState() {
    super.initState();
    _groqController = TextEditingController(text: ref.read(groqApiKeyProvider));
    _jinaController = TextEditingController(text: ref.read(jinaApiKeyProvider));
  }

  @override
  void dispose() {
    _groqController.dispose();
    _jinaController.dispose();
    super.dispose();
  }

  Future<void> _saveGroq() async {
    await ref.read(groqApiKeyProvider.notifier).set(_groqController.text.trim());
    setState(() => _savedGroq = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedGroq = false);
    });
  }

  Future<void> _saveJina() async {
    await ref.read(jinaApiKeyProvider.notifier).set(_jinaController.text.trim());
    setState(() => _savedJina = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _savedJina = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final thoughtCount = ref.watch(thoughtsProvider).length;
    final embeddedCount = ref.watch(thoughtsProvider).where((t) => t.embedding != null).length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),

        // Groq API Key
        _SectionHeader('Groq API Key'),
        const SizedBox(height: 8),
        Text(
          'Get a free key at console.groq.com — used for the AI agent.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        _ApiKeyField(
          controller: _groqController,
          obscure: _obscureGroq,
          hint: 'gsk_...',
          onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
        ),
        const SizedBox(height: 10),
        _SaveButton(saved: _savedGroq, onTap: _saveGroq),

        const SizedBox(height: 32),

        // Jina API Key
        _SectionHeader('Jina API Key'),
        const SizedBox(height: 8),
        Text(
          'Get a free key at jina.ai — used to embed your thoughts for semantic search.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
        _ApiKeyField(
          controller: _jinaController,
          obscure: _obscureJina,
          hint: 'jina-...',
          onToggleObscure: () => setState(() => _obscureJina = !_obscureJina),
        ),
        const SizedBox(height: 10),
        _SaveButton(saved: _savedJina, onTap: _saveJina),

        const SizedBox(height: 32),

        // Stats
        _SectionHeader('Your thoughts'),
        const SizedBox(height: 12),
        _StatRow(label: 'Total thoughts', value: '$thoughtCount'),
        const SizedBox(height: 8),
        _StatRow(label: 'Embedded', value: '$embeddedCount / $thoughtCount'),

        const SizedBox(height: 32),

        // Agent info
        _SectionHeader('Agent'),
        const SizedBox(height: 8),
        _InfoRow('LLM', 'llama-3.1-8b-instant (Groq)'),
        _InfoRow('Embeddings', 'jina-embeddings-v3'),
        _InfoRow('Search', 'dot product'),
        _InfoRow('Cost', 'Both free tier'),

        const SizedBox(height: 32),

        // About
        _SectionHeader('About'),
        const SizedBox(height: 8),
        Text(
          'ThoughtManager is your AI-powered second brain. '
          'Chat naturally to capture ideas — thoughts are embedded as vectors '
          'and retrieved by meaning, not keywords.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
        ),
      ],
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _ApiKeyField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final String hint;
  final VoidCallback onToggleObscure;

  const _ApiKeyField({
    required this.controller,
    required this.obscure,
    required this.hint,
    required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggleObscure,
        ),
      ),
      style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool saved;
  final VoidCallback onTap;

  const _SaveButton({required this.saved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: saved ? AppTheme.teal : AppTheme.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(saved ? 'Saved!' : 'Save API Key'),
      ),
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
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}