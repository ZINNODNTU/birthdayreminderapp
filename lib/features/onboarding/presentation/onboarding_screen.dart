import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/onboarding_page_data.dart';
import '../services/onboarding_service.dart';
import '../widgets/onboarding_indicator.dart';
import 'onboarding_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.manual = false});
  final bool manual;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close({required bool complete}) async {
    if (complete) await context.read<OnboardingService>().complete();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_page == OnboardingPageData.pages.length - 1) {
      _close(complete: !widget.manual);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<bool> _back() async {
    if (_page > 0) {
      await _controller.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return false;
    }
    if (widget.manual) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == OnboardingPageData.pages.length - 1;
    return PopScope(
      canPop: widget.manual && _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('onboarding-skip'),
                  onPressed:
                      widget.manual
                          ? () => _close(complete: false)
                          : () => _close(complete: true),
                  child: Text(widget.manual ? 'Đóng' : 'Bỏ qua'),
                ),
              ),
              Expanded(
                child: PageView(
                  key: const Key('onboarding-pages'),
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _page = value),
                  children:
                      OnboardingPageData.pages
                          .map((data) => OnboardingPage(data: data))
                          .toList(),
                ),
              ),
              OnboardingIndicator(
                current: _page,
                count: OnboardingPageData.pages.length,
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('onboarding-primary'),
                    onPressed: _next,
                    child: Text(
                      last
                          ? (widget.manual ? 'Đóng' : 'Bắt đầu sử dụng')
                          : 'Tiếp theo',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
