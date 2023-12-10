import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {


  final List<String> statusTypes = ["UPCOMING", "COMPLETED", "CANCELLED"];
  List<String> selectedStatusTypes = [];

  Future<List<Map<String, dynamic>>> getRidesHistory() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      CollectionReference tripsCollection = FirebaseFirestore.instance.collection('trips');

      QuerySnapshot querySnapshot = await tripsCollection.where('driverId', isEqualTo: userId).get();

      if (querySnapshot.size > 0) {
        List<Map<String, dynamic>> filteredTrips = [];

        for (QueryDocumentSnapshot doc in querySnapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          filteredTrips.add(data);
        }

        print(filteredTrips);
        return filteredTrips;
      } else {
        print("No Trips for the current user");
      }
    } catch (e) {
      print('Error fetching rides history: $e');
      // Handle the error, show a message, or perform any necessary action.
    }

    // Return an empty list in case of an error or no trips found
    return [];
  }

  Future<List<Map<String, dynamic>>> getTripsData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: userId)
        .get();

    List<Map<String, dynamic>> trips = [];
    for (QueryDocumentSnapshot doc in querySnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      trips.add(data);
    }
    return trips;
  }

  List<Map<String, dynamic>> filterTripsByStatus(
      List<Map<String, dynamic>> trips, List<String> selectedStatusTypes) {
    if (selectedStatusTypes.isEmpty) {
      return trips;
    } else {
      return trips
          .where((trip) =>
          selectedStatusTypes.contains(trip['status'].toString()))
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
    return Card(
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
                      snapshot['date']
                          .toString()
                          .substring(0, 10),
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
                Text(
                  "From: ${snapshot['start']}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_pin),
                const SizedBox(width: 10),
                Text(
                  "To: ${snapshot['destination']}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.question_mark),
                const SizedBox(width: 10),
                Text(
                  "Trip Status: ${snapshot['status'].toString().toUpperCase()}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.route),
                Text(
                  snapshot['distance'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.drive_eta),
                Text(
                  snapshot['duration'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.attach_money),
                Text(
                  snapshot['price'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.person),
                Text(
                  snapshot['passengersCount'].toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showAlertDialog(context, snapshot);
                    setState(() {});
                  },
                  icon: const Icon(Icons.delete_outlined),
                  label: const Text("Cancel Trip"),
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
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Trips History"),
      ),
      body:
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: statusTypes.map(
                  (statusType)=> FilterChip(
                    selected: selectedStatusTypes.contains(statusType),
                      label: Text(statusType),
                      onSelected: (selected){
                        setState((){
                      if (selected) {
                        selectedStatusTypes.add(statusType);
                      } else {
                        selectedStatusTypes
                            .removeWhere((String name) => name == statusType);
                      }
                    });
                  })
              ).toList(),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: getTripsData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "No Trips Yet",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else {
                    var filteredTrips =
                    filterTripsByStatus(snapshot.data!, selectedStatusTypes);
                    return buildTripsList(filteredTrips);
                  }
                },
              ),
            ),]
        ),
    );
  }
}

showAlertDialog(BuildContext context, snapshot) {
  // set up the buttons
  Widget cancelButton = TextButton(
    child: const Text("Don't Cancel"),
    onPressed:  () {
      Navigator.of(context).pop();
    },
  );
  Widget continueButton = TextButton(
    child: const Text("Confirm Cancellation"),
    onPressed:  () {
      Navigator.of(context).pop();
      FirebaseFirestore.instance.collection("trips").doc(snapshot['id']).delete();
    },
  );
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: const Text("Cancel Trip"),
    content: const Text("Are you sure you want to cancel this trip?"),
    actions: [
      cancelButton,
      continueButton,
    ],
  );
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
