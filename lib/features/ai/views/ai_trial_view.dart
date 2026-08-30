import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/ai_config_repository.dart';
import '../domain/ai_provider.dart';
import '../services/ai_client.dart';

class AiTrialView extends StatefulWidget {
  const AiTrialView({super.key});

  @override
  State<AiTrialView> createState() => _AiTrialViewState();
}

class _AiTrialViewState extends State<AiTrialView> {
  final TextEditingController _prompt = TextEditingController();
  AiConnectionResult? _result;
  bool _busy = false;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      final repo = context.read<AiConfigRepository>();
      final client = context.read<AiClient>();
      final config = repo.loadConfig();
      final hasKey = await repo.hasApiKey(config.provider);
      if (!hasKey) {
        if (!mounted) return;
        setState(() {
          _result = AiConnectionResult.failure(
            code: 'missing_api_key',
            message: 'Chưa có API key cho nhà cung cấp này.',
          );
        });
        return;
      }
      final key = await repo.readApiKey(config.provider) ?? '';
      final r = await client.chat(
        config: config,
        apiKey: key,
        prompt: _prompt.text.trim().isEmpty ? 'Xin chào!' : _prompt.text.trim(),
      );
      if (!mounted) return;
      setState(() => _result = r);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _providerLabel(AiProviderType p) {
    switch (p) {
      case AiProviderType.openAiCompatible:
        return 'OpenAI / tương thích';
      case AiProviderType.gemini:
        return 'Google Gemini';
      case AiProviderType.anthropic:
        return 'Anthropic';
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<AiConfigRepository>().loadConfig();
    return Scaffold(
      appBar: AppBar(title: const Text('Thử AI')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nhà cung cấp: ${_providerLabel(config.provider)}'),
                    Text(
                      'Model: ${config.model.isEmpty ? "(chưa đặt)" : config.model}',
                    ),
                    Text(
                      config.baseUrl.isEmpty
                          ? 'Base URL: (mặc định)'
                          : 'Base URL: ${config.baseUrl}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prompt,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Câu hỏi thử',
                hintText: 'Nhập prompt rồi nhấn Gửi',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _busy ? null : _send,
              icon: const Icon(Icons.send),
              label: const Text('Gửi'),
            ),
            const SizedBox(height: 16),
            if (_busy) const LinearProgressIndicator(),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SelectableText(
                  _result!.ok
                      ? 'Phản hồi (${_result!.latencyMs} ms):\n\n${_result!.reply}'
                      : 'Lỗi: ${_result!.errorCode}'
                          '${_result!.errorMessage != null ? ' — ${_result!.errorMessage}' : ''}',
                  style: TextStyle(
                    color: _result!.ok ? Colors.black87 : Colors.red.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
