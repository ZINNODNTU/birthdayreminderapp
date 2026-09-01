import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../ai/data/ai_config_repository.dart';
import '../../ai/domain/ai_provider.dart';
import '../../ai/services/ai_client.dart';
import '../../../l10n/l10n_extensions.dart';

class AiSettingsCard extends StatefulWidget {
  const AiSettingsCard({super.key});

  @override
  State<AiSettingsCard> createState() => _AiSettingsCardState();
}

class _AiSettingsCardState extends State<AiSettingsCard> {
  late AiProviderConfig _config;
  String _maskedKey = '';
  bool _busy = false;
  bool _obscureApiKey = true;
  String? _statusMessage;
  bool _statusOk = false;
  List<String> _models = const <String>[];

  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _modelCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _tempCtrl;
  late final TextEditingController _maxTokensCtrl;

  @override
  void initState() {
    super.initState();
    _config = context.read<AiConfigRepository>().loadConfig();
    _baseUrlCtrl = TextEditingController(text: _config.baseUrl);
    _modelCtrl = TextEditingController(text: _config.model);
    _apiKeyCtrl = TextEditingController();
    _tempCtrl = TextEditingController(text: _config.temperature.toString());
    _maxTokensCtrl = TextEditingController(text: _config.maxTokens.toString());
    _loadMaskedKey();
  }

  Future<void> _loadMaskedKey() async {
    final repo = context.read<AiConfigRepository>();
    final raw = await repo.readApiKey(_config.provider);
    if (!mounted) return;
    setState(() => _maskedKey = ApiKeyMask.mask(raw));
  }

  /// Build an [AiProviderConfig] from the CURRENT visible inputs so
  /// every action that consumes config (test / fetchModels / chat /
  /// save) is using the same draft.
  AiProviderConfig _draftConfigFromInputs() {
    final temp = double.tryParse(_tempCtrl.text.trim());
    final maxTokens = int.tryParse(_maxTokensCtrl.text.trim());
    var baseUrl = _baseUrlCtrl.text.trim();
    if (_config.provider == AiProviderType.openAiCompatible &&
        baseUrl.isEmpty) {
      baseUrl = 'https://api.openai.com/v1';
    } else if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return _config.copyWith(
      baseUrl: baseUrl,
      model: _modelCtrl.text.trim(),
      temperature: temp ?? _config.temperature,
      maxTokens: maxTokens ?? _config.maxTokens,
    );
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    _modelCtrl.dispose();
    _apiKeyCtrl.dispose();
    _tempCtrl.dispose();
    _maxTokensCtrl.dispose();
    super.dispose();
  }

  Future<String> _resolveApiKey() async {
    final visible = _apiKeyCtrl.text.trim();
    if (visible.isNotEmpty) return visible;
    final repo = context.read<AiConfigRepository>();
    final stored = await repo.readApiKey(_config.provider);
    return stored ?? '';
  }

