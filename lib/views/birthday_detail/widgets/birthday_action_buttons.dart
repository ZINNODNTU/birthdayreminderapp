import 'package:flutter/material.dart';

/// Action buttons for gift and wish suggestions.
class BirthdayActionButtons extends StatelessWidget {
  const BirthdayActionButtons({
    super.key,
    required this.onGiftTap,
    required this.onWishTap,
    required this.isGiftLoading,
    required this.isWishLoading,
    required this.wishLanguage,
    required this.onWishLanguageChanged,
  });

  final VoidCallback onGiftTap;
  final VoidCallback onWishTap;
  final bool isGiftLoading;
  final bool isWishLoading;
  final String wishLanguage;
  final ValueChanged<String> onWishLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 380;
    final giftButton = _GradientActionButton(
      icon: Icons.card_giftcard,
      label: isGiftLoading ? 'AI đang suy nghĩ...' : 'Gợi ý quà tặng',
      loading: isGiftLoading,
      gradient: const LinearGradient(
        colors: [Color(0xFF7C4DFF), Color(0xFFEC407A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onPressed: isGiftLoading ? null : onGiftTap,
    );
    if (isNarrow) {
      return Column(
        children: [
          SizedBox(width: double.infinity, child: giftButton),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: _buildWishButton(context)),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: giftButton),
        const SizedBox(width: 12),
        Expanded(child: _buildWishButton(context)),
      ],
    );
  }

  Widget _buildWishButton(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final narrow = c.maxWidth < 240;
        final picker = DropdownButtonFormField<String>(
          initialValue: wishLanguage,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Ngôn ngữ',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(
              value: 'vi',
              child: Text('Tiếng Việt', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'en',
              child: Text('Tiếng Anh', overflow: TextOverflow.ellipsis),
            ),
            DropdownMenuItem(
              value: 'zh',
              child: Text('Tiếng Trung', overflow: TextOverflow.ellipsis),
            ),
          ],
          onChanged: (v) {
            if (v != null) onWishLanguageChanged(v);
          },
        );
        final btn = _GradientActionButton(
          icon: Icons.message,
          label: isWishLoading ? 'AI đang suy nghĩ...' : 'Gợi ý câu chúc',
          loading: isWishLoading,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6F00), Color(0xFFD32F2F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          onPressed: isWishLoading ? null : onWishTap,
        );
        if (narrow) {
          return Column(
            children: [
              picker,
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: btn),
            ],
          );
        }
        return Row(
          children: [
            Flexible(child: picker),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: btn),
          ],
        );
      },
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.gradient,
    required this.loading,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: onPressed == null ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
