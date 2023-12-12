import 'dart:async';
import 'package:carpool_driver_flutter/Utilities/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<String> selectedStatusTypes = [];


  void showAcceptDialog(BuildContext context, snapshot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Accept Trip Request'),
          content: const Text('Are you sure you want to accept this request?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();

                FirebaseFirestore.instance
                    .collection('trips')
                    .doc(snapshot['tripId'])
                    .update({
                  'passengersCount': int.parse(snapshot['tripPassengersCount']) + 1,
                });
                FirebaseFirestore.instance
                    .collection('reservations')
                    .doc(snapshot['uid'])
                    .update({
                  'status': 'accepted',
                })
                    .then((value) => Utils.displayToast("Request Accepted!", context, toastLength: Toast.LENGTH_LONG))
                    .catchError(
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
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                FirebaseFirestore.instance
                    .collection('reservations')
                    .doc(snapshot['uid'])
                    .update({
                  'status': 'declined',
                })
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
    List<Map<String, dynamic>> requests = [];
    QuerySnapshot myTrips = await FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: userId)
        .where('status', isEqualTo: 'upcoming')
        .get();
    List<String> myTripsIds =
        myTrips.docs.map((e) => e['uid'].toString()).toList();
    QuerySnapshot requestsDocs = await FirebaseFirestore.instance
        .collection('reservations')
        .where('tripId', whereIn: myTripsIds)
        .where('paymentStatus', isEqualTo: 'paid')
        .where('status', isNotEqualTo: 'declined')
        .get();
    for (QueryDocumentSnapshot request in requestsDocs.docs) {
      DocumentSnapshot<Map<String, dynamic>> rider = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(request['userId'])
          .get();

      DocumentSnapshot<Map<String, dynamic>> trip = await FirebaseFirestore
          .instance
          .collection('trips')
          .doc(request['tripId'])
          .get();

      Map<String, dynamic> data = request.data() as Map<String, dynamic>;
      data['riderName'] = rider['username'];
      data['riderPhone'] = rider['phone'];
      data['riderId'] = rider['id'];
      data['riderEmail'] = rider['email'];
      data['date'] = trip['date'];
      data['start'] = trip['start'];
      data['destination'] = trip['destination'];
      data['price'] = trip['price'];
      data['tripId'] = trip['uid'];
      data['tripPassengersCount'] = trip['passengersCount'];
      requests.add(data);
    }

    return requests;
  }

  List<Map<String, dynamic>> filterTripsByStatus(
      List<Map<String, dynamic>> trips, List<String> selectedStatusTypes) {
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
                        snapshot['date'].toString().substring(0, 10),
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
                        snapshot['rideType'] == 'toASU'
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
                      "From: ${snapshot['start']}",
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
                      "To: ${snapshot['destination']}",
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
                        await Utils.makePhoneCall(snapshot['riderPhone']);
                      },
                      icon: const Icon(
                        Icons.phone,
                        color: Colors.green,
                      )),
                  const SizedBox(width: 5),
                  Text(
                    snapshot['riderEmail'].toString().toUpperCase(),
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
                      snapshot['riderName'].toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              snapshot['status']=='accepted'?
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
                  :snapshot['status']=='declined'?
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
