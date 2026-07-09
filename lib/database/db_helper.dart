import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/site.dart';
import '../models/user.dart';

/// Singleton wrapper around the local SQLite database.
/// Offline-first architecture.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static Database? _db;
  static Future<Database>? _dbFuture;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _dbFuture ??= _initDb();
    _db = await _dbFuture!;
    return _db!;
  }

  static const String _dbFileName = 'georura.db';
  static const String _backupFolderName = 'db_backups';
  static const String _exportFolderName = 'db_exports';
  static const int _dbVersion = 1;

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbFileName);

    return openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  Future<String> get _currentDatabasePath async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbFileName);
  }

  Future<Directory> _storageDirectory() async {
    final external = await getExternalStorageDirectory();
    if (external != null) return external;
    return getApplicationDocumentsDirectory();
  }

  Future<Directory> _ensureDirectory(String folderName) async {
    final baseDir = await _storageDirectory();
    final dir = Directory(join(baseDir.path, folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  // ---------------------------------------------------------------------------
  // DATABASE SCHEMA
  // ---------------------------------------------------------------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firestore_id TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0,
        name TEXT NOT NULL,
        village TEXT NOT NULL,
        type TEXT NOT NULL,
        registered_at TEXT NOT NULL,
        image_path TEXT,
        image_paths TEXT,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        altitude REAL,
        captured_at TEXT,
        address TEXT,
        landmark TEXT,
        description TEXT,
        household_head TEXT,
        household_size INTEGER,
        males INTEGER,
        females INTEGER,
        children INTEGER,
        adults INTEGER,
        pensioners INTEGER,
        chronic_members INTEGER,
        phone_number TEXT,
        services TEXT,
        notes TEXT,
        site_code TEXT,
        province TEXT,
        district TEXT,
        municipality TEXT,
        ward TEXT,
        traditional_authority TEXT,
        section TEXT,
        distance_from_landmark REAL,
        directions TEXT,
        income_bracket TEXT,
        employed_count INTEGER,
        unemployed_count INTEGER,
        grant_recipients INTEGER,
        road_access TEXT,
        landmark_accesses TEXT,
        created_by TEXT,
        created_by_uid TEXT,
        created_by_name TEXT,
        last_updated TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE users(
        name TEXT NOT NULL,
        email TEXT PRIMARY KEY NOT NULL,
        phone TEXT,
        role TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        lastLogin TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_sites_village ON sites(village)');
    await db.execute('CREATE INDEX idx_sites_type ON sites(type)');
    await db.execute('CREATE INDEX idx_sites_synced ON sites(isSynced)');
    await db.execute('CREATE INDEX idx_users_role ON users(role)');
  }

  // ---------------------------------------------------------------------------
  // SITE CRUD - LOCAL FIRST
  // ---------------------------------------------------------------------------

  /// Registers a new site locally. New sites always start unsynced with no
  /// Firestore id — they get assigned one once pushed to the backend.
  Future<int> insertSite(Site site) async {
    final db = await database;
    final map = site.toMap();
    map.remove('id');
    map['isSynced'] = 0;
    map['firestore_id'] = null;
    map['last_updated'] = DateTime.now().toIso8601String();
    return db.insert(
      'sites',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Updates an existing site and returns the number of rows affected.
  /// Always stamps `last_updated`, and marks the record unsynced whenever it
  /// already has a Firestore id (i.e. it was edited after a previous sync).
  Future<int> updateSite(Site site) async {
    if (site.id == null) {
      throw ArgumentError('Cannot update a site without an id.');
    }

    final db = await database;
    final map = site.toMap();
    map['last_updated'] = DateTime.now().toIso8601String();
    if (site.firestoreId != null) {
      map['isSynced'] = 0; // Mark for re-sync if edited
    }

    final updated = await db.update(
      'sites',
      map,
      where: 'id = ?',
      whereArgs: [site.id],
    );
    return updated;
  }

  Future<int> deleteSite(int id) async {
    final db = await database;
    return db.delete('sites', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteAllSites() async {
    final db = await database;
    return db.delete('sites');
  }

  Future<List<Site>> getAllSites({int? limit}) async {
    final db = await database;
    final rows = await db.query(
      'sites',
      orderBy: 'registered_at DESC',
      limit: limit,
    );
    return rows.map((e) => Site.fromMap(e)).toList();
  }

  Future<Site?> getSite(int id) async {
    final db = await database;
    final rows = await db.query(
      'sites',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Site.fromMap(rows.first);
  }

  Future<List<Site>> searchSites(String query) async {
    final db = await database;
    final rows = await db.query(
      'sites',
      where: 'name LIKE ? OR village LIKE ? OR household_head LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'registered_at DESC',
    );
    return rows.map((e) => Site.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // SYNC HELPERS
  // ---------------------------------------------------------------------------

  Future<int> markSiteUnsynced(int id) async {
    final db = await database;
    return db.update(
      'sites',
      {'isSynced': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Site>> getUnsyncedSites() async {
    final db = await database;
    final rows = await db.query(
      'sites',
      where: 'isSynced = 0',
      orderBy: 'registered_at ASC',
    );
    return rows.map((e) => Site.fromMap(e)).toList();
  }

  Future<int> markSiteSynced(int id, String firestoreId) async {
    final db = await database;
    return db.update(
      'sites',
      {
        'isSynced': 1,
        'firestore_id': firestoreId,
        'last_updated': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sites WHERE isSynced = 0'),
        ) ??
        0;
  }

  // ---------------------------------------------------------------------------
  // USER CRUD
  // ---------------------------------------------------------------------------

  /// Registers a new user locally.
  Future<int> insertUser(AppUser user) async {
    if (user.email.trim().isEmpty) {
      throw ArgumentError('Cannot register a user without an email.');
    }

    final db = await database;
    final map = user.toSqliteMap();
    map['createdAt'] = (map['createdAt'] as String?)?.isNotEmpty == true
        ? map['createdAt']
        : DateTime.now().toIso8601String();

    return db.insert(
      'users',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AppUser>> getAllUsers({String? filterRole}) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: filterRole != null ? 'role = ?' : null,
      whereArgs: filterRole != null ? [filterRole] : null,
      orderBy: 'createdAt DESC',
    );
    return maps.map((e) => AppUser.fromMap(e)).toList();
  }

  Future<AppUser?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AppUser.fromMap(maps.first);
  }

  /// Updates an existing user and returns the number of rows affected.
  Future<int> updateUser(AppUser user) async {
    if (user.email.trim().isEmpty) {
      throw ArgumentError('Cannot update a user without an email.');
    }

    final db = await database;
    final updated = await db.update(
      'users',
      user.toSqliteMap(),
      where: 'email = ?',
      whereArgs: [user.email],
    );
    return updated;
  }

  Future<int> deleteUser(String email) async {
    final db = await database;
    return db.delete('users', where: 'email = ?', whereArgs: [email]);
  }

  Future<int> getUserCountByRole(String role) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE role = ?',
      [role],
    );
    return result.first['count'] as int;
  }

  Future<int> getUserCount() async {
    final db = await database;
    return Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
  }

  Future<bool> hasAdminUser() async {
    final db = await database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery("SELECT COUNT(*) FROM users WHERE role = 'Admin'"),
        ) ??
        0;
    return count > 0;
  }

  // ---------------------------------------------------------------------------
  // STATS
  // ---------------------------------------------------------------------------

  Future<Map<String, int>> getFieldStats() async {
    final db = await database;
    final totalSites =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sites'),
        ) ??
        0;
    final gpsCaptured =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sites WHERE latitude IS NOT NULL AND longitude IS NOT NULL',
          ),
        ) ??
        0;
    final pendingSync =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sites WHERE isSynced = 0'),
        ) ??
        0;

    return {
      'totalSites': totalSites,
      'gpsCaptured': gpsCaptured,
      'pendingSync': pendingSync,
    };
  }

  Future<String> getDatabaseSize() async {
    try {
      final path = await _currentDatabasePath;
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.length();
        if (bytes < 1024 * 1024) {
          return '${(bytes / 1024).toStringAsFixed(1)} KB';
        }
        return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
      }
      return '0 KB';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<DashboardStats> getDashboardStats() async {
    final db = await database;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfToday.subtract(Duration(days: now.weekday - 1));

    final total =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sites'),
        ) ??
        0;
    final today =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sites WHERE registered_at >= ?',
            [startOfToday.toIso8601String()],
          ),
        ) ??
        0;
    final week =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM sites WHERE registered_at >= ?',
            [startOfWeek.toIso8601String()],
          ),
        ) ??
        0;

    final villageRows = await db.rawQuery(
      'SELECT village, COUNT(*) AS cnt FROM sites GROUP BY village ORDER BY cnt DESC',
    );
    final Map<String, int> villageCounts = {};
    for (final row in villageRows) {
      final village = row['village']?.toString() ?? '';
      final count = row['cnt'] is int
          ? row['cnt'] as int
          : int.tryParse(row['cnt']?.toString() ?? '') ?? 0;
      if (village.isNotEmpty) villageCounts[village] = count;
    }

    final typeRows = await db.rawQuery(
      'SELECT type, COUNT(*) AS cnt FROM sites GROUP BY type',
    );
    final Map<SiteType, int> typeCounts = {};
    for (final row in typeRows) {
      final typeValue = row['type']?.toString() ?? '';
      final typeCount = row['cnt'] is int
          ? row['cnt'] as int
          : int.tryParse(row['cnt']?.toString() ?? '') ?? 0;
      typeCounts[SiteTypeX.fromString(typeValue)] = typeCount;
    }

    return DashboardStats(
      totalSites: total,
      registeredToday: today,
      registeredThisWeek: week,
      villageCount: villageCounts.length,
      countsByType: typeCounts,
      countsByVillage: villageCounts,
    );
  }

  // ---------------------------------------------------------------------------
  // CSV IMPORT
  // ---------------------------------------------------------------------------

  Future<int> importSitesFromCsv(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) throw Exception('File not found: $filePath');

    final csvString = await file.readAsString();
    final List<List<dynamic>> rows = const CsvToListConverter().convert(
      csvString,
    );
    if (rows.length <= 1) return 0;

    final headers = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    final db = await database;
    int imported = 0;

    await db.transaction((txn) async {
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((e) => e.toString().trim().isEmpty)) {
          continue;
        }

        final map = <String, dynamic>{};
        for (int j = 0; j < headers.length && j < row.length; j++) {
          map[headers[j]] = row[j];
        }

        try {
          final name = map['name']?.toString().trim();
          final village = map['village']?.toString().trim();
          if (name == null ||
              name.isEmpty ||
              village == null ||
              village.isEmpty) {
            continue;
          }

          List<String>? imagePaths;
          final imagePathsStr = map['image_paths']?.toString().trim();
          if (imagePathsStr != null && imagePathsStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(imagePathsStr);
              if (decoded is List) {
                imagePaths = decoded.map((e) => e.toString()).toList();
              }
            } catch (_) {}
          }

          List<Map<String, dynamic>>? services;
          final servicesStr = map['services']?.toString().trim();
          if (servicesStr != null && servicesStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(servicesStr);
              if (decoded is List) {
                services = decoded
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
              }
            } catch (_) {}
          }

          Map<String, dynamic>? roadAccess;
          final roadAccessStr = map['road_access']?.toString().trim();
          if (roadAccessStr != null && roadAccessStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(roadAccessStr);
              if (decoded is Map) {
                roadAccess = Map<String, dynamic>.from(decoded);
              }
            } catch (_) {}
          }

          List<Map<String, dynamic>>? landmarkAccesses;
          final landmarkStr = map['landmark_accesses']?.toString().trim();
          if (landmarkStr != null && landmarkStr.isNotEmpty) {
            try {
              final decoded = jsonDecode(landmarkStr);
              if (decoded is List) {
                landmarkAccesses = decoded
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList();
              }
            } catch (_) {}
          }

          final site = Site(
            name: name,
            siteCode: map['site_code']?.toString().trim() ?? '',
            type: SiteTypeX.fromString(map['type']?.toString() ?? 'house'),
            village: village,
            section: map['section']?.toString().trim() ?? '',
            traditionalAuthority:
                map['traditional_authority']?.toString().trim() ?? '',
            ward: map['ward']?.toString().trim() ?? '',
            municipality: map['municipality']?.toString().trim() ?? '',
            district: map['district']?.toString().trim() ?? '',
            province: map['province']?.toString().trim() ?? '',
            householdHead: map['household_head']?.toString().trim(),
            householdSize: int.tryParse(
              map['household_size']?.toString() ?? '',
            ),
            males: int.tryParse(map['males']?.toString() ?? ''),
            females: int.tryParse(map['females']?.toString() ?? ''),
            children: int.tryParse(map['children']?.toString() ?? ''),
            adults: int.tryParse(map['adults']?.toString() ?? ''),
            pensioners: int.tryParse(map['pensioners']?.toString() ?? ''),
            chronicMembers: int.tryParse(
              map['chronic_members']?.toString() ?? '',
            ),
            phoneNumber: map['phone_number']?.toString().trim(),
            address: map['address']?.toString().trim(),
            landmark: map['landmark']?.toString().trim(),
            distanceFromLandmark: double.tryParse(
              map['distance_from_landmark']?.toString() ?? '',
            ),
            directions: map['directions']?.toString().trim() ?? '',
            latitude: double.tryParse(map['latitude']?.toString() ?? ''),
            longitude: double.tryParse(map['longitude']?.toString() ?? ''),
            accuracy: double.tryParse(map['accuracy']?.toString() ?? ''),
            altitude: double.tryParse(map['altitude']?.toString() ?? ''),
            capturedAt: map['captured_at']?.toString() != null
                ? DateTime.tryParse(map['captured_at'].toString())
                : null,
            description: map['description']?.toString().trim(),
            services: services,
            notes: map['notes']?.toString().trim(),
            imagePath: map['image_path']?.toString().trim(),
            imagePaths: imagePaths,
            registeredAt:
                DateTime.tryParse(map['registered_at']?.toString() ?? '') ??
                DateTime.now(),
            isSynced: false,
            incomeBracket: map['income_bracket']?.toString().trim(),
            employedCount: int.tryParse(
              map['employed_count']?.toString() ?? '',
            ),
            unemployedCount: int.tryParse(
              map['unemployed_count']?.toString() ?? '',
            ),
            grantRecipients: int.tryParse(
              map['grant_recipients']?.toString() ?? '',
            ),
            roadAccess: roadAccess,
            landmarkAccesses: landmarkAccesses,
          );

          final siteMap = site.toMap();
          siteMap.remove('id');
          await txn.insert(
            'sites',
            siteMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          imported++;
        } catch (e) {
          // Skip row on error
        }
      }
    });

    return imported;
  }

  // ---------------------------------------------------------------------------
  // EXCEL / CSV EXPORTS
  // ---------------------------------------------------------------------------

  static const List<String> _exportHeaders = [
    'id',
    'site_code',
    'name',
    'type',
    'registered_at',
    'province',
    'district',
    'municipality',
    'ward',
    'traditional_authority',
    'village',
    'section',
    'household_head',
    'household_size',
    'males',
    'females',
    'children',
    'adults',
    'pensioners',
    'chronic_members',
    'phone_number',
    'address',
    'landmark',
    'distance_from_landmark',
    'directions',
    'latitude',
    'longitude',
    'accuracy',
    'altitude',
    'captured_at',
    'description',
    'services',
    'notes',
    'image_path',
    'image_paths',
    'income_bracket',
    'employed_count',
    'unemployed_count',
    'grant_recipients',
    'road_access',
    'landmark_accesses',
  ];

  Future<String> exportSitesToExcel() async {
    final sites = await getAllSites();
    final excel = Excel.createExcel();
    final sheet = excel['Sites'];

    sheet.appendRow(_exportHeaders.map((e) => TextCellValue(e)).toList());

    for (final s in sites) {
      sheet.appendRow([
        TextCellValue(s.id?.toString() ?? ''),
        TextCellValue(s.siteCode),
        TextCellValue(s.name),
        TextCellValue(s.type.name),
        TextCellValue(s.registeredAt.toIso8601String()),
        TextCellValue(s.province),
        TextCellValue(s.district),
        TextCellValue(s.municipality),
        TextCellValue(s.ward),
        TextCellValue(s.traditionalAuthority),
        TextCellValue(s.village),
        TextCellValue(s.section),
        TextCellValue(s.householdHead ?? ''),
        TextCellValue(s.householdSize?.toString() ?? ''),
        TextCellValue(s.males?.toString() ?? ''),
        TextCellValue(s.females?.toString() ?? ''),
        TextCellValue(s.children?.toString() ?? ''),
        TextCellValue(s.adults?.toString() ?? ''),
        TextCellValue(s.pensioners?.toString() ?? ''),
        TextCellValue(s.chronicMembers?.toString() ?? ''),
        TextCellValue(s.phoneNumber ?? ''),
        TextCellValue(s.address ?? ''),
        TextCellValue(s.landmark ?? ''),
        TextCellValue(s.distanceFromLandmark?.toString() ?? ''),
        TextCellValue(s.directions),
        TextCellValue(s.latitude?.toString() ?? ''),
        TextCellValue(s.longitude?.toString() ?? ''),
        TextCellValue(s.accuracy?.toString() ?? ''),
        TextCellValue(s.altitude?.toString() ?? ''),
        TextCellValue(s.capturedAt?.toIso8601String() ?? ''),
        TextCellValue(s.description ?? ''),
        TextCellValue(s.services != null ? jsonEncode(s.services) : ''),
        TextCellValue(s.notes ?? ''),
        TextCellValue(s.imagePath ?? ''),
        TextCellValue(s.imagePaths != null ? jsonEncode(s.imagePaths) : ''),
        TextCellValue(s.incomeBracket ?? ''),
        TextCellValue(s.employedCount?.toString() ?? ''),
        TextCellValue(s.unemployedCount?.toString() ?? ''),
        TextCellValue(s.grantRecipients?.toString() ?? ''),
        TextCellValue(s.roadAccess != null ? jsonEncode(s.roadAccess) : ''),
        TextCellValue(
          s.landmarkAccesses != null ? jsonEncode(s.landmarkAccesses) : '',
        ),
      ]);
    }

    final exportDir = await _ensureDirectory(_exportFolderName);
    final filePath = join(
      exportDir.path,
      'sites_export_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }
    return filePath;
  }

  Future<String> exportSitesToCsv() async {
    final sites = await getAllSites();
    final rows = <List<dynamic>>[_exportHeaders];

    for (final s in sites) {
      rows.add([
        s.id,
        s.siteCode,
        s.name,
        s.type.name,
        s.registeredAt.toIso8601String(),
        s.province,
        s.district,
        s.municipality,
        s.ward,
        s.traditionalAuthority,
        s.village,
        s.section,
        s.householdHead,
        s.householdSize,
        s.males,
        s.females,
        s.children,
        s.adults,
        s.pensioners,
        s.chronicMembers,
        s.phoneNumber,
        s.address,
        s.landmark,
        s.distanceFromLandmark,
        s.directions,
        s.latitude,
        s.longitude,
        s.accuracy,
        s.altitude,
        s.capturedAt?.toIso8601String(),
        s.description,
        s.services != null ? jsonEncode(s.services) : '',
        s.notes,
        s.imagePath,
        s.imagePaths != null ? jsonEncode(s.imagePaths) : '',
        s.incomeBracket,
        s.employedCount,
        s.unemployedCount,
        s.grantRecipients,
        s.roadAccess != null ? jsonEncode(s.roadAccess) : '',
        s.landmarkAccesses != null ? jsonEncode(s.landmarkAccesses) : '',
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final exportDir = await _ensureDirectory(_exportFolderName);
    final filePath = join(
      exportDir.path,
      'sites_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final file = File(filePath);
    await file.writeAsString(csvData);
    return filePath;
  }

  // ---------------------------------------------------------------------------
  // DATABASE BACKUP/EXPORT
  // ---------------------------------------------------------------------------

  Future<String> exportDatabase() async {
    final sourcePath = await _currentDatabasePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Database file not found.');
    }
    final exportDir = await _ensureDirectory(_exportFolderName);
    final targetPath = join(
      exportDir.path,
      'database_export_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<String> backupDatabase() async {
    final sourcePath = await _currentDatabasePath;
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Database file not found.');
    }
    final backupDir = await _ensureDirectory(_backupFolderName);
    final targetPath = join(
      backupDir.path,
      'database_backup_${DateTime.now().millisecondsSinceEpoch}.db',
    );
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<List<String>> getBackupFiles() async {
    final backupDir = await _ensureDirectory(_backupFolderName);
    final files = backupDir
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.db'))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files.map((file) => file.path).toList();
  }

  Future<String?> restoreLatestBackup() async {
    final backupFiles = await getBackupFiles();
    if (backupFiles.isEmpty) return null;
    await close();
    final currentDbPath = await _currentDatabasePath;
    final currentDbFile = File(currentDbPath);
    final latestBackup = File(backupFiles.first);
    if (await currentDbFile.exists()) await currentDbFile.delete();
    await latestBackup.copy(currentDbPath);
    _db = null;
    _dbFuture = null;
    await database;
    return latestBackup.path;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
    _dbFuture = null;
  }
}
