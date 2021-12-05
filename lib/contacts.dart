import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:postgres/postgres.dart';

import 'authentication.dart';
import 'game_room.dart';
import 'model/spektrum_user.dart';
import 'model/pageInfo.dart';

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

  Future<ContactPageInfo> contactPageInfo;

  TextEditingController _newUserName = TextEditingController();
  InputDecoration inputDecorationNewFriend;
  InputDecoration inputDecorationChangeUserName;

  _ContactPageState() {
    this.contactPageInfo = ContactPageInfo.getContactPageInfo(FirebaseAuth.instance.currentUser.email);
  }

  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 60), (timer) {
      if (mounted) {
        setState(() {
          contactPageInfo = ContactPageInfo.getContactPageInfo(FirebaseAuth.instance.currentUser.email);
        });
      }
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

  void onShowFriendRequestDialog(ContactPageInfo contactPageInfo) {
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
        await contactPageInfo.user.sendFriendRequest(_newUserName.text.toLowerCase());
        setStateParent(() => contactPageInfo.pendingFriendRequestList.add(_newUserName.text.toLowerCase()));
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

  void onFriendRequestAccepted(ContactPageInfo contactPageInfo, String targetUserId) {
    contactPageInfo.user.acceptFriendRequest(targetUserId);
    setState(() {
      contactPageInfo.friendRequestList.remove(targetUserId);
      contactPageInfo.contactList.add(targetUserId);
      contactPageInfo.contactList.sort();
    });
  }

  Widget getFriendActionButton(ContactPageInfo contactPageInfo, String targetUserId) {
    if (contactPageInfo.friendRequestList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.person_add_outlined),
        onPressed: () => onFriendRequestAccepted(contactPageInfo, targetUserId),
      );
    } else if (contactPageInfo.pendingFriendRequestList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.person_add_outlined),
        onPressed: null,
      );
    } else if (contactPageInfo.challengeList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.check),
        onPressed: () async {
          await contactPageInfo.user.acceptChallenge(targetUserId);
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GameRoomPage(
                      user: contactPageInfo.user,
                      opponent: targetUserId,
                    ),
              maintainState: false,
            ),
          );
          setState(() {
            contactPageInfo.challengeList.remove(targetUserId);
            contactPageInfo.openGameList.add(targetUserId);
          });
        },
      );
    } else if (contactPageInfo.challengeSentList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.mail_outline),
        onPressed: null,
      );
    } else if (contactPageInfo.openGameList.contains(targetUserId)) {
      return IconButton(
        icon: Icon(Icons.arrow_forward),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => GameRoomPage(
                      user: contactPageInfo.user,
                      opponent: targetUserId,
                    ),
              maintainState: false
            ),
          );
        },
      );
    } else {
      return IconButton(
        icon: Icon(Icons.mail_outline),
        onPressed: () {
          contactPageInfo.user.sendChallenge(targetUserId);
          setState(() {
            contactPageInfo.challengeSentList.add(targetUserId);
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
          future: contactPageInfo,
          builder: (BuildContext context, AsyncSnapshot<ContactPageInfo> snapshot) {
            if (snapshot.hasData) {
              ContactPageInfo contactPageInfo = snapshot.data;
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
                                icon: contactPageInfo.user.profileImageId == null ? Icon(Icons.person_pin) : ClipRRect(
                                  borderRadius: BorderRadius.circular(200.0),
                                  child: Image.asset('assets/portrait_id/${contactPageInfo.user.profileImageId}.jpg'),
                                ),
                                iconSize: MediaQuery.of(context).size.width / 6,
                                onSelected: (MenuOption selected) {
                                  selected.action(context, this, contactPageInfo.user, contactPageInfo.speakerIdList);
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
                                  PopupMenuItem(
                                    value: MenuOption.profileImage,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                          onPressed: null,
                                          icon: contactPageInfo.user.profileImageId == null ? Icon(Icons.person_pin) : ClipRRect(
                                            borderRadius: BorderRadius.circular(200.0),
                                            child: Image.asset('assets/portrait_id/${contactPageInfo.user.profileImageId}.jpg'),
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
                                        Text(contactPageInfo.user.userName),
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
                                contactPageInfo.user.userName,
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
                                itemCount: contactPageInfo.openGameList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String targetUserId = contactPageInfo.openGameList[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(targetUserId),
                                      getFriendActionButton(contactPageInfo, targetUserId),
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
                                onPressed: () => onShowFriendRequestDialog(contactPageInfo),
                                icon: Icon(Icons.person_add_outlined),
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView.builder(
                                itemCount: contactPageInfo.contactList.length,
                                itemBuilder: (BuildContext context, int index) {
                                  String targetUserId = contactPageInfo.contactList[index];
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(targetUserId),
                                      getFriendActionButton(contactPageInfo, targetUserId),
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
