import 'package:flutter/material.dart';

import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onFinished,
    super.key,
  });

  final Future<void> Function() onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    (
      icon: Icons.spa_rounded,
      title: 'Build your flow',
      text: 'Create small habits and make them part of your day.',
    ),
    (
      icon: Icons.local_fire_department_rounded,
      title: 'Keep the streak',
      text: 'Check in, build momentum, and see your best runs.',
    ),
    (
      icon: Icons.insights_rounded,
      title: 'See the bigger picture',
      text: 'Use goals, stats, and your activity grid to stay consistent.',
    ),
  ];

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page == _pages.length - 1) {
      await widget.onFinished();
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynoxFowApp.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: Align(
                alignment: Alignment.centerRight,
                child: _page == _pages.length - 1
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: widget.onFinished,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: FynoxFowApp.darkPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (value) {
                  if (mounted) setState(() => _page = value);
                },
                itemBuilder: (_, index) {
                  final page = _pages[index];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 10, 28, 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 175,
                              height: 175,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF3E5F5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                page.icon,
                                size: 78,
                                color: FynoxFowApp.darkPrimary,
                              ),
                            ),
                            const SizedBox(height: 36),
                            const Text(
                              'Fynox Flow',
                              style: TextStyle(
                                color: FynoxFowApp.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 30,
                                height: 1.08,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              page.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: index == _page ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index == _page
                              ? FynoxFowApp.darkPrimary
                              : const Color(0xFFE1BEE7),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      style: FilledButton.styleFrom(
                        backgroundColor: FynoxFowApp.primary,
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: Text(
                        _page == _pages.length - 1
                            ? 'Start my flow'
                            : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
