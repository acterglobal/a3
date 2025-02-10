import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ActerNotififyL10n
/// returned by `ActerNotififyL10n.of(context)`.
///
/// Applications need to include `ActerNotififyL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ActerNotififyL10n.localizationsDelegates,
///   supportedLocales: ActerNotififyL10n.supportedLocales,
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
/// be consistent with the languages listed in the ActerNotififyL10n.supportedLocales
/// property.
abstract class ActerNotififyL10n {
  ActerNotififyL10n(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ActerNotififyL10n of(BuildContext context) {
    return Localizations.of<ActerNotififyL10n>(context, ActerNotififyL10n)!;
  }

  static const LocalizationsDelegate<ActerNotififyL10n> delegate = _ActerNotififyL10nDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en')
  ];

  /// No description provided for @objectTitleChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'{parentInfo} renamed'**
  String objectTitleChangeTitle(Object parentInfo);

  /// No description provided for @objectTitleChangeTitleNoParent.
  ///
  /// In en, this message translates to:
  /// **'{username} renamed title to \"{newTitle}\"'**
  String objectTitleChangeTitleNoParent(Object username, Object newTitle);

  /// No description provided for @objectTitleChangeBody.
  ///
  /// In en, this message translates to:
  /// **'by {username} to \"{newTitle}\"'**
  String objectTitleChangeBody(Object username, Object newTitle);
}

class _ActerNotififyL10nDelegate extends LocalizationsDelegate<ActerNotififyL10n> {
  const _ActerNotififyL10nDelegate();

  @override
  Future<ActerNotififyL10n> load(Locale locale) {
    return SynchronousFuture<ActerNotififyL10n>(lookupActerNotififyL10n(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_ActerNotififyL10nDelegate old) => false;
}

ActerNotififyL10n lookupActerNotififyL10n(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return ActerNotififyL10nEn();
  }

  throw FlutterError(
    'ActerNotififyL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
