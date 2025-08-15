// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Máy tính Lượng tử';

  @override
  String get homeTagline =>
      'Khám phá điện toán lượng tử qua mô phỏng trực quan, các thuật toán kinh điển và mạng lượng tử phân tán.';

  @override
  String get cardCircuitSimulator => 'Mô phỏng Mạch';

  @override
  String get cardCircuitSimulatorSubtitle => 'Tạo, chạy & đo';

  @override
  String get cardAlgorithms => 'Thuật toán';

  @override
  String get cardAlgorithmsSubtitle => 'Deutsch-Jozsa, Grover...';

  @override
  String get cardBasics => 'Cơ bản';

  @override
  String get cardBasicsSubtitle => 'Chồng chập & rối lượng tử';

  @override
  String get cardLearning => 'Chế độ Học';

  @override
  String get cardLearningSubtitle => 'Bài học & Trắc nghiệm';

  @override
  String get cardNetwork => 'Mạng Lượng tử';

  @override
  String get cardNetworkSubtitle => 'Phân tán & dịch chuyển';

  @override
  String get cardAdvanced => 'Nâng cao';

  @override
  String get cardAdvancedSubtitle => 'Tối ưu • QFT • Sửa lỗi';

  @override
  String get tabCircuitOptimization => 'Tối ưu Mạch';

  @override
  String get tabEntanglement => 'Rối lượng tử';

  @override
  String get tabErrorCorrection => 'Sửa lỗi';

  @override
  String get tabShorCode => 'Mã Shor';

  @override
  String get tabTeleportation => 'Dịch chuyển';

  @override
  String get tabQft => 'QFT';

  @override
  String get tabHybridVqe => 'Hybrid VQE';

  @override
  String get tabRng => 'Bộ sinh ngẫu nhiên';

  @override
  String get tabQml => 'QML (QSVM/QNN)';

  @override
  String get tabQkd => 'QKD (BB84)';

  @override
  String get tabSynthesis => 'Tổng hợp Mạch';
}
