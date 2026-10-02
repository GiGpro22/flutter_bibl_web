typedef Validator = String? Function(String?);

class V {
  static Validator required([String message = 'Поле обязательно для заполнения']) {
    return (value) => (value == null || value.trim().isEmpty) ? message : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.length < min) return 'Не короче $min символов';
      if (text.length > max) return 'Не длиннее $max символов';
      return null;
    };
  }

  static Validator integer({int? min, int? max, String message = 'Введите целое число'}) {
    return (value) {
      final text = value?.trim() ?? '';
      final n = int.tryParse(text);
      if (n == null) return message;
      if (min != null && n < min) return 'Значение не меньше $min';
      if (max != null && n > max) return 'Значение не больше $max';
      return null;
    };
  }

  static Validator email([String message = 'Некорректный адрес почты']) {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (value) => re.hasMatch(value?.trim() ?? '') ? null : message;
  }

  static Validator isbn([String message = 'Некорректный формат ISBN']) {
    final re = RegExp(r'^(?:ISBN(?:-1[03])?:? )?(?=[0-9X]{10}$|(?=(?:[0-9]+[- ]){3})[- 0-9X]{13}$|97[89][0-9]{10}$|(?=(?:[0-9]+[- ]){4})[- 0-9]{17}$)(?:97[89][- ]?)?[0-9]{1,5}[- ]?[0-9]+[- ]?[0-9]+[- ]?[0-9X]$');
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return null;
      return re.hasMatch(text) ? null : message;
    };
  }

  static Validator combine(List<Validator> validators) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}