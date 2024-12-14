import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Special DateTime', () {
    expect(DateTime(0) == DateTime(0), true);
  });

  test('parse', () {
    expect(DateTime.tryParse('2011-01-02') != null, true);
    expect(DateTime.tryParse('2011-1-02') != null, false);
    expect(DateTime.tryParse('2011-01-2') != null, false);
    expect(DateTime.tryParse('2011-1-2') != null, false);
  });
}
