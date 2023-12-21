import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';

import 'Models/TripModel.dart';

class MyDB {
  static Database? _database;
  static final MyDB _singleton = MyDB._internal();

  factory MyDB() {
    return _singleton;
  }

  MyDB._internal();

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  initDB() async {
    return await openDatabase(
      'myDB.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
              CREATE TABLE trip(
                id TEXT PRIMARY KEY,
                start TEXT,
                startLat REAL,
                startLng REAL,
                destination TEXT,
                destinationLat REAL,
                destinationLng REAL,
                price TEXT,
                distance TEXT,
                duration TEXT,
                driverId TEXT,
                status TEXT,
                passengersCount INTEGER,
                date INTEGER,
                rideType TEXT,
                gate INTEGER
              )
            ''');
        await db.execute('''
              CREATE TABLE reservation(
                id TEXT PRIMARY KEY,
                tripId TEXT,
                userId TEXT,
                status TEXT,
                paymentMethod TEXT,
                paymentStatus TEXT
              )
            ''');
      },
    );
  }

  Future<void> addTrip(Trip trip) async {
    final db = await database;
    var t = trip.toJSON();
    t['date'] = t['date'].millisecondsSinceEpoch;
    await db!.insert('trip', t, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Trip>> getTripsByDriverId(String driverId) async {
    final db = await database;
    var res = await db!.query('trip', where: 'driverId = ?', whereArgs: [driverId]);
    List<Map<String, dynamic>> modifiedList = res.map((element) {
      return {
        ...element,
        'date': Timestamp.fromMillisecondsSinceEpoch(element['date'] as int),
      };
    }).toList();

    return modifiedList.map((e) => Trip.fromJSON(e)).toList();
  }

  Future<List<Trip>> getTripsByDriverIdAndStatus(String driverId, String status) async {
    final db = await database;
    var res = await db!.query('trip', where: 'driverId = ? AND status = ?', whereArgs: [driverId, status]);
    for (var element in res) {
      element['date'] = Timestamp.fromMillisecondsSinceEpoch(element['date'] as int);
    }
    return res.map((e) => Trip.fromJSON(e)).toList();
  }

  void updateTrip(Trip trip) async {
    final db = await database;
    var t = trip.toJSON();
    t['date'] = t['date'].millisecondsSinceEpoch;
    await db?.update('trip', t, where: 'id = ?', whereArgs: [trip.id], conflictAlgorithm: ConflictAlgorithm.replace);
  }


}