  Future<void> _pasteApiKey() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await Clipboard.getData('text/plain');
      final value = (data?.text ?? '').trim();
      if (value.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Clipboard không có API key.')),
        );
        return;
      }
      _apiKeyCtrl.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      setState(() {});
      messenger.showSnackBar(
        SnackBar(content: Text('Đã dán API key (${value.length} ký tự).')),
      );
    } catch (e, st) {
      AppLogger.warn('AiSettings', 'paste clipboard failed: $e\n$st');
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<AiConfigRepository>();
    final draft = _draftConfigFromInputs();
    if (draft.model.isEmpty) {
      setState(() {
        _statusMessage = 'Vui lòng nhập model.';
        _statusOk = false;
      });
      return;
    }
    setState(() => _busy = true);
    try {
      AppLogger.info(
        'AiSettings',
        'save provider=${draft.provider.name} '
            'modelPresent=${draft.model.isNotEmpty} '
            'baseUrlPresent=${draft.baseUrl.isNotEmpty} '
            'apiKeyPresent=${_apiKeyCtrl.text.trim().isNotEmpty}',
      );
      await repo.saveConfig(draft);
      final key = _apiKeyCtrl.text.trim();
      if (key.isNotEmpty) {
        final result = await repo.writeApiKey(draft.provider, key);
        AppLogger.info(
          'AiSettings',
          'secureWrite=${result.ok ? 'success' : 'failed'} '
              'length=${result.length ?? 0}',
        );
      }
      _apiKeyCtrl.clear();
      setState(() => _config = draft);
      await _loadMaskedKey();
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Đã lưu cấu hình và API key an toàn.';
        _statusOk = true;
      });
    } catch (e, st) {
      AppLogger.warn('AiSettings', 'save failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _statusMessage = _sanitizeError(e.toString());
        _statusOk = false;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      messenger.hideCurrentSnackBar();
    }
  }

  Future<void> _test() async {
    setState(() => _busy = true);
    try {
      final draft = _draftConfigFromInputs();
      if (_apiKeyCtrl.text.trim().isEmpty && _maskedKey.isEmpty) {
        setState(() {
          _statusMessage = 'Vui lòng nhập API key.';
          _statusOk = false;
        });
        return;
      }
      if (draft.model.isEmpty) {
        setState(() {
          _statusMessage = 'Vui lòng nhập model.';
          _statusOk = false;
        });
        return;
      }
      AppLogger.info(
        'AiTest',
        'start provider=${draft.provider.name} '
            'modelPresent=${draft.model.isNotEmpty} '
            'baseUrlPresent=${draft.baseUrl.isNotEmpty}',
      );
      final client = context.read<AiClient>();
      final key = await _resolveApiKey();
      final stopwatch = Stopwatch()..start();
      final result = await client.testConnection(config: draft, apiKey: key);
      stopwatch.stop();
      AppLogger.info(
        'AiTest',
        'status=${result.ok ? 'ok' : (result.errorCode ?? 'error')} '
            'latencyMs=${result.latencyMs ?? stopwatch.elapsedMilliseconds}',
      );
      if (!mounted) return;
      setState(() {
        if (result.ok) {
          _statusOk = true;
          _statusMessage =
              'Kết nối thành công (${result.latencyMs} ms) — Phản hồi: "${result.reply}"';
        } else {
          _statusOk = false;
          _statusMessage = _localizeError(result);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fetchModels() async {
    setState(() => _busy = true);
    try {
      final draft = _draftConfigFromInputs();
      if (draft.baseUrl.isEmpty) {
        setState(() {
          _statusMessage = 'Vui lòng nhập Base URL.';
          _statusOk = false;
        });
        return;
      }
      final client = context.read<AiClient>();
      final key = await _resolveApiKey();
      final models = await client.listModels(config: draft, apiKey: key);
      if (!mounted) return;
      setState(() {
        _models = models;
        _statusMessage = models.isEmpty
            ? 'Không lấy được danh sách model — nhập ID thủ công.'
            : 'Đã tải ${models.length} model.';
        _statusOk = models.isNotEmpty;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clearKey() async {
    final repo = context.read<AiConfigRepository>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await repo.clearApiKey(_config.provider);
      _apiKeyCtrl.clear();
      await _loadMaskedKey();
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Đã xoá API key.';
        _statusOk = true;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Đã xoá API key.')));
    } catch (e, st) {
      AppLogger.warn('AiSettings', 'clear failed: $e\n$st');
    }
  }

  String _sanitizeError(String raw) {
    if (raw.toLowerCase().contains('missing_plugin_exception') ||
        raw.toLowerCase().contains('platform_exception')) {
      return 'Không thể lưu API key an toàn trên thiết bị.';
    }
    return 'Lỗi không xác định.';
  }

  String _localizeError(AiConnectionResult r) {
    switch (r.errorCode) {
      case 'missing_api_key':
        return 'Vui lòng nhập API key.';
      case 'missing_model':
        return 'Vui lòng nhập model.';
      case 'unauthorized':
      case 'http_401':
      case 'http_403':
        return 'API key không hợp lệ hoặc không có quyền truy cập.';
      case 'model_not_found':
      case 'http_404':
        return 'Không tìm thấy model hoặc endpoint.';
      case 'http_429':
        return 'Đã vượt giới hạn yêu cầu/quota.';
      case 'timeout':
        return 'Quá thời gian kết nối.';
      case 'network':
        return 'Không thể kết nối tới máy chủ.';
      case 'secure_storage_error':
        return 'Không thể lưu API key an toàn trên thiết bị.';
      default:
        return r.errorMessage ?? 'Nhà cung cấp từ chối yêu cầu.';
    }
  }

  void _switchProvider(AiProviderType v) {
    _apiKeyCtrl.clear();
    setState(() {
      _config = _config.copyWith(provider: v);
      _models = const <String>[];
      _statusMessage = null;
    });
    _loadMaskedKey();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.artificialIntelligence,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<AiProviderType>(
              decoration: InputDecoration(labelText: context.l10n.provider),
              initialValue: _config.provider,
              onChanged: (v) {
                if (v == null) return;
                _switchProvider(v);
              },
              items: [
                DropdownMenuItem(
                  value: AiProviderType.openAiCompatible,
                  child: Text(context.l10n.openAiCompatible),
                ),
                const DropdownMenuItem(
                  value: AiProviderType.gemini,
                  child: Text('Google Gemini'),
                ),
                const DropdownMenuItem(
                  value: AiProviderType.anthropic,
                  child: Text('Anthropic'),
                ),
              ],
            ),
            if (_config.provider == AiProviderType.openAiCompatible)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: _baseUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://api.openai.com/v1',
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _modelCtrl,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _apiKeyCtrl,
                obscureText: _obscureApiKey,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  helperText: _maskedKey.isEmpty
                      ? context.l10n.apiKeyNotSaved
                      : context.l10n.apiKeyCurrent(_maskedKey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _obscureApiKey
                            ? context.l10n.showApiKey
                            : context.l10n.hideApiKey,
                        icon: Icon(
                          _obscureApiKey
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                      IconButton(
                        tooltip: context.l10n.pasteClipboard,
                        icon: const Icon(Icons.paste),
                        onPressed: _pasteApiKey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tempCtrl,
                    decoration: const InputDecoration(labelText: 'Temperature'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxTokensCtrl,
                    decoration: const InputDecoration(labelText: 'Max tokens'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _test,
                  icon: const Icon(Icons.network_check),
                  label: Text(context.l10n.testConnection),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _fetchModels,
                  icon: const Icon(Icons.list_alt),
                  label: Text(context.l10n.fetchModels),
                ),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(context.l10n.saveConfiguration),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _clearKey,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.deleteApiKey),
                ),
              ],
            ),
            if (_statusMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    color: _statusOk
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            if (_models.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  children: _models
                      .take(20)
                      .map(
                        (m) => ActionChip(
                          label: Text(m),
                          onPressed: () {
                            _modelCtrl.text = m;
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
