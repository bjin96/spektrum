import '../api_connection.dart';

class SpektrumUser {
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
    await ApiConnection.post('/user/changeUserName', body);
  }

  Future<void> changeProfileImageId(String newProfileImageId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'newProfileImageId': newProfileImageId };
    await ApiConnection.post('/user/changeProfileImageId', body);
  }

  Future<void> createUser() async {
    final Map<String, dynamic> body = { 'userId': userId, 'userName': userName };
    await ApiConnection.post('/user/createUser', body);
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId };
    await ApiConnection.post('/user/sendFriendRequest', body);
  }

  Future<void> acceptFriendRequest(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId};
    await ApiConnection.post('/user/acceptFriendRequest', body);
  }

  Future<void> sendChallenge(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId };
    await ApiConnection.post('/user/sendChallenge', body);
  }

  Future<void> acceptChallenge(String targetUserId) async {
    final Map<String, dynamic> body = { 'userId': userId, 'targetUserId': targetUserId };
    await ApiConnection.post('/user/acceptChallenge', body);
  }
}