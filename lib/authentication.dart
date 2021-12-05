import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spektrum/contacts.dart';

import 'model/spektrum_user.dart';


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
  bool _wrongCredentials = false;

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
          profileImageId: '11003638',
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

  void signIn(StateSetter setState) async {
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
        setState(() => _wrongCredentials = true);
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
            childAspectRatio: MediaQuery.of(context).size.width /
                (MediaQuery.of(context).size.height -
                    (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom)) *
                2,
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
                    padding: EdgeInsets.only(top: 10, left: 40, right: 40, bottom: 10),
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
                    padding: EdgeInsets.only(top: 10, left: 40, right: 40, bottom: 10),
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
                      onEditingComplete: _isRegisterMode ? null : () => {signIn(setState)},
                    ),
                  ),
                  Visibility(
                    visible: _isRegisterMode,
                    child: Container(
                      padding: EdgeInsets.only(top: 10, left: 40, right: 40, bottom: 10),
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
                      visible: _wrongCredentials,
                      child: Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(top: 10, left: 40, right: 40, bottom: 10),
                        child: Text(
                          'benutzername oder password falsch.',
                          style: TextStyle(color: Colors.red[700], fontSize: 12),
                        ),
                      ),
                  ),
                  Visibility(
                    visible: !_isRegisterMode,
                    child: Container(
                      padding: EdgeInsets.only(top: 10, left: 40, right: 40, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: Text('noch keinen account?', style: TextStyle(fontSize: 12)),
                            onPressed: () => setState(() => _isRegisterMode = true),
                          ),
                          ElevatedButton(
                            child: Text('anmelden', style: TextStyle(fontSize: 12)),
                            onPressed: () => {signIn(setState)},
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                    visible: _isRegisterMode,
                    child: Container(
                      padding: EdgeInsets.only(top: 10, left: 40, right: 40, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: Text('bereits einen account?', style: TextStyle(fontSize: 12)),
                            onPressed: () => setState(() => _isRegisterMode = false),
                          ),
                          ElevatedButton(
                            child: Text('registrieren', style: TextStyle(fontSize: 12)),
                            onPressed: () => {registerUser()},
                          ),
                        ],
                      ),
                    )
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
