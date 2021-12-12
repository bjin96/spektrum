import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
  String _errorMessage = '';
  bool _passwordVisible = false;

  void registerUser() async {
    if (_formKey.currentState.validate()) {
      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: _mail.text.toLowerCase(), password: _password.text);
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
        setState(() {
          _wrongCredentials = true;
          switch (e.code) {
            case ('email-already-in-use'):
              _errorMessage = 'account mit dieser e-mail existiert bereits.';
              break;
            case ('invalid-email'):
              _errorMessage = 'e-mail ist ungültig.';
              break;
            case ('weak-password'):
              _errorMessage = 'passwort muss min. 6 zahlen und buchstaben enthalten.';
              break;
          }
        });
      } catch (e) {
        setState(() {
          _wrongCredentials = true;
          _errorMessage = 'unvorhergesehener fehler. bitte app neustarten.';
        });
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
        setState(() {
          _wrongCredentials = true;
          switch (e.code) {
            case ('invalid-email'):
              _errorMessage = 'e-mail adresse ist nicht gültig.';
              break;
            case ('user-disabled'):
              _errorMessage = 'benutzer ist deaktiviert.';
              break;
            case ('user-not-found'):
              _errorMessage = 'benutzer existiert nicht.';
              break;
            case ('wrong-password'):
              _errorMessage = 'password ist falsch.';
              break;
          }
        });
      } catch (e) {
        setState(() {
          _wrongCredentials = true;
          _errorMessage = 'unvorhergesehener fehler. bitte app neustarten.';
        });
      }
    }
  }

  void resetPassword(String email) {
    TextEditingController resetEmail = TextEditingController(text: email);
    InputDecoration inputDecorationEmail = InputDecoration(
      hintText: 'e-mail adresse',
      errorText: null,
    );

    void _resetPassword(StateSetter setStateDialog) async {
      if (resetEmail.text == null || resetEmail.text.isEmpty) {
        setStateDialog(() {
          inputDecorationEmail = InputDecoration(
            hintText: 'e-mail adresse',
            errorText: 'bitte gib eine e-mail adresse ein.',
          );
        });
        return;
      }
      if (!resetEmail.text.contains('@')) {
        setStateDialog(() {
          inputDecorationEmail = InputDecoration(
            hintText: 'e-mail adresse',
            errorText: 'e-mail ist ungültig.',
          );
        });
        return;
      }

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmail.text);
        Navigator.of(context).pop();
      } on FirebaseAuthException catch (e) {
        switch (e.code) {
          case ('invalid-email'):
            setStateDialog(() {
              inputDecorationEmail = InputDecoration(
                hintText: 'e-mail adresse',
                errorText: 'e-mail ist ungültig.',
              );
            });
            break;
          case ('user-not-found'):
            setStateDialog(() {
              inputDecorationEmail = InputDecoration(
                hintText: 'e-mail adresse',
                errorText: 'e-mail wurde nicht gefunden.',
              );
            });
        }
      } catch (e) {
        setStateDialog(() {
          inputDecorationEmail = InputDecoration(
            hintText: 'e-mail adresse',
            errorText: 'unvorhergesehener fehler. bitte erneut versuchen.',
          );
        });
      }
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('passwort zurücksetzen'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setStateDialog) {
                return Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.emailAddress,
                        obscureText: false,
                        decoration: inputDecorationEmail,
                        controller: resetEmail,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: () => _resetPassword(setStateDialog),
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
                                onPressed: () => _resetPassword(setStateDialog),
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
                      obscureText: !_passwordVisible,
                      style: TextStyle(),
                      decoration: InputDecoration(
                        hintText: 'passwort',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (String value) {
                        if (value == null || value.isEmpty) {
                          return 'bitte gib dein passwort ein.';
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
                        _errorMessage,
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !_isRegisterMode,
                    child: Container(
                      padding: EdgeInsets.only(top: 10, left: 33, right: 40, bottom: 10),
                      child: Column(
                        children: [
                          Row(
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
                          Row(
                            children: [
                              TextButton(
                                child: Text('password vergessen?', style: TextStyle(fontSize: 12)),
                                onPressed: () => resetPassword(_mail.text),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Visibility(
                      visible: _isRegisterMode,
                      child: Container(
                        padding: EdgeInsets.only(top: 10, left: 33, right: 40, bottom: 10),
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
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
