import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logging/app_logger.dart';
import 'tables/devices.dart';
import 'tables/sync_cursor.dart';
import 'tables/sync_outbox.dart';

part 'app_database.g.dart';

class DatabaseCorruptedException implements Exception {
  final String message;
  DatabaseCorruptedException(this.message);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);

    final file = File(p.join(directory.path, 'motaz_app.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        database.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}

Future<File> getDatabaseFile() async {
  final directory = await getApplicationSupportDirectory();
  return File(p.join(directory.path, 'motaz_app.sqlite'));
}

Future<void> resetDatabaseFiles() async {
  final dbFile = await getDatabaseFile();
  if (await dbFile.exists()) {
    await dbFile.delete();
  }

  final walFile = File('${dbFile.path}-wal');
  if (await walFile.exists()) {
    await walFile.delete();
  }

  final shmFile = File('${dbFile.path}-shm');
  if (await shmFile.exists()) {
    await shmFile.delete();
  }
}

@DriftDatabase(tables: [Devices, SyncOutbox, SyncCursor])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 1) {
        await m.createAll();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON;');
      await customStatement('PRAGMA journal_mode = WAL;');
    },
  );

  Future<void> initialize() async {
    AppLog.db('Opening local database');
    await customSelect('SELECT 1').get();
    AppLog.db('Local database opened successfully');
  }

  Future<void> closeConnection() => close();

  Future<void> resetDatabase() async {
    await close();
    AppLog.db('Resetting local database files');
    await resetDatabaseFiles();
  }

  static Future<AppDatabase> createWithCorruptionDetection() async {
    try {
      final db = AppDatabase();
      await db.initialize();
      return db;
    } catch (e) {
      AppLog.error('Database corruption or open failure detected', e);
      throw DatabaseCorruptedException(
        'فشل في فتح قاعدة البيانات. قد تكون البيانات تالفة.',
      );
    }
  }
}
