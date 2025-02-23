import 'package:flutter_test/flutter_test.dart';
import 'package:animetrace/utils/regexp.dart';

void main() {
  test('extract date', () {
    expect(RegexpUtil.extractDate('2024-04-05(日本)'), '2024-04-05');
    expect(RegexpUtil.extractDate('2024-04'), '2024-04');
    expect(RegexpUtil.extractDate('2024-4'), '2024-4');
    expect(RegexpUtil.extractDate('2024'), '2024');
  });
}
