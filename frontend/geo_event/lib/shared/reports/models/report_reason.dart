enum ReportReason {
  spam('Spam'),
  harassment('Harassment'),
  inappropriateContent('Inappropriate content'),
  misinformation('Misinformation'),
  fraud('Fraud or scam'),
  violence('Violence or dangerous behavior'),
  hateSpeech('Hate speech'),
  other('Other');

  final String label;

  const ReportReason(this.label);
}