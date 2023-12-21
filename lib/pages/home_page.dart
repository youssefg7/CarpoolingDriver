import 'dart:async';
import 'dart:convert';

import 'package:carpool_driver_flutter/data/Models/TripModel.dart';
import 'package:carpool_driver_flutter/data/Repositories/TripRepository.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Utilities/global_var.dart';
import '../Utilities/location_serives.dart';
import '../Utilities/utils.dart';
import '../authentication/login_screen.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../data/Models/UserModel.dart';
import '../data/Repositories/ReservationRepository.dart';
import '../data/Repositories/UserRepository.dart';
import '../widgets/loading_dialog.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserRepository userRepository = UserRepository();
  Student user = Student(
    id: '',
    username: '',
    email: '',
    phone: '',
    isDriver: false,
  );
  ReservationRepository reservationRepository = ReservationRepository();
  TripRepository tripRepository = TripRepository();
  final Completer<GoogleMapController> googleMapControllerCompleter =
      Completer<GoogleMapController>();
  late GoogleMapController googleMapController;
  Position? currentUserPosition;
  LatLng? currentUserLatLng;
  Set<Marker> markers = {};
  Marker? origin;
  Marker? destination;
  PolylinePoints polylinePoints = PolylinePoints();
  List<Polyline> polylines = [];
  List<LatLng> routeCoords = [];
  GlobalKey<ScaffoldState> sandwichKey = GlobalKey<ScaffoldState>();
  GlobalKey<ScaffoldState> cartKey = GlobalKey<ScaffoldState>();
  bool serviceEnabled = false;
  Map<String, dynamic>? routeData;
  int price = 0;
  String duration = "0 mins";
  String distance = "0 kms";
  Prediction? currentPrediction;
  late LatLng pickupLatLng;
  late LatLng dropoffLatLng;

  PanelController panelController = PanelController();
  TextEditingController pickupTextEditingController = TextEditingController();
  TextEditingController dropoffTextEditingController = TextEditingController();
  String rideType = "toASU";
  FocusNode pickupFocus = FocusNode();
  FocusNode dropoffFocus = FocusNode();
  bool floatingButtonVisibility = true;
  bool searchDone = false;
  int gate = 2;
  List<bool> selectedGate = [true, false, false];

  List<Widget> stopsWidgets = [];
  List<TextEditingController> stopsControllers = [];

  addStop(){
    setState(() {
      stopsControllers.add(TextEditingController());
    });
  }

  @override
  void dispose() {
    googleMapController.dispose();
    super.dispose();
  }

  updateMapStyle(GoogleMapController googleMapController, String mapStyleName) async {
    ByteData byteData =
        await rootBundle.load('lib/map_styles/${mapStyleName}_style.json');
    var list = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    var decodedList = utf8.decode(list);
    googleMapController.setMapStyle(decodedList);
  }

  getCurrentLocation() async {
    currentUserPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentUserLatLng =
        LatLng(currentUserPosition!.latitude, currentUserPosition!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: currentUserLatLng!, zoom: 14.4746);
    googleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  getUserInfo() async {
    user = await userRepository.getCurrentUser();
    setState(() {
      user = user;
    });
  }

  addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 4,
    );
    setState(() {
      polylines.add(polyline);
    });
  }

  void toggleRideType() {
    String tempPickup = pickupTextEditingController.text;
    String tempDropoff = dropoffTextEditingController.text;

    if (rideType == "fromASU") {
      pickupTextEditingController.text = tempDropoff;
      dropoffTextEditingController.text = "Faculty of Engineering, ASU";
    } else {
      pickupTextEditingController.text = "Faculty of Engineering, ASU";
      dropoffTextEditingController.text = tempPickup;
    }
    setState(() {
      if(origin != null && destination != null) {
        Marker tempOrigin = origin!;
        origin = destination;
        destination = tempOrigin;
      }
      if (markers.isNotEmpty) {
        markers.clear();
        markers.add(origin!);
        markers.add(destination!);
      }
      rideType = rideType == "toASU" ? "fromASU" : "toASU";
    });
    if(pickupTextEditingController.text.isNotEmpty && dropoffTextEditingController.text.isNotEmpty && currentPrediction != null) {
      searchWithPrediction(currentPrediction!);
    }
    adjustInitialDate();
  }

  void clearMap() {
    setState(() {
      markers.clear();
      polylines.clear();
    });
  }

  Future<void> searchWithPrediction(Prediction prediction) async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (rideType == "fromASU") {
      pickupLatLng = defaultLocation;
      dropoffLatLng =
          LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
      dropoffTextEditingController.text = prediction.name!;
    } else {
      pickupLatLng =
          LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
      dropoffLatLng = defaultLocation;
      pickupTextEditingController.text = prediction.name!;
    }
    clearMap();
    LocationServices.getDirections(pickupLatLng, dropoffLatLng)
        .then((value) async {
      addPolyLine(value["points"]);
      await googleMapController
          .animateCamera(CameraUpdate.newLatLngBounds(value['bounds'], 30));
      setState(() {
        routeData = value;
        origin = Marker(
          markerId: const MarkerId("origin"),
          infoWindow: const InfoWindow(title: "Trip Start"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          position: pickupLatLng,
        );
        destination = Marker(
          markerId: const MarkerId("destination"),
          infoWindow: const InfoWindow(title: "Trip End"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          position: dropoffLatLng,
        );
        markers.add(origin!);
        markers.add(destination!);
      });
      setState(() {
        searchDone = true;
      });
      // panelController.close();
    });
  }

  DateTime tripDate = DateTime.now();

  void adjustInitialDate(){
    if(rideType == "toASU"){
      if(DateTime.now().isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 22, 00))){
        tripDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 2);
      }else{
        tripDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1);
      }
    }else{
      if(DateTime.now().isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 13, 00))){
        tripDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1);
      }else{
        tripDate = DateTime.now();
      }
    }
    setState(() {
      tripDate = tripDate;
    });
  }

  void callDatePicker() async {
    DateTime? date = await getDate();
    setState(() {
      tripDate = date!;
    });
  }

  Future<DateTime?> getDate() {
    DateTime now = DateTime.now();
    DateTime initialDay;
    if (rideType == "toASU") {
      if (DateTime.now().isAfter(DateTime(DateTime.now().year,
          DateTime.now().month, DateTime.now().day, 23, 30))) {
        initialDay = DateTime(now.year, now.month, now.day + 2);
      } else {
        initialDay = DateTime(now.year, now.month, now.day + 1);
      }
    } else {
      if (DateTime.now().isAfter(DateTime(DateTime.now().year,
          DateTime.now().month, DateTime.now().day, 16, 30))) {
        initialDay = DateTime(now.year, now.month, now.day + 1);
      } else {
        initialDay = now;
      }
    }
    return showDatePicker(
      context: context,
      initialDate: initialDay,
      firstDate: initialDay,
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark(),
          child: child!,
        );
      },
    );
  }

  Future<void> addTrip() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(
        messageText: "Adding, Please wait...",
      ),
    );

    if(await tripRepository.checkIfTripExists(tripDate, rideType)){
      Navigator.pop(context);
      Utils.displaySnack("Couldn't add trip, Another trip in the same date and time already exits.", context);
      return;
    }

    Trip newTrip = Trip(id: "",
        driverId: FirebaseAuth.instance.currentUser!.uid,
        rideType: rideType,
        start: rideType == "fromASU" ? "Faculty of Engineering, ASU" : pickupTextEditingController.text,
        destination: rideType == "toASU" ? "Faculty of Engineering, ASU" : dropoffTextEditingController.text,
        date: tripDate,
        status: "upcoming",
        destinationLat: dropoffLatLng.latitude,
        destinationLng: dropoffLatLng.longitude,
        startLat: pickupLatLng.latitude,
        startLng: pickupLatLng.longitude,
        gate: gate,
        price: routeData!["priceText"],
        distance: routeData!["distanceText"],
        duration: routeData!["timeText"],
        passengersCount: 0);

    tripRepository.addTrip(newTrip).then((value){
      Navigator.pop(context);
      Utils.displayToast("Trip Added Successfully", context);
      if(rideType == "fromASU"){
        dropoffTextEditingController.clear();
      }
      if(rideType == "toASU"){
        pickupTextEditingController.clear();
      }
      clearMap();
      getCurrentLocation();
      panelController.close();
    }).catchError((error){
      Navigator.pop(context);
      Utils.displaySnack("Trip not added, try again.", context);
    });
  }



  @override
  void initState() {
    getUserInfo();
    super.initState();
    dropoffTextEditingController.text = "Faculty of Engineering, ASU";
    dropoffTextEditingController.addListener(() {
      if(dropoffTextEditingController.text.isEmpty){
        clearMap();
        getCurrentLocation();
        currentPrediction = null;
      }
    });
    pickupTextEditingController.addListener(() {
      if(pickupTextEditingController.text.isEmpty){
        clearMap();
        getCurrentLocation();
        currentPrediction = null;
      }
    });
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: Visibility(
          visible: floatingButtonVisibility,
          child: FloatingActionButton.extended(
            enableFeedback: false,
            backgroundColor: Colors.black,
            icon: const Icon(
              Icons.add,
              color: Colors.white,
            ),
            label: const Text(
              "Add New Trip",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onPressed: () async{
              if(!(await Utils.checkInternetConnection(context))){
                return;
              }

              if (pickupTextEditingController.text.isEmpty ||
                  dropoffTextEditingController.text.isEmpty ||
              currentPrediction == null
              ) {
                Utils.displayToast(
                    "Enter Trip Start and End Location", context);
              } else {
                adjustInitialDate();
                panelController.open();
              }
            },
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            "ASUFE CARPOOL DRIVER",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        key: sandwichKey,
        drawer: Container(
          width: 255,
          color: Colors.black87,
          child: Drawer(
            backgroundColor: Colors.white10,
            child: ListView(padding: EdgeInsets.zero, children: [
              const SizedBox(
                height: 50,
              ),
              ListTile(
                onTap: () {
                  Navigator.pushNamed(context, '/profile',
                      arguments: {"user": user});
                },
                leading: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 40,
                ),
                title: Text(
                  user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                onTap: (){
                  Navigator.pushNamed(context, '/history');
                },
                leading: const Icon(
                  Icons.receipt_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                title: const Text(
                  "Trips History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                onTap: () async {
                  if(!(await Utils.checkInternetConnection(context))){
                    return;
                  }
                  Navigator.pushNamed(context, '/requests');
                },
                leading: const Icon(
                  Icons.question_mark,
                  color: Colors.white,
                  size: 34,
                ),
                title: const Text(
                  "Ride Requests",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ListTile(
                onTap: (){
                  Navigator.pushNamed(context, '/wallet');
                },
                leading: const Icon(
                  Icons.monetization_on_outlined,
                  color: Colors.white,
                  size: 34,
                ),
                title: const Text(
                  "Wallet",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Divider(
                height: 1,
                color: Colors.white,
                thickness: 1,
              ),
              const SizedBox(
                height: 10,
              ),
              ListTile(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  userRepository.deleteCurrentUser();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()));
                },
                leading: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.grey,
                  ),
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                ),
              ),
            ]),
          ),
        ),
        body: SlidingUpPanel(
          color: Colors.black,
          backdropEnabled: true,
          backdropOpacity: 0.4,
          backdropTapClosesPanel: true,
          minHeight: 0,
          maxHeight: 0.72 * MediaQuery.of(context).size.height,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          controller: panelController,
          onPanelClosed: () {
            setState(() {
              floatingButtonVisibility = true;
            });
          },
          onPanelOpened: () {
            setState(() {
              floatingButtonVisibility = false;
            });
          },
          body: GestureDetector(
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Stack(
              children: [
                GoogleMap(
                  padding: const EdgeInsets.only(bottom: 122),
                  myLocationEnabled: true,
                  initialCameraPosition: googlePlexInitialPosition,
                  markers: markers,
                  onMapCreated: (GoogleMapController controller) {
                    setState(() {
                      googleMapController = controller;
                    });
                    googleMapControllerCompleter.complete(controller);
                  },
                  polylines: Set.from(polylines),
                ),
                Positioned(
                  // bottom: 0,
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: 122,
                    color: Colors.black,
                    child: Column(children: [
                      const SizedBox(
                        height: 3,
                      ),
                      AbsorbPointer(
                        absorbing: rideType == "fromASU" ? true : false,
                        child: Opacity(
                          opacity: rideType == "fromASU" ? 0.5 : 1,
                          child: GooglePlaceAutoCompleteTextField(
                            onCrossBtnPressed: () {
                              pickupTextEditingController.clear();
                              setState(() {
                                markers.clear();
                                polylines.clear();
                              });
                              getCurrentLocation();
                            },
                            focusNode: pickupFocus,
                            textEditingController: pickupTextEditingController,
                            googleAPIKey: googleMapApiKeyAndroid,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            inputDecoration: InputDecoration(
                              labelText: rideType == "fromASU"
                                  ? "Faculty of Engineering, Ain Shams University"
                                  : "Search Trip Start Location",
                              labelStyle: const TextStyle(
                                  fontSize: 20, color: Colors.white),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(22, 12, 0, 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: const BorderSide(
                                  width: 2,
                                  color: Colors.purple,
                                ),
                              ),
                              suffixIcon: const Icon(Icons.location_pin),
                            ),
                            boxDecoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            debounceTime: 800,
                            countries: const ["eg"],
                            getPlaceDetailWithLatLng: (Prediction prediction) {
                              print("getPlaceDetailWithLatLng");
                              setState(() {
                                currentPrediction = prediction;
                              });
                              searchWithPrediction(prediction);
                            },
                            itemClick: (Prediction prediction) {
                              print("itemClick");
                              pickupTextEditingController.text =
                                  prediction.structuredFormatting!.mainText!;
                              pickupTextEditingController.selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: prediction.structuredFormatting!.mainText!.length));
                              setState(() {

                              });
                            },
                            // if we want to make custom list background
                            // listBackgroundColor: Colors.black,
                            itemBuilder: (context, index, Prediction prediction) {
                              return Card(
                                color: Colors.white24,
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on),
                                      const SizedBox(
                                        width: 7,
                                      ),
                                      Expanded(
                                        child: Text(
                                                prediction.description ?? "",
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            seperatedBuilder: const Divider(
                              height: 1,
                            ),
                            isCrossBtnShown: rideType == "fromASU" ? false : true,
                          ),
                        ),
                      ),
                      AbsorbPointer(
                        absorbing: rideType == "toASU" ? true : false,
                        child: Opacity(
                          opacity: rideType == "toASU" ? 0.5 : 1,
                          child: GooglePlaceAutoCompleteTextField(
                            onCrossBtnPressed: () {
                              dropoffTextEditingController.clear();
                              clearMap();
                            },
                            focusNode: dropoffFocus,
                            textEditingController: dropoffTextEditingController,
                            googleAPIKey: googleMapApiKeyAndroid,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            inputDecoration: InputDecoration(
                              labelText: rideType == "toASU"
                                  ? "Faculty of Engineering, Ain Shams University"
                                  : "Search Trip Destination Location",
                              labelStyle: const TextStyle(
                                  fontSize: 20, color: Colors.white),
                              contentPadding:
                                  const EdgeInsets.fromLTRB(22, 12, 0, 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(40),
                                borderSide: const BorderSide(
                                  width: 2,
                                  color: Colors.purple,
                                ),
                              ),
                              suffixIcon: const Icon(Icons.location_pin),
                            ),
                            boxDecoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            debounceTime: 800,
                            countries: const ["eg"],
                            getPlaceDetailWithLatLng: (Prediction prediction) {
                              setState(() {
                                currentPrediction = prediction;
                              });
                              searchWithPrediction(prediction);
                            }, // this callback is called when isLatLngRequired is true
                            itemClick: (Prediction prediction) {
                              dropoffTextEditingController.text =
                              prediction.structuredFormatting!.mainText!;
                              dropoffTextEditingController.selection =
                                  TextSelection.fromPosition(TextPosition(
                                      offset: prediction.structuredFormatting!.mainText!.length));
                            },
                            itemBuilder: (context, index, Prediction prediction) {
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 24, 12, 24),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on),
                                    const SizedBox(
                                      width: 7,
                                    ),
                                    Expanded(
                                      child: Text(prediction.description ?? "",
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            seperatedBuilder: const Divider(
                              height: 1,
                            ),
                            isCrossBtnShown: rideType == "toASU" ? false : true,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Positioned(
                  top: 44,
                  right: 7,
                  child: GestureDetector(
                    onTap: toggleRideType,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: Transform.rotate(
                        angle: -1.5708,
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Colors.black,
                          size: 35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          panel: (searchDone)
              ? Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  color: Colors.black,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Stack(children: [
                      ListView(
                        children: [
                          const Center(
                            child: Text(
                              "Review New Trip",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 15, 5, 15),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.white70,
                                    size: 25,
                                  ),
                                  const Text(
                                    "From:  ",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  Expanded(
                                    child: Text(
                                        rideType == "toASU"
                                            ? pickupTextEditingController.text
                                            : "Faculty of Engineering, ASU",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]),
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Visibility(
                                    visible:
                                        rideType == "fromASU" ? true : false,
                                    child: ToggleButtons(
                                      direction: Axis.horizontal,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20)),
                                      selectedColor: Colors.white,
                                      color: Colors.white70,
                                      borderColor: Colors.blueAccent,
                                      selectedBorderColor: Colors.blueAccent,
                                      constraints: BoxConstraints(
                                        minHeight: 40.0,
                                        minWidth:
                                            (MediaQuery.of(context).size.width - 40) / 3,
                                      ),
                                      isSelected: selectedGate,
                                      children: const [
                                        Text("Gate 2",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        Text("Gate 3",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        Text("Gate 4",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold))
                                      ],
                                      onPressed: (index) {
                                        setState(() {
                                          for (int i = 0; i < selectedGate.length; i++) {
                                            selectedGate[i] = i == index;
                                          }
                                          gate = index + 2;
                                        });
                                      },
                                    )),
                              ]),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(10, 15, 5, 15),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Icon(
                                    Icons.location_pin,
                                    color: Colors.white70,
                                    size: 25,
                                  ),
                                  const Text(
                                    "To:     ",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  Expanded(
                                    child: Text(
                                        rideType == "fromASU"
                                            ? dropoffTextEditingController.text
                                            : "Faculty of Engineering, ASU",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 21,
                                            fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]),
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Visibility(
                                    visible: rideType == "toASU" ? true : false,
                                    child: ToggleButtons(
                                      direction: Axis.horizontal,
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(20)),
                                      selectedColor: Colors.white,
                                      color: Colors.white70,
                                      borderColor: Colors.blueAccent,
                                      selectedBorderColor: Colors.blueAccent,
                                      constraints: BoxConstraints(
                                        minHeight: 40.0,
                                        minWidth:
                                            (MediaQuery.of(context).size.width - 40) / 3,
                                      ),
                                      isSelected: selectedGate,
                                      children: const [
                                        Text("Gate 2",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        Text("Gate 3",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        Text("Gate 4",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold))
                                      ],
                                      onPressed: (index) {
                                        setState(() {
                                          for (int i = 0; i < selectedGate.length; i++) {
                                            selectedGate[i] = i == index;
                                          }
                                          gate = index + 2;
                                        });
                                      },
                                    )),
                              ]),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Icon(
                                    Icons.route,
                                    color: Colors.white70,
                                    size: 25,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    routeData?["distanceText"],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    width: 35,
                                  ),
                                  const Icon(
                                    Icons.drive_eta,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                      routeData?["timeText"],
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                  ),
                                ]),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: callDatePicker,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  // crossAxisAlignment: CrossAxisAlignment.center,
                                  // textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    const Icon(
                                      Icons.date_range,
                                      color: Colors.white70,
                                      size: 25,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                        Utils.formatDate(tripDate),
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold),
                                    ),
                                  ]),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.white70,
                                    size: 25,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  const Text(
                                    "Start Time: ",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  Text(
                                    rideType == "toASU"
                                        ? "7:30 AM"
                                        : "5:30 PM",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ]),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  const Icon(
                                    Icons.attach_money,
                                    color: Colors.white70,
                                    size: 25,
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                  const Text(
                                    "Ticket Price: ",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic),
                                  ),
                                  Text(
                                    routeData?["priceText"],
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ]),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              addTrip();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shadowColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 2,
                                  color: Colors.green,
                                ),
                                borderRadius: BorderRadius.circular(40),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(50, 15, 50, 15),
                            ),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Confirm New Trip",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: toggleRideType,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 18,
                            child: Transform.rotate(
                              angle: -1.5708,
                              child: const Icon(
                                Icons.compare_arrows_rounded,
                                color: Colors.black,
                                size: 35,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ))
              : const SizedBox(),
        ));
  }
}
