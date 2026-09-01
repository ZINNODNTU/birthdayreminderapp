import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/locale_service.dart';
import '../l10n/l10n_extensions.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  static const _locales = {'vi': '🇻🇳', 'en': '🇺🇸', 'zh': '🇨🇳'};

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    final l10n = context.l10n;
    final currentCode = localeService.locale.languageCode;
    final flag = _locales[currentCode] ?? '🌐';

    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 20),
        ],
      ),
      offset: const Offset(0, 40),
      tooltip: l10n.chooseLanguage,
      itemBuilder: (context) => [
        _buildItem(context, 'vi', l10n.languageVi, currentCode),
        _buildItem(context, 'en', l10n.languageEn, currentCode),
        _buildItem(context, 'zh', l10n.languageZh, currentCode),
      ],
      onSelected: (code) => localeService.setLocale(code),
    );
  }

  PopupMenuItem<String> _buildItem(
    BuildContext context,
    String code,
    String label,
    String currentCode,
  ) {
    final isSelected = code == currentCode;
    final flag = _locales[code] ?? '🌐';
    return PopupMenuItem<String>(
      value: code,
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isSelected) const Icon(Icons.check, color: Colors.blue, size: 18),
        ],
      ),
    );
  }
}
