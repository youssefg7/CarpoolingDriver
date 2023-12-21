import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/ReservationModel.dart';

class ReservationRepository{
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  ReservationRepository._();
  static final ReservationRepository _instance = ReservationRepository._();

  factory ReservationRepository(){
    return _instance;
  }

  Future<void> updateReservation(Reservation reservation) async{
    await _firestore.collection('reservations').doc(reservation.id).update(reservation.toJSON());
  }

  Future<List<Reservation>> getReservationsByTripIdAndPaymentStatusAndNotStatus(String tripId, String paymentStatus, String status) async{
    return await _firestore.collection('reservations')
        .where('tripId', isEqualTo: tripId)
        .where('paymentStatus', isEqualTo: paymentStatus)
        .where('status', isNotEqualTo: status)
        .get()
        .then((value) => value.docs.map((e) => Reservation.fromJSON(e.data())).toList());
  }

}