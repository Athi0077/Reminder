class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;
  final Map<String, dynamic>? sender;
  final String? relatedId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
    this.sender,
    this.relatedId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? json['_id'],
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      sender: json['sender'],
      relatedId: json['relatedId'],
    );
  }
}
