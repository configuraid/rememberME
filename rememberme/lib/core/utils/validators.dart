import '../constants/app_strings.dart';

class Validators {
  // Auth-Key Validator
  static String? validateAuthKey(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value.length < 10) {
      return AppStrings.authKeyTooShort;
    }
    // Weitere Validierung kann hier hinzugefügt werden
    return null;
  }

  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Ungültige E-Mail-Adresse';
    }
    return null;
  }

  // Required Field Validator
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return fieldName != null
          ? '$fieldName ist erforderlich'
          : AppStrings.requiredField;
    }
    return null;
  }

  // Min Length Validator
  static String? validateMinLength(String? value, int minLength,
      {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (value.length < minLength) {
      return '${fieldName ?? 'Feld'} muss mindestens $minLength Zeichen lang sein';
    }
    return null;
  }

  // Max Length Validator
  static String? validateMaxLength(String? value, int maxLength,
      {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Feld'} darf maximal $maxLength Zeichen lang sein';
    }
    return null;
  }

  // URL Validator
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlRegex.hasMatch(value)) {
      return 'Ungültige URL';
    }
    return null;
  }

  // Datum Validator
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Ungültiges Datum';
    }
  }

  // Number Validator
  static String? validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.requiredField;
    }
    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return 'Bitte geben Sie eine gültige Zahl ein';
    }
    return null;
  }
}
