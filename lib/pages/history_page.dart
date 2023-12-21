import 'dart:async';
import 'package:carpool_driver_flutter/Utilities/utils.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/Models/TripModel.dart';
import '../data/Repositories/TripRepository.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {

  TripRepository tripRepository = TripRepository();

  final List<String> statusTypes = ["UPCOMING", "COMPLETED", "CANCELLED"];
  List<String> selectedStatusTypes = [];

  showAlertDialog(Trip trip) {
    Widget cancelButton = TextButton(
      child: const Text("Don't Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Confirm Trip Cancellation"),
      onPressed: () async{
        if(!(await Utils.checkInternetConnection(context))) {return;}
        Navigator.of(context).pop();
        trip.status = 'cancelled';
        tripRepository.updateTrip(trip).then((value) {
          setState(() {
          });
        }).catchError((error) {
          Utils.displaySnack("Couldn't Cancel Trip, Try Again", context);
        });
      }
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Cancel Trip"),
      content:
      const Text("Are you sure you want to cancel this trip?"),
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

  Future<List<Trip>> getTripsData() async {
    var userId = FirebaseAuth.instance.currentUser?.uid;
    List<Trip> trips = await tripRepository.getTripsByDriverId(userId!);
    for (Trip trip in trips) {
      if(trip.date.isBefore(DateTime.now())){
        trip.status = 'completed';
        tripRepository.updateTrip(trip);
      }
    }
    return trips;
  }

  List<Trip> filterTripsByStatus(List<Trip> trips, List<String> selectedStatusTypes) {
    if (selectedStatusTypes.isEmpty) {
      return trips;
    } else {
      return trips.where((trip) => selectedStatusTypes.contains(trip.status.toUpperCase())).toList();
    }
  }

  Widget buildTripsList(List<Trip> trips) {
    return ListView.builder(
      itemCount: trips.length,
      itemBuilder: (context, index) {
        Trip trip = trips[index];
        return buildTripCard(trip, context);
      },
    );
  }

  Widget buildTripCard(Trip trip, BuildContext context) {
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
              const SizedBox(height: 5),
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
                children: [
                  trip.status == 'completed' ?
                  const Icon(Icons.check_circle, color: Colors.green,)
                      :trip.status == 'cancelled'?
                  const Icon(Icons.cancel, color: Colors.red,)
                      : const Icon(Icons.pending, color: Colors.blueAccent,),
                  const SizedBox(width: 10),
                  const Text(
                    "Trip Status: ",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    trip.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: trip.status == 'completed' ? Colors.green :trip.status == 'cancelled'? Colors.red: Colors.blueAccent,
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
                    trip.distance,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.drive_eta),
                  Text(
                    trip.duration,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.attach_money),
                  Text(
                    trip.price,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.person),
                  Text(
                    trip.passengersCount.toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trip.status == 'upcoming' ?
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {

                      showAlertDialog(trip);
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
              ):
              const SizedBox(),
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
              child: FutureBuilder<List<Trip>>(
                future: getTripsData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print("Error: ${snapshot.error}, snapshot.hasError");
                    return Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
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
                    var filteredTrips = filterTripsByStatus(snapshot.data!, selectedStatusTypes);
                    return buildTripsList(filteredTrips);
                  }
                },
              ),
            ),]
        ),
    );
  }
}

