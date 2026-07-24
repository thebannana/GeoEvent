class LoginRequest {
  final String emailOrUsername;
  final String password;
  final String? deviceInfo;

  const LoginRequest({
    required this.emailOrUsername,
    required this.password,
    this.deviceInfo,
  });

  Map<String, dynamic> toJson() {
    return {
      'emailOrUsername': emailOrUsername.trim(),
      'password': password,
      if (deviceInfo != null && deviceInfo!.trim().isNotEmpty)
        'deviceInfo': deviceInfo!.trim(),
    };
  }
}