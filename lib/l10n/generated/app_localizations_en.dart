// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Quantum Calculator';

  @override
  String get homeTagline =>
      'Explore quantum computing via visual simulation, canonical algorithms, and distributed quantum networking.';

  @override
  String get cardCircuitSimulator => 'Circuit Simulator';

  @override
  String get cardCircuitSimulatorSubtitle => 'Build, run & measure';

  @override
  String get cardAlgorithms => 'Algorithms';

  @override
  String get cardAlgorithmsSubtitle => 'Deutsch-Jozsa, Grover...';

  @override
  String get cardBasics => 'Basics';

  @override
  String get cardBasicsSubtitle => 'Superposition & entanglement';

  @override
  String get cardLearning => 'Learning Mode';

  @override
  String get cardLearningSubtitle => 'Lessons & Quizzes';

  @override
  String get cardNetwork => 'Quantum Network';

  @override
  String get cardNetworkSubtitle => 'Distributed & teleportation';

  @override
  String get cardAdvanced => 'Advanced';

  @override
  String get cardAdvancedSubtitle => 'Optimization • QFT • QEC';

  @override
  String get tabCircuitOptimization => 'Circuit Optimization';

  @override
  String get tabEntanglement => 'Entanglement';

  @override
  String get tabErrorCorrection => 'Error Correction';

  @override
  String get tabShorCode => 'Shor Code';

  @override
  String get tabTeleportation => 'Teleportation';

  @override
  String get tabQft => 'QFT';

  @override
  String get tabHybridVqe => 'Hybrid VQE';

  @override
  String get tabRng => 'Quantum RNG';

  @override
  String get tabQml => 'QML (QSVM/QNN)';

  @override
  String get tabQkd => 'QKD (BB84)';

  @override
  String get tabSynthesis => 'Circuit Synthesis';
}
