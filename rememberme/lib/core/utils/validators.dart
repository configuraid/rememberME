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
    return null;
  }

  // Name Validator
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name ist erforderlich';
    }
    if (value.trim().length < 2) {
      return 'Name muss mindestens 2 Zeichen lang sein';
    }
    if (value.trim().length > 100) {
      return 'Name darf maximal 100 Zeichen lang sein';
    }
    // Optional: Prüfen ob Name nur erlaubte Zeichen enthält
    final nameRegex = RegExp(r'^[a-zA-ZäöüÄÖÜß\s\-\.]+$');
    if (!nameRegex.hasMatch(value.trim())) {
      return 'Name enthält ungültige Zeichen';
    }
    return null;
  }

  // PIN Validator (4-stellig)
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN ist erforderlich';
    }
    if (value.length != 4) {
      return 'PIN muss genau 4 Ziffern haben';
    }
    // Prüfen ob nur Ziffern enthalten sind
    final pinRegex = RegExp(r'^\d{4}$');
    if (!pinRegex.hasMatch(value)) {
      return 'PIN darf nur Ziffern enthalten';
    }
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

  // Email Validator (Optional)
  static String? validateEmailOptional(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
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

  // Password Validator (optional für zukünftige Verwendung)
  static String? validatePassword(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) {
      return 'Passwort ist erforderlich';
    }
    if (value.length < minLength) {
      return 'Passwort muss mindestens $minLength Zeichen lang sein';
    }
    return null;
  }

  // Confirm Password Validator
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Passwort-Bestätigung ist erforderlich';
    }
    if (value != password) {
      return 'Passwörter stimmen nicht überein';
    }
    return null;
  }
}
