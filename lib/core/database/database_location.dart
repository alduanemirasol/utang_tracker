import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseLocation {
  DatabaseLocation._();

  static const databaseName = 'utang_tracker';
  static const databaseFileName = '$databaseName.sqlite';

  static Future<File> liveFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, databaseFileName));
  }
}
