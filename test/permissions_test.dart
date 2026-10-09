import 'package:flutter_test/flutter_test.dart';
import 'package:library_catalog/core/permissions.dart';
import 'package:library_catalog/models/app_user.dart';

void main() {
  const admin = AppUser(id: 1, email: 'admin@bibl.ru', name: 'Админ', role: Role.admin);
  const librarian = AppUser(id: 2, email: 'lib@bibl.ru', name: 'Библиотекарь', role: Role.librarian);
  const reader = AppUser(id: 3, email: 'reader@bibl.ru', name: 'Читатель', role: Role.reader);

  test('1. Гость (null) не имеет прав на операции изменения', () {
    expect(canManageBooks(null), isFalse);
    expect(canHardDelete(null), isFalse);
    expect(canManageUsers(null), isFalse);
  });

  test('2. Читатель может смотреть свои выдачи, но не может управлять книгами', () {
    expect(canViewMyLoans(reader), isTrue);
    expect(canManageBooks(reader), isFalse);
    expect(canHardDelete(reader), isFalse);
  });

  test('3. Библиотекарь может управлять книгами, но не может удалять физически', () {
    expect(canManageBooks(librarian), isTrue);
    expect(canHardDelete(librarian), isFalse);
    expect(canManageUsers(librarian), isFalse);
  });

  test('4. Администратор имеет полные права, включая пользователей и физическое удаление', () {
    expect(canManageBooks(admin), isTrue);
    expect(canHardDelete(admin), isTrue);
    expect(canRestore(admin), isTrue);
    expect(canManageUsers(admin), isTrue);
  });

  test('5. Безопасная деградация роли: неизвестная роль трактуется как reader', () {
    final unknownRole = Role.fromCode('super_hacker');
    expect(unknownRole, Role.reader);
  });
}