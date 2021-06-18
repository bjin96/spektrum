import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:postgres/postgres.dart';

import 'authentication.dart';
import 'database.dart';
import 'excerpt.dart';
import 'game_room.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({Key key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  _ContactPageState();
  Future<SpektrumUser> spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);

  TextEditingController _friendMail = TextEditingController();

  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
        });
      }
    });
  }

  void onSendFriendRequest(SpektrumUser user) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Freund*in hinzufügen.'),
            content: Container(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    obscureText: false,
                    decoration: InputDecoration(hintText: 'E-Mail Adresse'),
                    validator: (String value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte gib deine E-Mail Adresse ein.';
                      }
                      if (!value.contains('@')) {
                        return 'Bitte gib eine korrekte E-Mail Adresse ein.';
                      }
                      return null;
                    },
                    controller: _friendMail,
                    textInputAction: TextInputAction.next,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        child: ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: Text('Abbrechen')),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: ElevatedButton(
                            onPressed: () {
                              user.sendFriendRequest(_friendMail.text);
                              Navigator.of(context).pop();
                            },
                            child: Text('Bestätigen')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  void onFriendRequestAccepted(SpektrumUser user, String targetUserId) {
    setState(() {
      spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
    });
    user.acceptFriendRequest(targetUserId);
  }

  void onChallengeFriend(SpektrumUser user, String opponent) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GameRoomPage(
                opponent: opponent,
              )),
    );
    setState(() {
      spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
    });
  }

  ElevatedButton getFriendActionButton(SpektrumUser user, String targetUserId) {
    if (user.challengeList.contains(targetUserId)) {
      return ElevatedButton(
        child: Text('Herausforderung annehmen'),
        onPressed: () async {
          user.acceptChallenge(targetUserId);
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GameRoomPage(
                      opponent: targetUserId,
                    )),
          );
          setState(() {
            spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
          });
        },
      );
    } else if (user.challengeSentList.contains(targetUserId)) {
      return ElevatedButton(
        child: Text('Herausgefordert'),
        onPressed: null,
      );
    } else if (user.openGameList.contains(targetUserId)) {
      return ElevatedButton(
        child: Text('Spiel öffnen'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GameRoomPage(
                      opponent: targetUserId,
                    )),
          );
          setState(() {
            spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
          });
        },
      );
    } else {
      return ElevatedButton(
        child: Text('herausfordern'),
        onPressed: () {
          user.sendChallenge(targetUserId);
          setState(() {
            spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: spektrumUser,
          builder: (BuildContext context, AsyncSnapshot<SpektrumUser> snapshot) {
            if (snapshot.hasData) {
              SpektrumUser user = snapshot.data;
              return Container(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            child: Text(
                              user.userId,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            alignment: Alignment.topRight,
                            padding: EdgeInsets.only(
                              top: 50,
                              bottom: 50,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.logout),
                            onPressed: () async {
                              await FirebaseAuth.instance.signOut();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => AuthenticationPage()),
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Freund*innen',
                            textScaleFactor: 1.2,
                            style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: () => onSendFriendRequest(user),
                            icon: Icon(Icons.person_add),
                          ),
                        ],
                      ),
                      Flexible(
                        child: ListView.builder(
                            itemCount: user.contactList.length,
                            itemBuilder: (BuildContext context, int index) {
                              String targetUserId = user.contactList[index];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(targetUserId),
                                  getFriendActionButton(user, targetUserId),
                                ],
                              );
                            }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Freundschaftseinladungen',
                            textScaleFactor: 1.2,
                            style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Flexible(
                        child: ListView.builder(
                            itemCount: user.friendRequestList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(user.friendRequestList[index]),
                                  ElevatedButton(
                                      onPressed: () => onFriendRequestAccepted(user, user.friendRequestList[index]),
                                      child: Text('annehmen')),
                                ],
                              );
                            }),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Ausstehende Freundschaftseinladungen',
                            textScaleFactor: 1.2,
                            style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Flexible(
                        child: ListView.builder(
                            itemCount: user.pendingFriendRequestList.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(user.pendingFriendRequestList[index]),
                                ],
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return SizedBox(
                child: CircularProgressIndicator(),
                width: 60,
                height: 60,
              );
            }
          },
        ),
      ),
    );
  }
}

class SpektrumUser {
  String userId;
  String userName;
  List<String> contactList;
  List<String> friendRequestList;
  List<String> pendingFriendRequestList;
  List<String> openGameList;
  List<String> challengeList;
  List<String> challengeSentList;

  SpektrumUser(
      {this.userId,
      this.userName,
      this.contactList,
      this.friendRequestList,
      this.pendingFriendRequestList,
      this.challengeList,
      this.challengeSentList,
      this.openGameList});

