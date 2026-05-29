import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lightweight i18n (English + Amharic) without ARB codegen.
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  bool get isAm => locale.languageCode == 'am';

  String get appTitle => isAm ? 'ቫሊዩኢት' : 'ValueIt';
  String get signIn => isAm ? 'ግባ' : 'Sign in';
  String get signOut => isAm ? 'ውጣ' : 'Sign out';
  String get projects => isAm ? 'ፕሮጀክቶች' : 'Projects';
  String get notifications => isAm ? 'ማሳወቂያዎች' : 'Notifications';
  String get searchHint => isAm ? 'ፕሮጀክት ፈልግ…' : 'Search projects…';
  String get saveDraft => isAm ? 'ረቂቅ አስቀምጥ' : 'Save draft';
  String get submitReport => isAm ? 'ሪፖርት አስገባ' : 'Submit report';
  String get approve => isAm ? 'አጽድቅ' : 'Approve';
  String get reject => isAm ? 'አስተውል' : 'Reject';
  String get chat => isAm ? 'ውይይት' : 'Chat';
  String get checklist => isAm ? 'የምርመራ ዝርዝር' : 'Inspection checklist';
  String get offlineDraft => isAm ? 'ከመስመር ውጭ ረቂቅ ተጭኗል' : 'Offline draft saved';
  String get markAllRead => isAm ? 'ሁሉንም አንብብ' : 'Mark all read';
  String get analytics => isAm ? 'ትንታኔ' : 'Analytics';
  String get clients => isAm ? 'ደንበኞች' : 'Clients';
  String get users => isAm ? 'ተጠቃሚዎች' : 'Users';
  String get materials => isAm ? 'ቁሳቁሶች' : 'Materials';
  String get auditLog => isAm ? 'የኦዲት መዝገብ' : 'Audit log';
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'am'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}

final localeProvider = StateProvider<Locale>((_) => const Locale('en'));
