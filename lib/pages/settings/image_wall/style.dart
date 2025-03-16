import 'package:animetrace/utils/sp_util.dart';

class NoteImageWallStyle {
  static String get _groupCntKey => 'groupCntInNoteImageWallPage';

  static void setGroupCnt(int cnt) {
    SPUtil.setInt(_groupCntKey, cnt);
  }

  static int getGroupCnt() {
    return SPUtil.getInt(_groupCntKey, defaultValue: 3);
  }
}
