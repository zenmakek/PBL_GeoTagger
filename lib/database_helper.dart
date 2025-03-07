import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocationEntry {
  final int? id;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  LocationEntry({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationEntry.fromMap(Map<String, dynamic> map) {
    return LocationEntry(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('locations.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE locations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        address TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertLocation(LocationEntry location) async {
    final db = await database;
    return await db.insert('locations', location.toMap());
  }

  Future<List<LocationEntry>> getAllLocations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('locations');
    return List.generate(maps.length, (i) => LocationEntry.fromMap(maps[i]));
  }
}
