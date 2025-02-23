import 'package:animetrace/utils/sp_util.dart';

class MainScreenStyle {
  static String get showNoteTabInMainScreenKey => 'showNoteTabInMainScreen';
  static String get showSeriesTabInMainScreenKey => 'showSeriesTabInMainScreen';

  static bool showNoteTabInMainScreen() {
    return SPUtil.getBool(showNoteTabInMainScreenKey, defaultValue: true);
  }

  static bool showSeriesTabInMainScreen() {
    return SPUtil.getBool(showSeriesTabInMainScreenKey, defaultValue: false);
  }

  static bool turnShowNoteTabInMainScreen() {
    bool destVal = !showNoteTabInMainScreen();
    SPUtil.setBool(showNoteTabInMainScreenKey, destVal);
    return destVal;
  }

  static bool turnShowSeriesTabInMainScreen() {
    bool destVal = !showSeriesTabInMainScreen();
    SPUtil.setBool(showSeriesTabInMainScreenKey, destVal);
    return destVal;
  }
}
