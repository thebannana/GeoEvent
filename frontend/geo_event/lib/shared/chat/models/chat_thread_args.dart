import 'chat_thread_type.dart';

class ChatThreadArgs {
  final int threadId;
  final ChatThreadType type;
  final String title;
  final int? otherUserId;
  final int? eventId;

  const ChatThreadArgs({
    required this.threadId,
    required this.type,
    required this.title,
    this.otherUserId,
    this.eventId,
  });
}