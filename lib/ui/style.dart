import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Centralized design tokens & helpers.
class AppStyle {
  static const double hPad = 20;
  static const double vPad = 20;
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(20));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(14));

  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.fromLTRB(
    hPad,
    kToolbarHeight + 16,
    hPad,
    vPad + MediaQuery.paddingOf(context).bottom,
  );

  static Gradient pageGradient(BuildContext context, Color accent) =>
      LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withOpacity(0.18), Colors.transparent],
      );

  static TextStyle get sectionTitle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static TextStyle get monoSmall =>
      const TextStyle(fontFamily: 'monospace', fontSize: 12);

  static TextStyle headlineSmall(BuildContext context) => Theme.of(context)
      .textTheme
      .titleLarge!
      .copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5);
}

class SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget child;
  final Widget? illustration; // optional small illustrative widget / image
  const SectionCard({
    super.key,
    this.title,
    this.actions,
    this.illustration,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(title!, style: AppStyle.sectionTitle),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            if (title != null) const SizedBox(height: 8),
            if (illustration != null) ...[
              SizedBox(
                height: 80,
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerLeft,
                  child: illustration!,
                ),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Hero tag constants
class HeroTags {
  static const circuit = 'feature:circuit';
  static const algorithms = 'feature:algorithms';
  static const basics = 'feature:basics';
  static const learning = 'feature:learning';
  static const network = 'feature:network';
  static const advanced = 'feature:advanced';
}
