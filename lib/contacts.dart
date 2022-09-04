import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spektrum/model/image.dart';
import 'package:spektrum/socket_connection.dart';

import 'authentication.dart';
import 'game_room.dart';
import 'model/spektrum_user.dart';

enum MenuOption {
  userName,
  profileImage,
  logOut,
}

extension MenuOptionExtension on MenuOption {
  Function get action {
    switch (this) {
      case MenuOption.userName:
        return (BuildContext context, _ContactPageState contactPage, SpektrumUser user, List<String> speakerIdList) {
          contactPage.onShowChangeUserNameDialog(user);
        };
      case MenuOption.profileImage:
        return (BuildContext context, _ContactPageState contactPage, SpektrumUser user, List<String> speakerIdList) {
          contactPage.onShowChangeProfileImageDialog(user, speakerIdList);
        };
      case MenuOption.logOut:
        return (BuildContext context, _ContactPageState contactPage, SpektrumUser user, List<String> speakerIdList) async {
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

  SpektrumUser user;
  List<String> contactList;
  List<String> friendRequestList;
  List<String> pendingFriendRequestList;
  List<String> openGameList;
  List<Map<String, dynamic>> finishedGameList;
  List<String> challengeList;
  List<String> challengeSentList;
  List<String> speakerIdList;

  Future dataLoaded;

  TextEditingController _newUserName = TextEditingController();
  InputDecoration inputDecorationNewFriend;
  InputDecoration inputDecorationChangeUserName;

  PageController _pageController = PageController(initialPage: 1);

  _ContactPageState();

  @override
  initState() {
    super.initState();
    dataLoaded = setContactData();
    SocketConnection.registerEventHandler('new_friend_request', handleNewFriendRequest);
    SocketConnection.registerEventHandler('friend_request_accepted', handleFriendRequestAccepted);
    SocketConnection.registerEventHandler('new_challenge', handleNewChallenge);
    SocketConnection.registerEventHandler('challenge_accepted', handleChallengeAccepted);
    SocketConnection.registerEventHandler('both_finished_game', handleBothFinishedGame);
  }

  @override
  dispose() {
    super.dispose();
    SocketConnection.clearHandler('new_friend_request', handleNewFriendRequest);
    SocketConnection.clearHandler('friend_request_accepted', handleFriendRequestAccepted);
    SocketConnection.clearHandler('new_challenge', handleNewChallenge);
    SocketConnection.clearHandler('challenge_accepted', handleChallengeAccepted);
    SocketConnection.clearHandler('both_finished_game', handleBothFinishedGame);
  }

  Future setContactData() async {
    final Map<String, dynamic> body = {'userId': FirebaseAuth.instance.currentUser.email};
    Map<String, dynamic> json = await SocketConnection.send('view_contact_page', body);

    this.user = SpektrumUser.fromJson(json['user']);
    this.contactList = List<String>.from(json['contactList']);
    this.friendRequestList = List<String>.from(json['friendRequestList']);
    this.pendingFriendRequestList = List<String>.from(json['pendingFriendRequestList']);
    this.challengeList = List<String>.from(json['challengeList']);
    this.challengeSentList = List<String>.from(json['challengeSentList']);
    this.openGameList = List<String>.from(json['openGameList']);
    this.finishedGameList = List<Map<String, dynamic>>.from(json['finishedGameList']);
    this.speakerIdList = List<String>.from(json['speakerIdList']);
  }

  void handleNewFriendRequest(dynamic json) {
    this.setState(() {
      this.friendRequestList.add(json['userId']);
      this.contactList.add(json['userId']);
    });
  }

  void handleFriendRequestAccepted(dynamic json) {
    this.setState(() {
      this.pendingFriendRequestList.remove(json['userId']);
    });
  }

  void handleNewChallenge(dynamic json) {
    this.setState(() {
      this.challengeList.add(json['userId']);
    });
  }

  void handleChallengeAccepted(dynamic json) {
    this.setState(() {
      this.challengeSentList.remove(json['userId']);
      this.openGameList.add(json['userId']);
    });
  }

  void handleBothFinishedGame(dynamic json) {
    this.setState(() {
      this.openGameList.remove(json['userId']);
    });
  }

  void onShowChangeProfileImageDialog(SpektrumUser user, List<String> speakerIdList) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        StateSetter setStateParent = setState;
        return AlertDialog(
          title: Text('profilbild wählen'),
          content: Container(
              width: 200,
              child: GridView.builder(

                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                ),
                shrinkWrap: true,
                itemCount: speakerIdList.length,
                itemBuilder: (BuildContext ctx, index) {
                  return FutureBuilder(
                      future: PoliticianImage.getPoliticianImageAndCopyright(speakerIdList[index]),
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return IconButton(
                            iconSize: MediaQuery
                                .of(context)
                                .size
                                .width / 3,
                            tooltip: snapshot.data['copyright'],
                            onPressed: () async {
                              await user.changeProfileImageId(speakerIdList[index]);
                              Navigator.of(context).pop();
                              setStateParent(() => user.profileImageId = speakerIdList[index]);
                            },
                            icon: ClipRRect(
                              borderRadius: BorderRadius.circular(200.0),
                              child: snapshot.data['image'],
                            ),
                          );
                        } else {
                          return IconButton(
                            iconSize: MediaQuery
                                .of(context)
                                .size
                                .width / 3,
                            onPressed: () async {
                              await user.changeProfileImageId(speakerIdList[index]);
                              Navigator.of(context).pop();
                              setStateParent(() => user.profileImageId = speakerIdList[index]);
                            },
                            icon: Icon(
                              Icons.person_pin,
                              size: 65,
                            ),
                          );
                        }
                      }
                    );
                  }
                ),
              )
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
      } catch (exception) {
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

  void onShowFriendRequestDialog() {
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
        setStateParent(() => pendingFriendRequestList.add(_newUserName.text.toLowerCase()));
        Navigator.of(context).pop();
      } catch (exception) {
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

  Widget getFriendActionButton(String targetUserId) {
    void _onFriendRequestAccepted(String targetUserId) {
      user.acceptFriendRequest(targetUserId);
      setState(() {
        friendRequestList.remove(targetUserId);
        contactList.sort();
      });
    }

    Future<void> _onAcceptChallenge(String targetUserId) async {
      await user.acceptChallenge(targetUserId);
      setState(() {
        challengeList.remove(targetUserId);
        openGameList.add(targetUserId);
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GameRoomPage(
            user: user,
            opponent: targetUserId,
          ),
        ),
      );
    }

    void _onSendChallenge(String targetUserId) {
      user.sendChallenge(targetUserId);
      setState(() {
        challengeSentList.add(targetUserId);
      });
    }

    Future<void> _onOpenGame(String targetUserId) async {
      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => GameRoomPage(
              user: user,
              opponent: targetUserId,
            ),
        ),
      );
    }

    if (friendRequestList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.person_add_outlined),
        onPressed: () => _onFriendRequestAccepted(targetUserId),
      );
    } else if (pendingFriendRequestList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.person_add_outlined),
        onPressed: null,
      );
    } else if (challengeList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.check),
        onPressed: () => _onAcceptChallenge(targetUserId),
      );
    } else if (challengeSentList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.mail_outline),
        onPressed: null,
      );
    } else if (openGameList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.arrow_forward),
        onPressed: () => _onOpenGame(targetUserId),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.mail_outline),
        onPressed: () => _onSendChallenge(targetUserId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder(
          future: dataLoaded,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return PageView(
                scrollDirection: Axis.horizontal,
                controller: _pageController,
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      top: 100,
                      left: 20,
                      right: 20,
                      bottom: 0,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'spielverlauf',
                                textScaleFactor: 2.0,
                                style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView.builder(
                                itemCount: finishedGameList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String targetUserId = finishedGameList[index]['otherPlayer'];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(targetUserId),
                                      IconButton(
                                        icon: Icon(Icons.arrow_forward),
                                        onPressed: () =>  {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => GameRoomPage(
                                                user: user,
                                                opponent: targetUserId,
                                                userGameId: finishedGameList[index]['gameId']
                                              ),
                                            ),
                                          ),
                                        }
                                      ),
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
                              FutureBuilder(
                                  future: PoliticianImage.getPoliticianImageAndCopyright(user.profileImageId),
                                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                                    Widget icon;
                                    String copyright;
                                    if (snapshot.connectionState == ConnectionState.done) {
                                      icon = ClipRRect(
                                          borderRadius: BorderRadius.circular(200.0),
                                          child: snapshot.data['image'],
                                      );
                                      copyright = snapshot.data['copyright'];
                                    } else {
                                      icon = Icon(
                                        Icons.person_pin,
                                        size: 65,
                                      );
                                      copyright = 'Copyright loading...';
                                    }
                                    return PopupMenuButton<MenuOption>(
                                      offset: Offset(-MediaQuery.of(context).size.width / 5, MediaQuery.of(context).size.width / 6),
                                      icon: icon,
                                      tooltip: copyright,
                                      iconSize: MediaQuery.of(context).size.width / 6,
                                      onSelected: (MenuOption selected) {
                                        selected.action(context, this, user, speakerIdList);
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
                                        PopupMenuItem(
                                          value: MenuOption.profileImage,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              IconButton(
                                                onPressed: null,
                                                tooltip: copyright,
                                                icon: user.profileImageId == null ? Icon(Icons.person_pin) : ClipRRect(
                                                  borderRadius: BorderRadius.circular(200.0),
                                                  child: icon,
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
                                    );
                                  }
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
                          Flexible(
                            child: ListView.builder(
                                itemCount: openGameList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String targetUserId = openGameList[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(targetUserId),
                                      getFriendActionButton(targetUserId),
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
                      bottom: 0,
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'freund:innen',
                                textScaleFactor: 2.0,
                                style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => onShowFriendRequestDialog(),
                                icon: Icon(Icons.person_add_outlined),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView.builder(
                                itemCount: contactList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String targetUserId = contactList[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(targetUserId),
                                      getFriendActionButton(targetUserId),
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
