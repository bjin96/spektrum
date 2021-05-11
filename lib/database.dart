import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;


class SpektrumDatabase {

  static const String DATABASE_FILE_NAME = 'spektrum.db';
  static bool dbIsCopied = false;

  static Future<Database> getDatabase() async {
    String dbPath = join(await getDatabasesPath(), DATABASE_FILE_NAME);
    if (!dbIsCopied) {
      ByteData data = await rootBundle.load(join("assets", DATABASE_FILE_NAME));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await io.File(dbPath).writeAsBytes(bytes, flush: true);
      dbIsCopied = true;
    }
    return openDatabase(
      dbPath,
      singleInstance: false,
    );
  }
}