import 'package:carpool_driver_flutter/data/Models/TripModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../myDatabase.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MyDB _database = MyDB();
  TripRepository._();
  static final TripRepository _instance = TripRepository._();

  factory TripRepository(){
    return _instance;
  }

  Future<void> addTrip(Trip trip) async {
    DocumentReference documentReference = await _firestore.collection('trips').add(trip.toJSON());
    trip.id = documentReference.id;
    await _firestore.collection('trips').doc(documentReference.id).update(trip.toJSON())
        .then((value) {
      _database.addTrip(trip);
    });
  }

  Future<void> updateTrip(Trip trip) async {
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return;
    }
    await _firestore.collection('trips').doc(trip.id).update(trip.toJSON())
        .then((value) {
      _database.updateTrip(trip);
    });
  }

  Future<List<Trip>> getTripsByDriverId(String driverId) async {
    List<Trip> trips = [];
    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getTripsByDriverId(driverId);
    }
    await _firestore.collection('trips').where(
        'driverId', isEqualTo: driverId)
        .get()
        .then((value) {
      for (var element in value.docs) {
        trips.add(Trip.fromJSON(element.data()));
        _database.addTrip(Trip.fromJSON(element.data()));
      }
    }
    );
    return trips;
  }

  Future<List<Trip>> getTripsByDriverIdAndStatus(String driverId, String status) async {

    var connection = await Connectivity().checkConnectivity();
    if(!(connection == ConnectivityResult.mobile || connection == ConnectivityResult.wifi)){
      return await _database.getTripsByDriverIdAndStatus(driverId, status);
    }

    List<Trip> trips = [];
    var result = await _firestore.collection('trips').where(
        'driverId', isEqualTo: driverId).where('status', isEqualTo: status).get();
    for (var element in result.docs) {
      trips.add(Trip.fromJSON(element.data()));
      _database.addTrip(Trip.fromJSON(element.data()));
    }
    return trips;
  }


  Future<bool> checkIfTripExists(DateTime date, String rideType) async {
    var result = await _firestore.collection('trips')
        .where('driverId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .where('date', isEqualTo: Timestamp.fromDate(date))
        .where('rideType', isEqualTo: rideType)
        .get();
    return result.docs.isNotEmpty;
  }



}