enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

class Friend {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String status;
  final bool isOnline;

  const Friend({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.status = '',
    this.isOnline = false,
  });

  Friend copyWith({
    String? name,
    String? email,
    String? avatar,
    String? status,
    bool? isOnline,
  }) {
    return Friend(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.status = FriendRequestStatus.pending,
    required this.createdAt,
  });

  FriendRequest copyWith({
    FriendRequestStatus? status,
  }) {
    return FriendRequest(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
