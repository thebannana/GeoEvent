class RegisterRequest {
  final String username;
  final String email;
  final DateTime birthDate;
  final String phoneNumber;
  final bool consentGiven;
  final String consentVersion;
  final String password;
  final String confirmPassword;
  final String firstName;
  final String lastName;

  const RegisterRequest({
    required this.username,
    required this.email,
    required this.birthDate,
    required this.phoneNumber,
    required this.consentGiven,
    required this.consentVersion,
    required this.password,
    required this.confirmPassword,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username.trim(),
      'email': email.trim(),
      'birthDate': birthDate.toUtc().toIso8601String(),
      'phoneNumber': phoneNumber.trim(),
      'consentGiven': consentGiven,
      'consentVersion': consentVersion.trim(),
      'password': password,
      'confirmPassword': confirmPassword,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
    };
  }
}