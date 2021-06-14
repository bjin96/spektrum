import 'package:postgres/postgres.dart';

class SpektrumDatabase {

  static const String HOST = 'db-spektrum-do-user-4221323-0.b.db.ondigitalocean.com';
  static const int PORT = 25060;
  static const String DATABASE_NAME = 'defaultdb';
  static const String USERNAME = 'doadmin';
  static const String PASSWORD = 'p3stzq1xpfhnmdlr';
  static const bool USE_SSL = true;

  static PostgreSQLConnection getDatabaseConnection() {
    return PostgreSQLConnection(HOST, PORT, DATABASE_NAME, username: USERNAME, password: PASSWORD, useSSL: USE_SSL);
  }
}
