import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Task {
  int? id;
  String name;
  DateTime dueDate;
  bool isCompleted;
  List<DateTime> completionDates;
  List<int> daysOfWeek; // New field

  Task({
    this.id,
    required this.name,
    required this.dueDate,
    required this.isCompleted,
    this.completionDates = const [],
    this.daysOfWeek = const [], // Initialize with an empty list
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted ? 1 : 0,
      'completionDates': jsonEncode(
          completionDates.map((date) => date.toIso8601String()).toList()),
      'daysOfWeek': jsonEncode(daysOfWeek), // Convert daysOfWeek to JSON
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      name: map['name'],
      dueDate: DateTime.parse(map['dueDate']),
      isCompleted: map['isCompleted'] == 1,
      completionDates: (jsonDecode(map['completionDates']) as List<dynamic>)
          .map((dateStr) => DateTime.parse(dateStr))
          .toList(),
      daysOfWeek: (jsonDecode(map['daysOfWeek']) as List<dynamic>)
          .map((day) => day as int)
          .toList(),
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'tasks.db');

    return openDatabase(
      path,
      version: 2, // Increment the version number
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          dueDate TEXT,
          isCompleted INTEGER,
          completionDates TEXT,
          daysOfWeek TEXT
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add the new column if it doesn't exist
          await db.execute('''
          ALTER TABLE tasks ADD COLUMN daysOfWeek TEXT DEFAULT '[]'
        ''');
        }
      },
    );
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return Task.fromMap(maps[i]);
    });
  }

Future<void> updateTask(Task task) async {
  final db = await database;
  await db.update(
    'tasks',
    task.toMap(),
    where: 'id = ?',
    whereArgs: [task.id],
  );
}


  Future<void> deleteTask(int id) async {
    final db = await database;
    await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
