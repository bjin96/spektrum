import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'game.dart';

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
      print(_mail);
      print(_password);
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _mail.text,
            password: _password.text
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GamePage(title: 'spektrum')),
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
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _mail.text,
          password: _password.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GamePage(title: 'spektrum')),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
              ),
              Container(
                padding: EdgeInsets.only(top: 10, left: 50, right: 50, bottom: 10),
                child: TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  obscureText: false,
                  decoration: InputDecoration(hintText: 'E-Mail'),
                  validator: (String value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib deine E-Mail Adresse ein.';
                    }
                    if (!value.contains('@')) {
                      return 'Bitte gib eine korrekte E-Mail Adresse ein.';
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
                    hintText: 'Passwort',
                  ),
                  validator: (String value) {
                    if (value == null || value.isEmpty) {
                      return 'Bitte gib dein Passwort ein.';
                    }
                    if (value.length < 8) {
                      return 'Passwort muss mindesten 8 Zeichen enthalten.';
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
                      hintText: 'Passwort wiederholen',
                    ),
                    validator: (String value) {
                      if (value != _password.text) {
                        return 'Passwörter müssen übereinstimmen.';
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
                        child: Text('Anmelden'),
                        onPressed: () => {signIn()},
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      child: TextButton(
                        child: Text('Noch keinen Account?'),
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
                        child: Text('Registrieren'),
                        onPressed: () => {registerUser()},
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      child: TextButton(
                        child: Text('Bereits einen Account?'),
                        onPressed: () => setState(() => _isRegisterMode = false),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
