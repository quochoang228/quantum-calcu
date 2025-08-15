import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Quantum Calculator'**
  String get appTitle;

  /// No description provided for @homeTagline.
  ///
  /// In en, this message translates to:
  /// **'Explore quantum computing via visual simulation, canonical algorithms, and distributed quantum networking.'**
  String get homeTagline;

  /// No description provided for @cardCircuitSimulator.
  ///
  /// In en, this message translates to:
  /// **'Circuit Simulator'**
  String get cardCircuitSimulator;

  /// No description provided for @cardCircuitSimulatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build, run & measure'**
  String get cardCircuitSimulatorSubtitle;

  /// No description provided for @cardAlgorithms.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get cardAlgorithms;

  /// No description provided for @cardAlgorithmsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Deutsch-Jozsa, Grover...'**
  String get cardAlgorithmsSubtitle;

  /// No description provided for @cardBasics.
  ///
  /// In en, this message translates to:
  /// **'Basics'**
  String get cardBasics;

  /// No description provided for @cardBasicsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Superposition & entanglement'**
  String get cardBasicsSubtitle;

  /// No description provided for @cardLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning Mode'**
  String get cardLearning;

  /// No description provided for @cardLearningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lessons & Quizzes'**
  String get cardLearningSubtitle;

  /// No description provided for @cardNetwork.
  ///
  /// In en, this message translates to:
  /// **'Quantum Network'**
  String get cardNetwork;

  /// No description provided for @cardNetworkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Distributed & teleportation'**
  String get cardNetworkSubtitle;

  /// No description provided for @cardAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get cardAdvanced;

  /// No description provided for @cardAdvancedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optimization • QFT • QEC'**
  String get cardAdvancedSubtitle;

  /// No description provided for @tabCircuitOptimization.
  ///
  /// In en, this message translates to:
  /// **'Circuit Optimization'**
  String get tabCircuitOptimization;

  /// No description provided for @tabEntanglement.
  ///
  /// In en, this message translates to:
  /// **'Entanglement'**
  String get tabEntanglement;

  /// No description provided for @tabErrorCorrection.
  ///
  /// In en, this message translates to:
  /// **'Error Correction'**
  String get tabErrorCorrection;

  /// No description provided for @tabShorCode.
  ///
  /// In en, this message translates to:
  /// **'Shor Code'**
  String get tabShorCode;

  /// No description provided for @tabTeleportation.
  ///
  /// In en, this message translates to:
  /// **'Teleportation'**
  String get tabTeleportation;

  /// No description provided for @tabQft.
  ///
  /// In en, this message translates to:
  /// **'QFT'**
  String get tabQft;

  /// No description provided for @tabHybridVqe.
  ///
  /// In en, this message translates to:
  /// **'Hybrid VQE'**
  String get tabHybridVqe;

  /// No description provided for @tabRng.
  ///
  /// In en, this message translates to:
  /// **'Quantum RNG'**
  String get tabRng;

  /// No description provided for @tabQml.
  ///
  /// In en, this message translates to:
  /// **'QML (QSVM/QNN)'**
  String get tabQml;

  /// No description provided for @tabQkd.
  ///
  /// In en, this message translates to:
  /// **'QKD (BB84)'**
  String get tabQkd;

  /// No description provided for @tabSynthesis.
  ///
  /// In en, this message translates to:
  /// **'Circuit Synthesis'**
  String get tabSynthesis;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
