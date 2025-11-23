// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Anter';

  @override
  String get sessionListTitle => '세션';

  @override
  String get settingsTitle => '설정';

  @override
  String get connect => '연결';

  @override
  String get host => '호스트';

  @override
  String get port => '포트';

  @override
  String get username => '사용자명';

  @override
  String get password => '비밀번호';
}
