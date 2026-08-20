class Validators {
  const Validators._();

  static String? required(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? requiredField(
    String? value, {
    String fieldName = 'This field',
  }) {
    return required(
      value,
      fieldName: fieldName,
    );
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address in the format name@example.com.';
    }

    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required.';
    }

    final trimmed = value.trim();

    if (trimmed.length < 3) {
      return 'Username must be at least 3 characters.';
    }

    if (trimmed.length > 24) {
      return 'Username must be at most 24 characters.';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9._]+$');

    if (!usernameRegex.hasMatch(trimmed)) {
      return 'Username may contain only letters, numbers, dots, and underscores.';
    }

    return null;
  }

  static String? password(
    String? value, {
    bool required = true,
  }) {
    if (value == null || value.isEmpty) {
      return required ? 'Password is required.' : null;
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters.';
    }

    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecial = RegExp(
      r'''[!@#\$%\^&\*\(\)_\+\-\=\[\]\{\};:'",\.<>\?\/\\|`~]''',
    ).hasMatch(value);

    if (!hasUppercase) {
      return 'Password must contain at least one uppercase letter.';
    }

    if (!hasLowercase) {
      return 'Password must contain at least one lowercase letter.';
    }

    if (!hasDigit) {
      return 'Password must contain at least one number.';
    }

    if (!hasSpecial) {
      return 'Password must contain at least one special character.';
    }

    return null;
  }

  static String? confirmPassword(
    String? value,
    String originalPassword, {
    bool required = true,
  }) {
    if ((value == null || value.isEmpty) && !required) {
      return null;
    }

    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }

    if (value != originalPassword) {
      return 'Passwords do not match.';
    }

    return null;
  }

  static String? firstName(String? value) {
    return _personName(
      value,
      fieldName: 'First name',
    );
  }

  static String? lastName(String? value) {
    return _personName(
      value,
      fieldName: 'Last name',
    );
  }

  static String? fullName(String? value) {
    return _personName(
      value,
      fieldName: 'Name',
    );
  }

  static String? _personName(
    String? value, {
    required String fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    final trimmed = value.trim();

    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters.';
    }

    if (trimmed.length > 100) {
      return '$fieldName must be at most 100 characters.';
    }

    final nameRegex = RegExp(r"^[A-Za-zÀ-ž\s'-]+$");

    if (!nameRegex.hasMatch(trimmed)) {
      return '$fieldName contains invalid characters.';
    }

    return null;
  }

  static String? phoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }

    final normalized = value.replaceAll(
      RegExp(r'[\s()-]'),
      '',
    );

    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');

    if (!phoneRegex.hasMatch(normalized)) {
      return 'Enter a valid phone number with 8 to 15 digits.';
    }

    return null;
  }

  static String? birthDate(
    DateTime? value, {
    int minimumAge = 13,
  }) {
    if (value == null) {
      return 'Birth date is required.';
    }

    final now = DateTime.now().toUtc();
    final cutoff = DateTime(
      now.year - minimumAge,
      now.month,
      now.day,
    );

    if (value.isAfter(cutoff)) {
      return 'You must be at least $minimumAge years old.';
    }

    return null;
  }

  static String? minLength(
    String? value, {
    required int length,
    String fieldName = 'This field',
  }) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return '$fieldName is required.';
    }

    if (trimmed.length < length) {
      return '$fieldName must be at least $length characters.';
    }

    return null;
  }

  static String? maxLength(
    String? value, {
    required int length,
    String fieldName = 'This field',
  }) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.length > length) {
      return '$fieldName must be at most $length characters.';
    }

    return null;
  }

  static String? positiveNumber(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    final parsed = double.tryParse(
      value.replaceAll(',', '.').trim(),
    );

    if (parsed == null) {
      return '$fieldName must be a valid number.';
    }

    if (parsed < 0) {
      return '$fieldName must be zero or greater.';
    }

    return null;
  }

  static String? url(
    String? value, {
    bool required = false,
  }) {
    final trimmed = value?.trim() ?? '';

    if (trimmed.isEmpty) {
      return required ? 'URL is required.' : null;
    }

    final uri = Uri.tryParse(trimmed);

    final isValid = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;

    if (!isValid) {
      return 'Enter a valid URL starting with http:// or https://.';
    }

    return null;
  }

  static String? selectionRequired<T>(
    T? value, {
    String fieldName = 'Selection',
  }) {
    if (value == null) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? dateRequired(
    DateTime? value, {
    String fieldName = 'Date',
  }) {
    if (value == null) {
      return '$fieldName is required.';
    }

    return null;
  }

  static String? nonNegativeInt(
    String? value, {
    String fieldName = 'Value',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required.';
    }

    final parsed = int.tryParse(value.trim());

    if (parsed == null) {
      return '$fieldName must be a whole number.';
    }

    if (parsed < 0) {
      return '$fieldName must be zero or greater.';
    }

    return null;
  }
}