  static Future<SpektrumUser> getUserById(String userId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> userMap = await connection.mappedResultsQuery('''
      SELECT name
      FROM spektrum_user
      WHERE id = @userId
      ''', substitutionValues: {'userId': userId});
    final List<Map<String, dynamic>> friendMap = await connection.mappedResultsQuery('''
      SELECT user_friend
      FROM friend
      WHERE logged_in_user = @userId
      ''', substitutionValues: {'userId': userId});
    final List<Map<String, dynamic>> friendRequestMap = await connection.mappedResultsQuery('''
      SELECT sender
      FROM friend_request
      WHERE receiver = @userId
      ''', substitutionValues: {'userId': userId});
    final List<Map<String, dynamic>> pendingFriendRequestMap = await connection.mappedResultsQuery('''
      SELECT receiver
      FROM friend_request
      WHERE sender = @userId
      ''', substitutionValues: {'userId': userId});
    final List<Map<String, dynamic>> challengeSentMap = await connection.mappedResultsQuery('''
      SELECT receiver
      FROM game_request
      WHERE sender = @userId
      ''', substitutionValues: {'userId': userId});
    final List<Map<String, dynamic>> challengeMap = await connection.mappedResultsQuery('''
      SELECT sender
      FROM game_request
      WHERE receiver = @userId
      ''', substitutionValues: {'userId': userId});
    final List<Map<String, dynamic>> openGameMap = await connection.mappedResultsQuery('''
      SELECT other_player
      FROM game
      WHERE logged_in_player = @userId
      ''', substitutionValues: {'userId': userId});
    connection.close();
    return SpektrumUser(
      userId: userId,
      userName: userMap[0]['spektrum_user']['name'],
      contactList: List<String>.from(friendMap.map((row) => row['friend']['user_friend']).toList()),
      friendRequestList: List<String>.from(friendRequestMap.map((row) => row['friend_request']['sender']).toList()),
      pendingFriendRequestList:
          List<String>.from(pendingFriendRequestMap.map((row) => row['friend_request']['receiver']).toList()),
      challengeList: List<String>.from(challengeMap.map((row) => row['game_request']['sender']).toList()),
      challengeSentList: List<String>.from(challengeSentMap.map((row) => row['game_request']['receiver']).toList()),
      openGameList: List<String>.from(openGameMap.map((row) => row['game']['other_player']).toList()),
    );
  }

  Future<void> createUser() async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO spektrum_user (id, name)
      VALUES (@userId, @userName)
    ''', substitutionValues: {
      'userId': userId,
      'userName': userName,
    });
    connection.close();
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO friend_request (sender, receiver)
      VALUES (@userId, @targetUserId)
    ''', substitutionValues: {
      'userId': userId,
      'targetUserId': targetUserId,
    });
    connection.close();
  }

  Future<void> acceptFriendRequest(String targetUserId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.transaction((ctx) async {
      await ctx.query('''
      DELETE FROM friend_request
      WHERE receiver = @userId
      AND sender = @targetUserId
    ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
      await ctx.query('''
        INSERT INTO friend (logged_in_user, user_friend)
        VALUES (@userId, @targetUserId)
      ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
      await ctx.query('''
        INSERT INTO friend (logged_in_user, user_friend)
        VALUES (@targetUserId, @userId)
      ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
    });
    connection.close();
  }

  Future<void> sendChallenge(String targetUserId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
      INSERT INTO game_request (sender, receiver)
      VALUES (@userId, @targetUserId)
    ''', substitutionValues: {
      'userId': userId,
      'targetUserId': targetUserId,
    });
    connection.close();
  }

  Future<void> acceptChallenge(String targetUserId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.transaction((ctx) async {
      await ctx.query('''
      DELETE FROM game_request
      WHERE receiver = @userId
      AND sender = @targetUserId
    ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
      await ctx.query('''
        INSERT INTO game (logged_in_player, other_player)
        VALUES (@userId, @targetUserId)
      ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
      await ctx.query('''
        INSERT INTO game (game_created, logged_in_player, other_player)
        VALUES (
        (
          SELECT game_created
          FROM game
          WHERE logged_in_player = @userId
          AND other_player = @targetUserId
          AND finished = false
        ), @targetUserId, @userId)
      ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
      final List<Map<String, dynamic>> gameMap = await ctx.mappedResultsQuery('''
      SELECT id
      FROM game
      WHERE (
        (
          logged_in_player = @loggedInPlayer
          AND other_player = @otherPlayer
        ) OR (
          logged_in_player = @otherPlayer
          AND other_player = @loggedInPlayer
        )
      )
      AND finished = false
      ''', substitutionValues: {'loggedInPlayer': userId, 'otherPlayer': targetUserId});
      List<Map<String, dynamic>> excerptIdList = await Excerpt.getRandomExcerptIdList();
      for (int i = 0; i < excerptIdList.length; i++) {
        for (Map<String, dynamic> row in gameMap) {
          await ctx.query('''
            INSERT INTO game_excerpt (game_id, counter, speech_id, fragment)
            VALUES (@gameId, @counter, @speechId, @fragment)
            ''', substitutionValues: {
            'gameId': row['game']['id'],
            'counter': i,
            'speechId': excerptIdList[i]['speechId'],
            'fragment': excerptIdList[i]['fragment'],
          });
        }
      }
    });
    connection.close();
  }
}
