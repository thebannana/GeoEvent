enum ChatThreadType {
  direct,
  eventGroup,
}

extension ChatThreadTypeX on ChatThreadType {
  static ChatThreadType fromJson(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'eventgroup':
      case 'event_group':
      case 'group':
        return ChatThreadType.eventGroup;
      case 'direct':
      default:
        return ChatThreadType.direct;
    }
  }

  String toJson() {
    switch (this) {
      case ChatThreadType.direct:
        return 'direct';
      case ChatThreadType.eventGroup:
        return 'eventGroup';
    }
  }
}