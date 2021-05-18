class ChabokMessage {
  dynamic data;
  String userId = "";
  String content = "";
  String channel = "";
  dynamic notification;

  ChabokMessage(String userId, String channel, String content, [dynamic data]) {
    this.data = data;
    this.userId = userId;
    this.content = content;
    this.channel = channel;
  }
}
