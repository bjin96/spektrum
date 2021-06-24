import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spektrum/authentication.dart';
import 'package:firebase_core/firebase_core.dart';

import 'contacts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  Widget _app = MaterialApp(
    title: 'spektrum',
    theme: ThemeData(
      primarySwatch: Colors.blueGrey,
      fontFamily: 'RobotoMono',
    ),
    home: Scaffold(
      body: Center(
        child: Text('lädt...'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            title: 'spektrum',
            theme: ThemeData(
              primarySwatch: Colors.blueGrey,
              fontFamily: 'RobotoMono',
            ),
            home: Scaffold(
              body: Center(
                child: Text(snapshot.error.toString()),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          User user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            _app = MaterialApp(
              title: 'spektrum',
              theme: ThemeData(
                primarySwatch: Colors.blueGrey,
                fontFamily: 'RobotoMono',
              ),
              home: AuthenticationPage(),
            );
          } else {
            _app = MaterialApp(
              title: 'spektrum',
              theme: ThemeData(
                primarySwatch: Colors.blueGrey,
                fontFamily: 'RobotoMono',
              ),
              home: ContactPage(),
            );
          }
        }
        return _app;
      },
    );
  }
}
