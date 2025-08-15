import 'package:flutter/material.dart';
import 'basics_screen.dart';
import 'algorithms_screen.dart';
import 'circuit_simulator_screen.dart';
import 'learning_screen.dart';
import 'quantum_network_screen.dart';
import 'advanced_features_screen.dart';
import '../ui/style.dart';
import '../l10n/generated/app_localizations.dart';
import '../main.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final cards = [
      _FeatureCard(
        title: t.cardCircuitSimulator,
        subtitle: t.cardCircuitSimulatorSubtitle,
        icon: Icons.memory_rounded,
        heroTag: HeroTags.circuit,
        gradient: const [Color(0xFF5E5CE6), Color(0xFF7D7AFF)],
        onTap: () => _open(context, const CircuitSimulatorScreen()),
      ),
      _FeatureCard(
        title: t.cardAlgorithms,
        subtitle: t.cardAlgorithmsSubtitle,
        icon: Icons.auto_graph_rounded,
        heroTag: HeroTags.algorithms,
        gradient: const [Color(0xFF64D2FF), Color(0xFF5AC8FA)],
        onTap: () => _open(context, const AlgorithmsScreen()),
      ),
      _FeatureCard(
        title: t.cardBasics,
        subtitle: t.cardBasicsSubtitle,
        icon: Icons.bubble_chart_rounded,
        heroTag: HeroTags.basics,
        gradient: const [Color(0xFF30D158), Color(0xFF34C759)],
        onTap: () => _open(context, const BasicsScreen()),
      ),
      _FeatureCard(
        title: t.cardLearning,
        subtitle: t.cardLearningSubtitle,
        icon: Icons.school_rounded,
        heroTag: HeroTags.learning,
        gradient: const [Color(0xFFFF9F0A), Color(0xFFFFB340)],
        onTap: () => _open(context, const LearningScreen()),
      ),
      _FeatureCard(
        title: t.cardNetwork,
        subtitle: t.cardNetworkSubtitle,
        icon: Icons.hub_rounded,
        heroTag: HeroTags.network,
        gradient: const [Color(0xFFFF375F), Color(0xFFFF2D55)],
        onTap: () => _open(context, const QuantumNetworkScreen()),
      ),
      _FeatureCard(
        title: t.cardAdvanced,
        subtitle: t.cardAdvancedSubtitle,
        icon: Icons.science_rounded,
        heroTag: HeroTags.advanced,
        gradient: const [Color(0xFF8E8E93), Color(0xFF5E5CE6)],
        onTap: () => _open(context, const AdvancedFeaturesScreen()),
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsetsDirectional.only(
                start: 20,
                bottom: 16,
              ),
              background: _HeaderGradient(),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t.appTitle),
                  const SizedBox(width: 12),
                  _LocaleToggle(),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                t.homeTagline,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 16, height: 1.35),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (c, i) => cards[i],
                childCount: cards.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: 0.95,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: 0.95,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation.drive(tween), child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }
}

class _HeaderGradient extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFDEE4FF), Color(0xFFF5F5F7)],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Opacity(
            opacity: 0.15,
            child: Icon(
              Icons.blur_on_rounded,
              size: 120,
              color: Colors.indigo.shade400,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final String? heroTag;
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [
            BoxShadow(
              color: gradient.last.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: heroTag == null
                    ? Icon(icon, size: 34, color: Colors.white.withOpacity(0.9))
                    : Hero(
                        tag: heroTag!,
                        child: Icon(
                          icon,
                          size: 34,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocaleToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final isVi = lang == 'vi';
    return GestureDetector(
      onTap: () => setAppLocale(isVi ? const Locale('en') : const Locale('vi')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          isVi ? 'VI' : 'EN',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
