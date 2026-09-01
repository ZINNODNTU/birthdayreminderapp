import 'package:flutter/material.dart';

import '../domain/onboarding_page_data.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.data});
  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        children: [
          Semantics(
            label: data.title,
            child: Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primaryContainer, colors.tertiaryContainer],
                ),
                borderRadius: BorderRadius.circular(44),
              ),
              child: Icon(
                data.icon,
                size: 88,
                color: colors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: data.highlights
                .map(
                  (text) => Chip(
                    avatar: Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: colors.primary,
                    ),
                    label: Text(text),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
