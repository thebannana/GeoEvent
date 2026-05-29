class RegisterRequest {
  final String username;
  final String email;
  final DateTime birthDate;
  final String phoneNumber;
  final bool consentGiven;
  final String consentVersion;
  final String password;
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
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'email': email,
      'birthDate': birthDate.toUtc().toIso8601String(),
      'phoneNumber': phoneNumber,
      'consentGiven': consentGiven,
      'consentVersion': consentVersion,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}