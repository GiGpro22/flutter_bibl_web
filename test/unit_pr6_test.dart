import 'package:flutter_test/flutter_test.dart';
import 'package:library_catalog/models/app_user.dart';
import 'package:library_catalog/models/book.dart';
import 'package:library_catalog/core/permissions.dart';

void main() {
  group('1. Валидаторы полей ввода', () {
    String? validateRequired(String? val) {
      if (val == null || val.trim().isEmpty) {
        return 'Поле обязательно для заполнения';
      }
      return null;
    }

    String? validateYear(String? val) {
      if (val == null || val.trim().isEmpty) return 'Укажите год издания';
      final year = int.tryParse(val.trim());
      if (year == null || year < 1000 || year > 2100) {
        return 'Некорректный год издания';
      }
      return null;
    }

    String? validateNonNegative(String? val) {
      if (val == null || val.trim().isEmpty) return 'Укажите значение';
      final num = int.tryParse(val.trim());
      if (num == null || num < 0) return 'Число не может быть отрицательным';
      return null;
    }

    test('Обязательное поле: пустая строка и пробелы отклоняются', () {
      expect(validateRequired(''), isNotNull);
      expect(validateRequired('   '), isNotNull);
      expect(validateRequired(null), isNotNull);
    });

    test('Обязательное поле: заполненная строка принимается', () {
      expect(validateRequired('Война и мир'), isNull);
    });

    test('Год издания: корректный год принимается', () {
      expect(validateYear('1869'), isNull);
      expect(validateYear('2024'), isNull);
    });

    test('Год издания: отрицательные и некорректные значения отклоняются', () {
      expect(validateYear('-500'), isNotNull);
      expect(validateYear('abc'), isNotNull);
      expect(validateYear('9999'), isNotNull);
    });

    test('Количество экземпляров: неотрицательное число принимается', () {
      expect(validateNonNegative('0'), isNull);
      expect(validateNonNegative('5'), isNull);
      expect(validateNonNegative('-1'), isNotNull);
    });
  });

  group('2. Разбор и сериализация моделей данных (JSON)', () {
    test('Book.fromJson корректно парсит валидный JSON', () {
      final json = {
        'id': 1,
        'title': 'Евгений Онегин',
        'isbn': '978-5-17-090812-4',
        'year': 1833,
        'publisherId': 2,
        'isDeleted': false,
        'copiesAvailable': 3,
        'copiesTotal': 5,
      };
      final book = Book.fromJson(json);

      expect(book.id, 1);
      expect(book.title, 'Евгений Онегин');
      expect(book.isbn, '978-5-17-090812-4');
      expect(book.year, 1833);
      expect(book.isDeleted, false);
      expect(book.copiesAvailable, 3);
      expect(book.copiesTotal, 5);
    });

    test(
        'Book.fromJson корректно использует значения по умолчанию при отсутствии полей',
        () {
      final json = {'id': 2, 'title': 'Книга без деталей', 'isbn': ''};
      final book = Book.fromJson(json);

      expect(book.id, 2);
      expect(book.title, 'Книга без деталей');
      expect(book.year, 0);
      expect(book.isDeleted, false);
      expect(book.copiesAvailable, 0);
    });

    test('AppUser.fromJson корректно определяет роли читателя и библиотекаря',
        () {
      final readerJson = {
        'id': 1,
        'email': 'r@bibl.ru',
        'name': 'Читатель',
        'role': 'reader'
      };
      final librarianJson = {
        'id': 2,
        'email': 'l@bibl.ru',
        'name': 'Библиотекарь',
        'role': 'librarian'
      };

      final reader = AppUser.fromJson(readerJson);
      final librarian = AppUser.fromJson(librarianJson);

      expect(reader.role, Role.reader);
      expect(librarian.role, Role.librarian);
    });
  });

  group('3. Логика матрицы разграничения прав (RBAC)', () {
    const reader =
        AppUser(id: 1, email: 'r@bibl.ru', name: 'Читатель', role: Role.reader);
    const librarian = AppUser(
        id: 2, email: 'l@bibl.ru', name: 'Библиотекарь', role: Role.librarian);
    const admin = AppUser(
        id: 3, email: 'a@bibl.ru', name: 'Администратор', role: Role.admin);

    test(
        'Читатель не имеет прав на изменение фонда и управление пользователями',
        () {
      expect(canManageBooks(reader), isFalse);
      expect(canManageUsers(reader), isFalse);
      expect(canRestore(reader), isFalse);
      expect(canHardDelete(reader), isFalse);
    });

    test(
        'Библиотекарь может управлять книгами и выдачами, но не пользователями',
        () {
      expect(canManageBooks(librarian), isTrue);
      expect(canManageLoans(librarian), isTrue);
      expect(canManageUsers(librarian), isFalse);
      expect(canHardDelete(librarian), isFalse);
    });

    test(
        'Только Администратор обладает правами на жесткое удаление и восстановление',
        () {
      expect(canRestore(admin), isTrue);
      expect(canHardDelete(admin), isTrue);
      expect(canManageUsers(admin), isTrue);
    });
  });
}
