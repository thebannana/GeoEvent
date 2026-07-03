class ResetPasswordRequest {
  final String email;
  final String token;
  final String newPassword;
  final String confirmPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim(),
      'token': token.trim(),
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }
}