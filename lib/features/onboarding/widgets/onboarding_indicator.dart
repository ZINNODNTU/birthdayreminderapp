import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.current,
    required this.count,
  });
  final int current;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Trang ${current + 1} trên $count',
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (index) => AnimatedContainer(
          key: ValueKey('onboarding-dot-$index'),
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == current ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: index == current
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    ),
  );
}
