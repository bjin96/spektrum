import '../socket_connection.dart';

class SpektrumUser {

  static const String SOCKET_NAMESPACE = 'user_';

  String userId;
  String userName;
  String profileImageId;

  SpektrumUser(
      {this.userId,
        this.userName,
        this.profileImageId});

  factory SpektrumUser.fromJson(Map<String, dynamic> json) {
    return SpektrumUser(
      userId: json['userId'],
      userName: json['userName'],
      profileImageId: json['profileImageId']
    );
  }

  Future<void> changeUserName(String newUserName) async {
    final Map<String, dynamic> body = { 'userId': userId, 'newUserName': newUserName };
    await SocketConnection.send(SOCKET_NAMESPACE + 'change_user_name', body);
  }

  Future<void> changeProfileImageId(String newProfileImageId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'newProfileImageId': newProfileImageId };
    await SocketConnection.send(SOCKET_NAMESPACE + 'change_profile_image_id', body);
  }

  Future<void> createUser() async {
    final Map<String, dynamic> body = { 'userId': userId, 'userName': userName };
    await SocketConnection.send(SOCKET_NAMESPACE + 'create_user', body);
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId };
    await SocketConnection.send(SOCKET_NAMESPACE + 'send_friend_request', body);
  }

  Future<void> acceptFriendRequest(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId};
    await SocketConnection.send(SOCKET_NAMESPACE + 'accept_friend_request', body);
  }

  Future<void> sendChallenge(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId };
    await SocketConnection.send(SOCKET_NAMESPACE + 'send_challenge', body);
  }

  Future<void> acceptChallenge(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId };
    await SocketConnection.send(SOCKET_NAMESPACE + 'accept_challenge', body);
  }
}