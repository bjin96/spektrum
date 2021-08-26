import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:postgres/postgres.dart';
import 'package:spektrum/speaker.dart';

import 'authentication.dart';
import 'database.dart';
import 'excerpt.dart';
import 'game_room.dart';

enum MenuOption {
  userName,
  profileImage,
  logOut,
}

extension MenuOptionExtension on MenuOption {
  Function get action {
    switch (this) {
      case MenuOption.userName:
        return (BuildContext context, _ContactPageState contactPage, SpektrumUser user) {
          contactPage.onShowChangeUserNameDialog(user);
        };
      case MenuOption.profileImage:
        return (BuildContext context, _ContactPageState contactPage, SpektrumUser user) {
          contactPage.onShowChangeProfileImageDialog(user);
        };
      case MenuOption.logOut:
        return (BuildContext context, _ContactPageState contactPage, SpektrumUser user) async {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AuthenticationPage()),
          );
        };
      default:
        return null;
    }
  }
}

class ContactPage extends StatefulWidget {
  const ContactPage({Key key}) : super(key: key);

  @override
  _ContactPageState createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  _ContactPageState();

  Future<SpektrumUser> spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);

  TextEditingController _newUserName = TextEditingController();
  InputDecoration inputDecorationNewFriend;
  InputDecoration inputDecorationChangeUserName;

  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          spektrumUser = SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
        });
      }
    });
  }

  void onShowChangeProfileImageDialog(SpektrumUser user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        StateSetter setStateParent = setState;
        return FutureBuilder(
          future: Speaker.fetchAllSpeakerIds(),
          builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
            if (snapshot.hasData) {
              List<String> speakerIdList = snapshot.data;
              return AlertDialog(
                  title: Text('profilbild wählen'),
                  content: Container(
                    width: 200,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      children: List.generate(speakerIdList.length, (index) => IconButton(
                          iconSize: MediaQuery.of(context).size.width / 3,
                          onPressed: () async {
                              await user.changeProfileImageId(speakerIdList[index]);
                              Navigator.of(context).pop();
                              setStateParent(() => user.profileImageId = speakerIdList[index]);
                          },
                          icon: ClipRRect(
                            borderRadius: BorderRadius.circular(200.0),
                            child: Image.asset('assets/portrait_id/${speakerIdList[index]}.jpg'),
                          ),
                      )),
                    )
                  ),
              );
            } else {
              return SizedBox();
            }
          },
        );
      }
    );
  }

  void onShowChangeUserNameDialog(SpektrumUser user) {
    inputDecorationChangeUserName = InputDecoration(
      hintText: 'neuer benutzername',
      errorText: null,
    );

    void changeUserName(StateSetter setStateDialog, StateSetter setStateParent) async {
      if (_newUserName.text == null || _newUserName.text.isEmpty) {
        setStateDialog(() {
          inputDecorationChangeUserName = InputDecoration(
            hintText: 'neuer benutzername',
            errorText: 'bitte gib einen neuen benutzername ein.',
          );
        });
        return;
      }
      if (_newUserName.text.length < 3) {
        setStateDialog(() {
          inputDecorationChangeUserName = InputDecoration(
            hintText: 'neuer benutzername',
            errorText: 'name muss mindestens 4 zeichen lang sein.',
          );
        });
        return;
      }

      if (_newUserName.text.length > 16) {
        setStateDialog(() {
          inputDecorationChangeUserName = InputDecoration(
            hintText: 'neuer benutzername',
            errorText: 'name darf höchstens 16 zeichen lang sein.',
          );
        });
        return;
      }

      try {
        await user.changeUserName(_newUserName.text);
        Navigator.of(context).pop();
        setStateParent(() => user.userName = _newUserName.text);
      } on PostgreSQLException {
        setStateDialog(() {
          inputDecorationChangeUserName = InputDecoration(
            hintText: 'neuer benutzername',
            errorText: 'name konnte nicht geändert werden.',
          );
        });
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          StateSetter setStateParent = setState;
          return AlertDialog(
            title: Text('benutzernamen ändern'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                return Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.name,
                        obscureText: false,
                        decoration: inputDecorationChangeUserName,
                        controller: _newUserName,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => changeUserName(setStateDialog, setStateParent),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('abbrechen', textScaleFactor: 0.9)),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            child: ElevatedButton(
                                onPressed: () => changeUserName(setStateDialog, setStateParent),
                                child: Text('bestätigen', textScaleFactor: 0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
  }

  void onShowFriendRequestDialog(SpektrumUser user) {
    inputDecorationNewFriend = InputDecoration(
      hintText: 'e-mail adresse',
      errorText: null,
    );
    StateSetter setStateParent = setState;

    void sendFriendRequest(StateSetter setStateDialog) async {
      if (_newUserName.text == null || _newUserName.text.isEmpty) {
        setStateDialog(() {
          inputDecorationNewFriend = InputDecoration(
            hintText: 'e-mail adresse',
            errorText: 'bitte gib deine e-mail adresse ein.',
          );
        });
        return;
      }
      if (!_newUserName.text.contains('@')) {
        setStateDialog(() {
          inputDecorationNewFriend = InputDecoration(
            hintText: 'e-mail adresse',
            errorText: 'bitte gib eine korrekte e-mail adresse ein.',
          );
        });
        return;
      }

      try {
        await user.sendFriendRequest(_newUserName.text.toLowerCase());
        setStateParent(() => user.pendingFriendRequestList.add(_newUserName.text.toLowerCase()));
        Navigator.of(context).pop();
      } on PostgreSQLException {
        setStateDialog(() {
          inputDecorationNewFriend = InputDecoration(
            hintText: 'e-mail adresse',
            errorText: 'nutzer wurde nicht gefunden.',
          );
        });
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('freund:in hinzufügen.'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                return Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        decoration: inputDecorationNewFriend,
                        controller: _newUserName,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => sendFriendRequest(setStateDialog),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('abbrechen', textScaleFactor: 0.9)),
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            child: ElevatedButton(
                                onPressed: () => sendFriendRequest(setStateDialog),
                                child: Text('bestätigen', textScaleFactor: 0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        });
  }

  void onFriendRequestAccepted(SpektrumUser user, String targetUserId) {
    user.acceptFriendRequest(targetUserId);
    setState(() {
      user.friendRequestList.remove(targetUserId);
      user.contactList.add(targetUserId);
      user.contactList.sort();
    });
  }

  Widget getFriendActionButton(SpektrumUser user, String targetUserId) {
    if (user.challengeList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.check),
        onPressed: () async {
          await user.acceptChallenge(targetUserId);
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GameRoomPage(
                      opponent: targetUserId,
                    )),
          );
          setState(() {
            user.challengeList.remove(targetUserId);
            user.openGameList.add(targetUserId);
          });
        },
      );
    } else if (user.challengeSentList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.autorenew),
        onPressed: null,
      );
    } else if (user.openGameList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.arrow_forward),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GameRoomPage(
                      opponent: targetUserId,
                    )),
          );
        },
      );
    } else {
      return IconButton(
        icon: Icon(Icons.mail_outline),
        onPressed: () {
          user.sendChallenge(targetUserId);
          setState(() {
            user.challengeSentList.add(targetUserId);
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
              return PageView(
                scrollDirection: Axis.horizontal,
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 50,
                      bottom: 20,
                      left: 20,
                      right: 20,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PopupMenuButton<MenuOption>(
                                offset: Offset(-MediaQuery.of(context).size.width / 5, MediaQuery.of(context).size.width / 6),
                                icon: user.profileImageId == null ? Icon(Icons.person) : ClipRRect(
                                  borderRadius: BorderRadius.circular(200.0),
                                  child: Image.asset('assets/portrait_id/${user.profileImageId}.jpg'),
                                ),
                                iconSize: MediaQuery.of(context).size.width / 6,
                                onSelected: (MenuOption selected) {
                                  selected.action(context, this, user);
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
                                  PopupMenuItem(
                                    value: MenuOption.profileImage,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: null,
                                          icon: user.profileImageId == null ? Icon(Icons.person) : ClipRRect(
                                            borderRadius: BorderRadius.circular(200.0),
                                            child: Image.asset('assets/portrait_id/${user.profileImageId}.jpg'),
                                          ),
                                          iconSize: 40,
                                        ),
                                        Icon(Icons.edit_rounded),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: MenuOption.userName,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(user.userName),
                                        Icon(Icons.edit_rounded),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: MenuOption.logOut,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('abmelden'),
                                        Icon(Icons.login_rounded),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                user.userName,
                                textScaleFactor: 1.2,
                              ),
                            ],
                          ),
                          Container(
                            padding: EdgeInsets.only(
                              top: MediaQuery.of(context).size.height / 5,
                              bottom: 50,
                            ),
                            child: Text(
                              'spektrum',
                              textScaleFactor: 3,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                            ),
                            alignment: Alignment.bottomCenter,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'freund:innen',
                                textScaleFactor: 1.1,
                                style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => onShowFriendRequestDialog(user),
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
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(
                      top: 100,
                      left: 20,
                      right: 20,
                      bottom: 20,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'freundschaftseinladungen',
                                textScaleFactor: 1.1,
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
                                          child: Text('annehmen', textScaleFactor: 0.8)),
                                    ],
                                  );
                                }),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'ausstehende freundschaftseinladungen',
                                textScaleFactor: 1.1,
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
                  ),
                ],
              );
            } else {
              return SizedBox(
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 5,
                    bottom: 50,
                  ),
                  child: Text(
                    'spektrum',
                    textScaleFactor: 3,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  alignment: Alignment.bottomCenter,
                ),
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
  String profileImageId;

  SpektrumUser(
      {this.userId,
      this.userName,
      this.contactList,
      this.friendRequestList,
      this.pendingFriendRequestList,
      this.challengeList,
      this.challengeSentList,
      this.openGameList,
      this.profileImageId});

  static Future<SpektrumUser> getUserById(String userId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> userMap = await connection.mappedResultsQuery('''
      SELECT name, profile_image_id
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
      profileImageId: userMap[0]['spektrum_user']['profile_image_id'],
      contactList: List<String>.from(friendMap.map((row) => row['friend']['user_friend']).toList()),
      friendRequestList: List<String>.from(friendRequestMap.map((row) => row['friend_request']['sender']).toList()),
      pendingFriendRequestList:
          List<String>.from(pendingFriendRequestMap.map((row) => row['friend_request']['receiver']).toList()),
      challengeList: List<String>.from(challengeMap.map((row) => row['game_request']['sender']).toList()),
      challengeSentList: List<String>.from(challengeSentMap.map((row) => row['game_request']['receiver']).toList()),
      openGameList: List<String>.from(openGameMap.map((row) => row['game']['other_player']).toList()),
    );
  }

  static Future<String> fetchProfileImageId(String userId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> map = await connection.mappedResultsQuery('''
      SELECT profile_image_id
      FROM spektrum_user
      WHERE id = @userId
      ''', substitutionValues: {'userId': userId});
    connection.close();
    return map[0]['spektrum_user']['profile_image_id'];
  }

  static Future<String> fetchUserName(String userId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> map = await connection.mappedResultsQuery('''
      SELECT name
      FROM spektrum_user
      WHERE id = @userId
      ''', substitutionValues: {'userId': userId});
    connection.close();
    return map[0]['spektrum_user']['name'];
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

  Future<void> changeUserName(String newUserName) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
      UPDATE spektrum_user
      SET name = @newUserName
      WHERE id = @userId
    ''', substitutionValues: {
      'userId': userId,
      'newUserName': newUserName,
    });
    connection.close();
  }

  Future<void> changeProfileImageId(String newProfileImageId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
      UPDATE spektrum_user
      SET profile_image_id = @newProfileImageId
      WHERE id = @userId
    ''', substitutionValues: {
      'userId': userId,
      'newProfileImageId': newProfileImageId,
    });
    connection.close();
  }

  Future<void> sendFriendRequest(String targetUserId) async {
    try {
      final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
      await connection.open();
      await connection.transaction((ctx) async {
        final List<Map<String, dynamic>> map = await ctx.mappedResultsQuery('''
            SELECT EXISTS(
              SELECT sender, receiver
              FROM friend_request
              WHERE sender = @targetUserId
                AND receiver = @userId
            )
            ''', substitutionValues: {
          'userId': userId,
          'targetUserId': targetUserId,
        });
        bool isAlreadyRequested = map[0]['']['exists'];
        if (!isAlreadyRequested) {
          await ctx.query('''
            INSERT INTO friend_request (sender, receiver)
            VALUES (@userId, @targetUserId)
          ''', substitutionValues: {
            'userId': userId,
            'targetUserId': targetUserId,
          });
        } else {
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
        }
      });
      connection.close();
    } catch (e) {
      rethrow;
    }
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
    await connection.transaction((ctx) async {
      final List<Map<String, dynamic>> map = await ctx.mappedResultsQuery('''
      SELECT EXISTS(
        SELECT sender, receiver
        FROM game_request
        WHERE sender = @targetUserId
          AND receiver = @userId
      )
      ''', substitutionValues: {
        'userId': userId,
        'targetUserId': targetUserId,
      });
      bool isAlreadyChallenged = map[0]['']['exists'];
      if (!isAlreadyChallenged) {
        await ctx.query('''
          INSERT INTO game_request (sender, receiver)
          VALUES (@userId, @targetUserId)
        ''', substitutionValues: {
          'userId': userId,
          'targetUserId': targetUserId,
        });
      } else {
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
      }
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
