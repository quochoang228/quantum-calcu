// import 'package:flutter/widgets.dart';

// /// Lightweight manual localization layer (stand-in for generated l10n).
// /// For production, run: flutter gen-l10n --arb-dir=lib/l10n --output-dir=lib/l10n
// class AppLocalizations {
//   final Locale locale;
//   AppLocalizations(this.locale);

//   static const LocalizationsDelegate<AppLocalizations> delegate =
//       _AppLocDelegate();

//   static AppLocalizations of(BuildContext context) {
//     return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
//   }

//   static const supportedLocales = [Locale('en'), Locale('vi')];

//   bool get isVi => locale.languageCode == 'vi';

//   String get appTitle => isVi ? 'Máy tính Lượng tử' : 'Quantum Calculator';
//   String get homeTagline => isVi
//       ? 'Khám phá điện toán lượng tử qua mô phỏng trực quan, các thuật toán kinh điển và mạng lượng tử phân tán.'
//       : 'Explore quantum computing via visual simulation, canonical algorithms, and distributed quantum networking.';

//   String get cardCircuitSimulator =>
//       isVi ? 'Mô phỏng Mạch' : 'Circuit Simulator';
//   String get cardCircuitSimulatorSubtitle =>
//       isVi ? 'Tạo, chạy & đo' : 'Build, run & measure';
//   String get cardAlgorithms => isVi ? 'Thuật toán' : 'Algorithms';
//   String get cardAlgorithmsSubtitle => 'Deutsch-Jozsa, Grover...';
//   String get cardBasics => isVi ? 'Cơ bản' : 'Basics';
//   String get cardBasicsSubtitle =>
//       isVi ? 'Chồng chập & rối lượng tử' : 'Superposition & entanglement';
//   String get cardLearning => isVi ? 'Chế độ Học' : 'Learning Mode';
//   String get cardLearningSubtitle =>
//       isVi ? 'Bài học & Trắc nghiệm' : 'Lessons & Quizzes';
//   String get cardNetwork => isVi ? 'Mạng Lượng tử' : 'Quantum Network';
//   String get cardNetworkSubtitle =>
//       isVi ? 'Phân tán & dịch chuyển' : 'Distributed & teleportation';
//   String get cardAdvanced => isVi ? 'Nâng cao' : 'Advanced';
//   String get cardAdvancedSubtitle =>
//       isVi ? 'Tối ưu • QFT • Sửa lỗi' : 'Optimization • QFT • QEC';

//   // Tabs
//   String get tabCircuitOptimization =>
//       isVi ? 'Tối ưu Mạch' : 'Circuit Optimization';
//   String get tabEntanglement => isVi ? 'Rối lượng tử' : 'Entanglement';
//   String get tabErrorCorrection => isVi ? 'Sửa lỗi' : 'Error Correction';
//   String get tabShorCode => isVi ? 'Mã Shor' : 'Shor Code';
//   String get tabTeleportation => isVi ? 'Dịch chuyển' : 'Teleportation';
//   String get tabQft => 'QFT';
//   String get tabHybridVqe => 'Hybrid VQE';
//   String get tabRng => isVi ? 'Bộ sinh ngẫu nhiên' : 'Quantum RNG';
//   String get tabQml => 'QML (QSVM/QNN)';
//   String get tabQkd => 'QKD (BB84)';
//   String get tabSynthesis => isVi ? 'Tổng hợp Mạch' : 'Circuit Synthesis';
// }

// class _AppLocDelegate extends LocalizationsDelegate<AppLocalizations> {
//   const _AppLocDelegate();
//   @override
//   bool isSupported(Locale locale) => ['en', 'vi'].contains(locale.languageCode);

//   @override
//   Future<AppLocalizations> load(Locale locale) async {
//     return AppLocalizations(locale);
//   }

//   @override
//   bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
//       false;
// }
