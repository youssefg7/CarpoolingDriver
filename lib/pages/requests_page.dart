import 'dart:async';
import 'package:carpool_driver_flutter/Utilities/utils.dart';
import 'package:carpool_driver_flutter/data/Models/ReservationModel.dart';
import 'package:carpool_driver_flutter/data/Models/TripModel.dart';
import 'package:carpool_driver_flutter/data/Repositories/ReservationRepository.dart';
import 'package:carpool_driver_flutter/data/Repositories/TripRepository.dart';
import 'package:carpool_driver_flutter/data/Repositories/UserRepository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../data/Models/UserModel.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<String> selectedStatusTypes = [];
  ReservationRepository reservationRepository = ReservationRepository();
  TripRepository tripRepository = TripRepository();
  UserRepository userRepository = UserRepository();

  void showAcceptDialog(BuildContext context, snapshot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Trip Request'),
          content: const Text('Are you sure you want to accept this request?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async{
                if(!(await Utils.checkInternetConnection(context))) {return;}
                Navigator.of(context).pop();
                Reservation reservation = snapshot['reservation'];
                reservation.status = 'accepted';
                reservationRepository.updateReservation(reservation).then((value) {
                    Trip trip = snapshot['trip'];
                trip.passengersCount = trip.passengersCount + 1;
                tripRepository.updateTrip(trip)
                    .then((value) {
                  Utils.displayToast("Request Accepted!", context,
                      toastLength: Toast.LENGTH_LONG);
                  setState(() {

                  });
                })
                    .catchError(
                        (error) => Utils.displaySnack("Couldn't Accept Request, Try Again.", context));
                }
                ).catchError(
                        (error) => Utils.displaySnack("Couldn't Accept Request, Try Again.", context));

              },
              child: const Text('Accept Request'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
  void showDeclineDialog(BuildContext context, snapshot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decline Trip Request'),
          content: const Text('Are you sure you want to decline this request?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                if(!(await Utils.checkInternetConnection(context))) {return;}
                // Close the dialog
                Navigator.of(context).pop();
                Reservation reservation = snapshot['reservation'];
                reservation.status = 'declined';
                reservationRepository.updateReservation(reservation)
                    .then((value) => Utils.displayToast("Request Declined!", context, toastLength: Toast.LENGTH_LONG))
                    .catchError(
                        (error) => Utils.displaySnack("Couldn't Decline Request, Try Again.", context));
              },
              child: const Text('Decline Request'),
            ),
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> getTripsData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    List<Trip> myTrips = await tripRepository.getTripsByDriverIdAndStatus(userId!, 'upcoming');

    List<Map<String, dynamic>> requests = [];
    for(Trip trip in myTrips){
      List<Reservation> reservations = await reservationRepository.getReservationsByTripIdAndPaymentStatusAndNotStatus(trip.id, 'paid', 'declined');
      if(trip.date.isBefore(DateTime.now())){
        for(Reservation reservation in reservations){
          reservation.status = 'expired';
          reservationRepository.updateReservation(reservation);
        }
        continue;
      }
      for(Reservation reservation in reservations){
        Student rider = (await userRepository.getUser(reservation.userId))!;
        requests.add({
          'trip': trip,
          'reservation': reservation,
          'rider': rider,
        });
      }
    }
    return requests;
  }

  List<Map<String, dynamic>> filterTripsByStatus(List<Map<String, dynamic>> trips, List<String> selectedStatusTypes) {
    if (selectedStatusTypes.isEmpty) {
      return trips;
    } else {
      return trips
          .where((trip) => selectedStatusTypes.contains(trip['status'].toString()))
          .toList();
    }
  }

  Widget buildTripsList(List<Map<String, dynamic>> trips) {
    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        var tripData = trips[index];
        return buildTripCard(tripData, context);
      },
    );
  }

  Widget buildTripCard(Map<String, dynamic> snapshot, BuildContext context) {
    Trip trip = snapshot['trip'];
    Reservation reservation = snapshot['reservation'];
    Student rider = snapshot['rider'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Card(
        elevation: 10,
        shadowColor: Colors.black,
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.date_range_sharp),
                      const SizedBox(width: 10),
                      Text(
                        Utils.formatDate(trip.date),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.watch_later_outlined),
                      const SizedBox(width: 10),
                      Text(
                        trip.rideType == 'toASU'
                            ? '07:30 AM'
                            : '05:30 PM',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_pin),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "From: ${trip.start}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_pin),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "To: ${trip.destination}",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 3),
                  const Icon(Icons.person),
                  IconButton(
                      onPressed: () async{
                        await Utils.makePhoneCall(rider.phone);
                      },
                      icon: const Icon(
                        Icons.phone,
                        color: Colors.green,
                      )),
                  const SizedBox(width: 5),
                  Text(
                    rider.email.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    "-",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      rider.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              reservation.status=='accepted'?
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  Icon(Icons.check_circle, color: Colors.green,),
                  SizedBox(width: 10),
                  Text(
                    "Accepted",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ]
              )
                  :reservation.status=='declined'?
              const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:[
                    Icon(Icons.cancel, color: Colors.red,),
                    SizedBox(width: 10),
                    Text(
                      "Declined",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ]
              )
                  :Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showAcceptDialog(context, snapshot);
                      setState(() {});
                    },
                    icon: const Icon(Icons.check),
                    label: const Text(
                      "Accept",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.green),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDeclineDialog(context, snapshot);
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                    label: const Text(
                      "Decline",
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.red),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Trips Requests"),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(children: [
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: getTripsData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No Available Requests for Upcoming Trips",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              } else {
                // var filteredTrips = filterTripsByStatus(snapshot.data!, selectedStatusTypes);
                return buildTripsList(snapshot.data!);
              }
            },
          ),
        ),
      ]),
    );
  }
}
