import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spektrum/contacts.dart';


class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({Key key}) : super(key: key);

  @override
  _AuthenticationPageState createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  _AuthenticationPageState();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController _mail = TextEditingController();
  TextEditingController _password = TextEditingController();
  bool _isRegisterMode = false;

  void registerUser() async {
    if (_formKey.currentState.validate()) {
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _mail.text.toLowerCase(),
            password: _password.text
        );
        await SpektrumUser(
          userId: _mail.text.toLowerCase(),
          userName: _mail.text.toLowerCase(),
          contactList: <String>[],
          friendRequestList: <String>[],
          pendingFriendRequestList: <String>[],
          challengeList: <String>[],
          challengeSentList: <String>[],
          openGameList: <String>[],
        ).createUser();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ContactPage()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'weak-password') {
          print('The password provided is too weak.');
        } else if (e.code == 'email-already-in-use') {
          print('The account already exists for that email.');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  void signIn() async {
    if (_formKey.currentState.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _mail.text.toLowerCase(),
          password: _password.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ContactPage()),
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          print('No user found for that email.');
        } else if (e.code == 'wrong-password') {
          print('Wrong password provided for that user.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: _formKey,
          child: GridView.count(
            crossAxisCount: 1,
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: 50,
                  bottom: 100,
                ),
                child: Text(
                  'spektrum',
                  textScaleFactor: 3,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                alignment: Alignment.bottomCenter,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.only(top: 10, left: 50, right: 50, bottom: 10),
                    child: TextFormField(
                      keyboardType: TextInputType.emailAddress,
                      obscureText: false,
                      decoration: InputDecoration(hintText: 'e-mail'),
                      validator: (String value) {
                        if (value == null || value.isEmpty) {
                          return 'bitte gib deine e-mail adresse ein.';
                        }
                        if (!value.contains('@')) {
                          return 'bitte gib eine korrekte e-Mail adresse ein.';
                        }
                        return null;
                      },
                      controller: _mail,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 10, left: 50, right: 50, bottom: 10),
                    child: TextFormField(
                      obscureText: true,
                      style: TextStyle(),
                      decoration: InputDecoration(
                        hintText: 'passwort',
                      ),
                      validator: (String value) {
                        if (value == null || value.isEmpty) {
                          return 'bitte gib dein passwort ein.';
                        }
                        if (value.length < 8) {
                          return 'passwort muss mindesten 8 zeichen enthalten.';
                        }
                        return null;
                      },
                      controller: _password,
                      textInputAction: _isRegisterMode ? TextInputAction.next : TextInputAction.done,
                      onEditingComplete: _isRegisterMode ? null : () => {signIn()},
                    ),
                  ),
                  Visibility(
                    visible: _isRegisterMode,
                    child: Container(
                      padding: EdgeInsets.only(top: 10, left: 50, right: 50, bottom: 10),
                      child: TextFormField(
                        obscureText: true,
                        style: TextStyle(),
                        decoration: InputDecoration(
                          hintText: 'passwort wiederholen',
                        ),
                        validator: (String value) {
                          if (value != _password.text) {
                            return 'passwörter müssen übereinstimmen.';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => registerUser(),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !_isRegisterMode,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          child: ElevatedButton(
                            child: Text('anmelden'),
                            onPressed: () => {signIn()},
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: TextButton(
                            child: Text('noch keinen account?'),
                            onPressed: () => setState(() => _isRegisterMode = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: _isRegisterMode,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          child: ElevatedButton(
                            child: Text('registrieren'),
                            onPressed: () => {registerUser()},
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.all(10),
                          child: TextButton(
                            child: Text('bereits einen account?'),
                            onPressed: () => setState(() => _isRegisterMode = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
