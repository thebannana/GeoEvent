enum ChatThreadType {
  direct,
  eventGroup,
}

extension ChatThreadTypeX on ChatThreadType {
  static ChatThreadType fromJson(String? value) {
    switch (value) {
      case 'eventGroup':
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