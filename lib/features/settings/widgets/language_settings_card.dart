import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n_extensions.dart';
import '../../../services/locale_service.dart';
import '../../../theme/mid_autumn_theme.dart';

class LanguageSettingsCard extends StatelessWidget {
  const LanguageSettingsCard({super.key});

  static const _languages = [
    ('vi', '🇻🇳', 'Tiếng Việt'),
    ('en', '🇺🇸', 'English'),
    ('zh', '🇨🇳', '中文'),
  ];

  @override
  Widget build(BuildContext context) {
    final localeService = context.watch<LocaleService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.language_rounded,
                color: MidAutumnColors.moon,
              ),
              title: Text(
                context.l10n.language,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(context.l10n.selectLanguage),
            ),
            const SizedBox(height: 6),
            for (final language in _languages)
              RadioListTile<String>(
                key: ValueKey('language_${language.$1}'),
                value: language.$1,
                groupValue: localeService.locale.languageCode,
                onChanged: (value) {
                  if (value != null) localeService.setLocale(value);
                },
                activeColor: MidAutumnColors.lantern,
                title: Text('${language.$2}  ${language.$3}'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
