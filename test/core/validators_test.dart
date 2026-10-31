import 'package:flutter_test/flutter_test.dart';
import 'package:petcare/core/utils/validators.dart';

void main() {
  test('email', () {
    expect(validateEmail('a@x.vn'), isNull);
    expect(validateEmail(' a@x.vn '), isNull);
    expect(validateEmail('a@x'), isNotNull);
    expect(validateEmail(''), isNotNull);
    expect(validateEmail(null), isNotNull);
  });

  test('mật khẩu tối thiểu 6 ký tự', () {
    expect(validatePassword('123456'), isNull);
    expect(validatePassword('12345'), isNotNull);
    expect(validatePassword(null), isNotNull);
  });

  test('bắt buộc nhập', () {
    expect(validateRequired('An', 'họ tên'), isNull);
    expect(validateRequired('   ', 'họ tên'), 'Vui lòng nhập họ tên.');
  });
}
