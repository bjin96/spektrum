import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spektrum/authentication.dart';

import 'contacts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Widget _home = Scaffold(
    body: Center(
      child: Container(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return FutureBuilder(
      future: Firebase.initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _home = Scaffold(
            body: Center(
              child: Text(snapshot.error.toString()),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          User user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _home = AuthenticationPage();
          } else {
            _home = ContactPage();
          }
        }
        return MaterialApp(
          title: 'spektrum',
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            fontFamily: 'RobotoMono',
          ),
          home: _home,
        );
      },
    );
  }
}
