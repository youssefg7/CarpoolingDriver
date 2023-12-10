import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Utilities/utils.dart';
import '../widgets/loading_dialog.dart';

class MissingVehicleScreen extends StatefulWidget {
  const MissingVehicleScreen({super.key});

  @override
  State<MissingVehicleScreen> createState() => _MissingVehicleScreenState();
}

class _MissingVehicleScreenState extends State<MissingVehicleScreen> {
  TextEditingController colorTextEditingController = TextEditingController();
  TextEditingController modelTextEditingController = TextEditingController();
  TextEditingController plateTextEditingController = TextEditingController();
  TextEditingController colorPickerController = TextEditingController();
  String selectedVehicleType = "Car";

  Color selectedColor = const Color(0x00000000);
  String selectedColorName = "FFFFFFFF";

  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  List vehicleTypes = [
    "Car",
    "Motorcycle",
  ];

  updateDriver() async {
    setState(() => _submitted = true);

    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => LoadingDialog(
          messageText: "Adding your $selectedVehicleType...",
        ),
      );

      User? userFirebase = FirebaseAuth.instance.currentUser;

      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          DocumentReference userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(userFirebase!.uid);

          DocumentSnapshot snapshot = await transaction.get(userRef);

          if (snapshot.exists) {
            transaction.update(userRef, {
              "vehicleType": selectedVehicleType,
              "vehicleColor": colorTextEditingController.text.trim(),
              "vehicleModel": modelTextEditingController.text.trim(),
              "vehiclePlates": plateTextEditingController.text.trim(),
              "isDriver": true,
            });
          }
        });

        Navigator.pop(context);

        Navigator.pushReplacementNamed(
          context,
          '/home',);
      } catch (e) {
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: ListView(children: [
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(40),
                child: Image(
                  image: AssetImage("assets/images/logo.png"),
                ),
              ),
              const Text(
                "ASU FE Carpooling Community",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Text(
                "Update your Account to drive!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 20, 15, 50),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          "$selectedVehicleType Details:",
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 13,
                      ),
                      DropdownButtonFormField(
                        decoration: InputDecoration(
                          labelText: "Vehicle Type",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: Icon(selectedVehicleType=="Car"?Icons.drive_eta:Icons.motorcycle),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(
                              width: 2,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        items: vehicleTypes.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e))).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedVehicleType = value.toString();
                          });
                        },),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: colorTextEditingController,
                        keyboardType: TextInputType.none,
                        readOnly: true,
                        showCursor: false,
                        decoration: InputDecoration(
                          labelText: "Choose $selectedVehicleType Color",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.color_lens),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              Utils.openColorPicker(context, selectedVehicleType, selectedColor,(Color newColor) {
                                setState(() {
                                  selectedColor = newColor;
                                  colorTextEditingController.text = ColorTools.materialName(selectedColor);
                                  selectedColorName = ColorTools.colorCode(selectedColor);
                                });
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 2,
                                  color: Colors.white,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: selectedColor,
                              ),
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(
                              width: 2,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: modelTextEditingController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(25),
                        ],
                        decoration: InputDecoration(
                          labelText: "$selectedVehicleType Model",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.settings),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(
                              width: 2,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.grey),
                        autovalidateMode: _submitted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return "Please enter your $selectedVehicleType model.";
                          }
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: plateTextEditingController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          labelText: "$selectedVehicleType Plates Number",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(40),
                            borderSide: const BorderSide(
                              width: 2,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.grey),
                        autovalidateMode: _submitted
                            ? AutovalidateMode.onUserInteraction
                            : AutovalidateMode.disabled,
                        validator: (value) {
                          if (value!.trim().isEmpty) {
                            return "Please enter your $selectedVehicleType plates number.";
                          }
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [Expanded(
                          child: ElevatedButton(
                              onPressed: () {
                                Utils.checkInternetConnection(context);
                                updateDriver();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(32)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 15)),
                              child: const Text("Confirm Vehicle Details",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ))),
                        ),]
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Already have an account? Login Here!",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
