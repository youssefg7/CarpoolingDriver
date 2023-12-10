import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../Utilities/utils.dart';
import '../widgets/loading_dialog.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController usernameTextEditingController = TextEditingController();
  TextEditingController phoneTextEditingController = TextEditingController();
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  TextEditingController profilePictureTextEditingController = TextEditingController();
  TextEditingController colorTextEditingController = TextEditingController();
  TextEditingController modelTextEditingController = TextEditingController();
  TextEditingController plateTextEditingController = TextEditingController();
  String selectedVehicleType = "Car";
  Color selectedColor = const Color(0);
  String selectedColorName = "FFFFFFFF";
  String selectedProfilePicture = "";
  XFile? image;

  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;
  bool _submitted = false;
  RegExp emailPattern =
      RegExp(r'^[1-9][0-9][0PQTWEX][0-9]{4}', caseSensitive: false);

  List vehicleTypes = [
    "Car",
    "Motorcycle",
  ];

  registerNewUser() async {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => LoadingDialog(
                messageText: "Registering, Please wait...",
              ));
      final User? userFirebase = (await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: "${emailTextEditingController.text.trim()}@eng.asu.edu.eg",
        password: passwordTextEditingController.text.trim(),
      ).catchError((error) {
        Navigator.pop(context);
        Utils.displaySnack(error.toString(), context);
      })).user;

      if (!context.mounted) return;
      Navigator.pop(context);

      CollectionReference usersCollection = FirebaseFirestore.instance.collection('users');
      Reference ref = FirebaseStorage.instance
          .ref()
          .child(
          'profile_pictures/${userFirebase?.uid}');
      await ref.putFile(File(image!.path));
      String url = await ref.getDownloadURL();

        Map<String, dynamic> userMap = {
          "username": usernameTextEditingController.text.trim(),
          "phone": phoneTextEditingController.text.trim(),
          "email": emailTextEditingController.text.trim(),
          "id": userFirebase?.uid,
          "profilePicture": url,
          "vehicleType": selectedVehicleType,
          "vehicleColor": colorTextEditingController.text.trim(),
          "vehicleModel": modelTextEditingController.text.trim(),
          "vehiclePlates": plateTextEditingController.text.trim(),
          "isDriver": true,
        };

        await usersCollection.doc(userFirebase?.uid).set(userMap);

      Navigator.pushReplacementNamed(context, '/verifyEmail');
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
                  height: 150,
                  width: 150,
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
                "Create a New Driver Account",
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
                        child: const Text(
                          "Personal Details:",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: usernameTextEditingController,
                        keyboardType: TextInputType.text,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(20),
                        ],
                        decoration: InputDecoration(
                          labelText: "Name",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.person),
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
                          RegExp namePattern =
                              RegExp(r'^[A-Z ]+$', caseSensitive: false);
                          if (value!.isEmpty) {
                            return "Please enter your username.";
                          } else if (value.trim().length < 5) {
                            return "User Name must be at least 5 letters.";
                          } else if (value.trim().length > 50) {
                            return "User Name cannot be more than 50 characters.";
                          } else if (!namePattern.hasMatch(value.trim())) {
                            return "User Name must be in English and does not contain numbers.";
                          }
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: phoneTextEditingController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(11),
                        ],
                        decoration: InputDecoration(
                          labelText: "Mobile Number",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.phone),
                          hintText: "01XXXXXXXXX",
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
                            return "Please enter your mobile number.";
                          } else if (value.trim().length != 11) {
                            return "Mobile Number must be exactly 11 numbers.";
                          } else if (!value.trim().startsWith("01")) {
                            return "Mobile Number must start with 01.";
                          }
                        },
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextFormField(
                                  controller: emailTextEditingController,
                                  keyboardType: TextInputType.text,
                                  decoration: InputDecoration(
                                    labelText: "FE ASU ID",
                                    labelStyle: const TextStyle(fontSize: 16),
                                    prefixIcon:
                                        const Icon(Icons.alternate_email),
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
                                    RegExp idPattern = RegExp(
                                        r"^[1-9][0-9][0PQTWEX][0-9]{4}",
                                        caseSensitive: false);
                                    if (value!.trim().isEmpty) {
                                      return "Please enter your FE ASU ID.";
                                    } else if (!idPattern
                                        .hasMatch(value.trim())) {
                                      return "Please enter a valid FE ASU ID.";
                                    }
                                  }),
                            ),
                            const Text(
                              "@eng.asu.edu.eg",
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ]),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                          obscureText: !_passwordVisible,
                          controller: passwordTextEditingController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: const TextStyle(fontSize: 16),
                            prefixIcon: const Icon(Icons.password),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
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
                          autovalidateMode: _submitted
                              ? AutovalidateMode.onUserInteraction
                              : AutovalidateMode.disabled,
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "Please enter a password.";
                            } else if (value.trim().length < 6) {
                              return "Password must be at least 6 characters.";
                            } else if (value.trim().length > 32) {
                              return "Password cannot be more than 32 characters.";
                            }
                          }),
                      const SizedBox(
                        height: 15,
                      ),
                      TextFormField(
                        controller: profilePictureTextEditingController,
                        keyboardType: TextInputType.none,
                        readOnly: true,
                        showCursor: false,
                        decoration: InputDecoration(
                          labelText: "Upload Profile Picture",
                          labelStyle: const TextStyle(fontSize: 16),
                          prefixIcon: const Icon(Icons.camera_front_outlined),
                          suffixIcon: GestureDetector(
                            onTap: () async {
                                ImagePicker imagePicker = ImagePicker();
                                image = await imagePicker.pickImage(source: ImageSource.gallery);
                                if(image == null) {
                                  return;
                                }
                                try{}
                                catch(e){}
                            },
                            child: const Icon(Icons.camera_alt_outlined),
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
                        height: 15,
                      ),
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
                          LengthLimitingTextInputFormatter(50),
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
                          LengthLimitingTextInputFormatter(7),
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
                          RegExp platePattern = RegExp(r"^[A-Z]{3}[0-9]{3}[0-9]?", caseSensitive: false);
                          if (value!.trim().isEmpty) {
                            return "Please enter your $selectedVehicleType plate info.";
                          } else if (!platePattern.hasMatch(value.trim())) {
                            return "Please enter valid plate info (xxx000(0)).";
                          }
                        },
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      ElevatedButton(
                          onPressed: () {
                            Utils.checkInternetConnection(context);
                            registerNewUser();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 142, vertical: 15)),
                          child: const Text("Sign Up",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ))),
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

