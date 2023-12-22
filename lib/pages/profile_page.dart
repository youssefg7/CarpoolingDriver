import 'dart:io';

import 'package:carpool_driver_flutter/widgets/loading_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../Utilities/utils.dart';
import '../data/Models/UserModel.dart';
import '../data/Repositories/UserRepository.dart';
import 'package:badges/badges.dart' as Badge;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserRepository userRepository = UserRepository();
  Student user = Student(
    id: '',
    username: '',
    email: '',
    phone: '',
    isDriver: false,
  );

  bool updateModelPressed = false;
  final _modelFocusNode = FocusNode();
  final GlobalKey<FormState> _modelFormKey = GlobalKey<FormState>();

  bool updateColorPressed = false;
  Color selectedColor = const Color(0x00000000);
  String selectedColorName = "FFFFFFFF";

  bool updatePlatesPressed = false;
  final colorTextEditingController = TextEditingController();
  final _platesFocusNode = FocusNode();
  final GlobalKey<FormState> _platesFormKey = GlobalKey<FormState>();

  bool updateMobilePressed = false;
  final _mobileFocusNode = FocusNode();
  final mobileTextEditingController = TextEditingController();
  final GlobalKey<FormState> _mobileFormKey = GlobalKey<FormState>();

  bool changePasswordPressed = false;
  final _oldPasswordFocusNode = FocusNode();
  final oldPasswordTextEditingController = TextEditingController();
  final newPasswordTextEditingController = TextEditingController();
  final confirmPasswordTextEditingController = TextEditingController();
  final vehicleModelTextEditingController = TextEditingController();
  final vehicleColorTextEditingController = TextEditingController();
  final vehiclePlatesTextEditingController = TextEditingController();
  final GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  updatePlates() {
    if (vehiclePlatesTextEditingController.text.isEmpty) {
      setState(() {
        updatePlatesPressed = false;
        return;
      });
    }
    if (_platesFormKey.currentState!.validate()) {
      showPlatesAlertDialog(context);
    }
  }

  showPlatesAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
        setState(() {
          updatePlatesPressed = false;
          vehiclePlatesTextEditingController.clear();
        });
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Confirm Vehicle Plates"),
      onPressed: () {
        Navigator.of(context).pop();
        user.phone = vehiclePlatesTextEditingController.text;
        userRepository.updateCurrentUser(user).then((value) {
          Utils.displaySnack("Vehicle Plates updated successfully", context);
          setState(() {
            updatePlatesPressed = false;
            vehiclePlatesTextEditingController.clear();
          });
        }).onError((error, stackTrace) => Utils.displaySnack(
            "Error occured: \n ${error.toString()}", context));
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Update Vehicle Plates"),
      content:
      const Text("Are you sure you want to update your Vehicle Plates?"),
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

  updateModel() {
    if (vehicleModelTextEditingController.text.isEmpty) {
      setState(() {
        updateModelPressed = false;
        return;
      });
    }
    if (_modelFormKey.currentState!.validate()) {
      showModelAlertDialog(context);
    }
  }

  showModelAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
        setState(() {
          updateModelPressed = false;
          vehicleModelTextEditingController.clear();
        });
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Confirm Vehicle Model"),
      onPressed: () {
        Navigator.of(context).pop();
        user.vehicleModel = vehicleModelTextEditingController.text;
        userRepository.updateCurrentUser(user).then((value) {
          Utils.displaySnack("Vehicle Model updated successfully", context);
          setState(() {
            updateModelPressed = false;
            vehicleModelTextEditingController.clear();
          });
        }).onError((error, stackTrace) => Utils.displaySnack(
            "Error occured: \n ${error.toString()}", context));
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Update Vehicle Model"),
      content:
          const Text("Are you sure you want to update your Vehicle Model?"),
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

  updateMobileNumber() {
    if (mobileTextEditingController.text.isEmpty) {
      setState(() {
        updateMobilePressed = false;
        return;
      });
    }
    if (_mobileFormKey.currentState!.validate()) {
      showMobileAlertDialog(context);
    }
  }

  showMobileAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
        setState(() {
          updateMobilePressed = false;
          mobileTextEditingController.clear();
        });
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Confirm Mobile Number"),
      onPressed: () {
        Navigator.of(context).pop();
        user.phone = mobileTextEditingController.text;
        userRepository.updateCurrentUser(user).then((value) {
          Utils.displaySnack("Mobile number updated successfully", context);
          setState(() {
            updateMobilePressed = false;
            mobileTextEditingController.clear();
          });
        }).onError((error, stackTrace) => Utils.displaySnack(
            "Error occured: \n ${error.toString()}", context));
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Update Mobile Number"),
      content:
          const Text("Are you sure you want to update your mobile number?"),
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

  updatePassword() {
    if (_passwordFormKey.currentState!.validate()) {
      showPasswordAlertDialog(context);
    }
  }

  showPasswordAlertDialog(BuildContext context) {
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
        setState(() {
          changePasswordPressed = false;
          oldPasswordTextEditingController.clear();
          newPasswordTextEditingController.clear();
          confirmPasswordTextEditingController.clear();
        });
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Confirm Password Change"),
      onPressed: () {
        Navigator.of(context).pop();
        AuthCredential credential = EmailAuthProvider.credential(
          email: "${user.email}@eng.asu.edu.eg",
          password: oldPasswordTextEditingController.text,
        );
        FirebaseAuth.instance.currentUser!
            .reauthenticateWithCredential(credential)
            .then((result) {
          FirebaseAuth.instance.currentUser!
              .updatePassword(newPasswordTextEditingController.text)
              .then((value) {
            Utils.displaySnack("Password updated successfully", context);
          }).onError((error, stackTrace) => Utils.displaySnack(
              "Error: \n ${error.toString()}", context));
          setState(() {
            changePasswordPressed = false;
            oldPasswordTextEditingController.clear();
            newPasswordTextEditingController.clear();
            confirmPasswordTextEditingController.clear();
          });
        }).catchError((error) {
          Utils.displaySnack("Old Password Incorrect", context);
        });
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

  updateProfilePicture() async {
    ImagePicker imagePicker = ImagePicker();
    XFile? image = imagePicker.pickImage(source: ImageSource.gallery) as XFile?;
    if (image == null) {
      return;
    }
    showDialog(
        context: context,
        builder: (BuildContext context) => LoadingDialog(
          messageText: 'Updating Profile Picture',
        ));
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('profile_pictures/${FirebaseAuth.instance.currentUser!.uid}');
    ref.putFile(File(image.path));
    setState(() {
      user.profilePicture = ref.getDownloadURL().toString();
    });
    if (await userRepository.updateCurrentUser(user)) {
      Navigator.of(context).pop();
      Utils.displaySnack("Profile picture updated successfully", context);
    } else {
      Navigator.of(context).pop();
      Utils.displaySnack(
          "Error occured while updating profile picture", context);
    }
  }


  getUserInfo() async {
    user = await userRepository.getCurrentUser();
    setState(() {
      user = user;
    });
  }

  @override
  void initState() {
    getUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("${user.username.split(" ")[0]}'s Profile"),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.blueAccent,
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ),
        body: ListView(children: [
          Column(
            children: [
              GestureDetector(
                onTap: () async{
                  if(!(await Utils.checkInternetConnection(context))){
                    return;
                  }
                  updateProfilePicture();
                },
                child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Badge.Badge(
                    position: Badge.BadgePosition.bottomEnd(),
                    badgeStyle: const Badge.BadgeStyle(
                      badgeColor: Colors.blueAccent,
                      padding: EdgeInsets.all(10),
                      shape: Badge.BadgeShape.circle,
                    ),
                    badgeContent: Icon(
                      (user.profilePicture != null &&
                          user.profilePicture != '')?
                      Icons.edit
                          :Icons.add,
                      color: Colors.white,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white70,
                          width: 10,
                        ),
                      ),
                      child: ClipOval(
                        child: (user.profilePicture != null &&
                            user.profilePicture != '')?
                        Image(
                          image: NetworkImage(user.profilePicture!),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ):
                        const Icon(
                          Icons.person,
                          color: Colors.white70,
                          size: 150,)
                        ,
                      ),
                    ),
                  ),
                ),
              ),
              const Text(
                "Your ASUFE Carpooling Profile",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                          // mainAxisAlignment: MainAxisAlignment.center,
                          // crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.person,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Name: ",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic),
                            ),
                            Expanded(
                              child: Text(
                                user.username,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                              Icons.person_pin_rounded,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "ASUFE ID: ",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic),
                            ),
                            Expanded(
                              child: Text(
                                user.email,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 5, 20),
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
                              Icons.phone,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Mobile: ",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 25,
                                  fontStyle: FontStyle.italic),
                            ),
                            Expanded(
                              child: updateMobilePressed
                                  ? Form(
                                      key: _mobileFormKey,
                                      child: TextFormField(
                                        focusNode: _mobileFocusNode,
                                        controller: mobileTextEditingController,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(11),
                                        ],
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          labelStyle:
                                              const TextStyle(fontSize: 18),
                                          hintText: "01xxxxxxxxx",
                                          suffixIcon: IconButton(
                                            onPressed: updateMobileNumber,
                                            icon:
                                                const Icon(Icons.check_circle),
                                          ),
                                        ),
                                        style:
                                            const TextStyle(color: Colors.grey),
                                        autovalidateMode:
                                            AutovalidateMode.disabled,
                                        validator: (value) {
                                          if (value?.length != 11 ||
                                              !value!.startsWith('01')) {
                                            return 'Please enter a valid mobile number';
                                          }
                                          return null;
                                        },
                                      ))
                                  : Text(
                                      user.phone,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                            // const SizedBox(
                            //   width: 10,
                            // ),
                            updateMobilePressed
                                ? const SizedBox(
                                    width: 0,
                                  )
                                : IconButton(
                                    onPressed: () async{
                                      if(!(await Utils.checkInternetConnection(context))){
                                        return;
                                      }
                                      setState(() {
                                        updateMobilePressed = true;
                                      });
                                      _mobileFocusNode.requestFocus();
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),
                          ]),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    changePasswordPressed
                        ? Form(
                            key: _passwordFormKey,
                            child: Column(children: [
                              const SizedBox(
                                height: 20,
                              ),
                              TextFormField(
                                focusNode: _oldPasswordFocusNode,
                                controller: oldPasswordTextEditingController,
                                obscureText: !_oldPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "Old Password",
                                  labelStyle: const TextStyle(fontSize: 16),
                                  prefixIcon: const Icon(Icons.password),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _oldPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _oldPasswordVisible =
                                            !_oldPasswordVisible;
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
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: (value) {
                                  if (value!.trim().isEmpty) {
                                    return 'Please enter your old password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              TextFormField(
                                controller: newPasswordTextEditingController,
                                obscureText: !_newPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "New Password",
                                  labelStyle: const TextStyle(fontSize: 16),
                                  prefixIcon: const Icon(Icons.password),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _newPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _newPasswordVisible =
                                            !_newPasswordVisible;
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
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: (value) {
                                  if (value!.trim().isEmpty) {
                                    return 'Please enter your new password';
                                  } else if (value.trim().length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              TextFormField(
                                controller:
                                    confirmPasswordTextEditingController,
                                obscureText: !_confirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: "Confirm New Password",
                                  labelStyle: const TextStyle(fontSize: 16),
                                  prefixIcon: const Icon(Icons.password),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _confirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _confirmPasswordVisible =
                                            !_confirmPasswordVisible;
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
                                autovalidateMode: AutovalidateMode.disabled,
                                validator: (value) {
                                  if (value!.trim().isEmpty) {
                                    return 'Please enter your new password';
                                  } else if (value.trim().length < 6) {
                                    return 'Password must be at least 6 characters long';
                                  } else if (value.trim() !=
                                      newPasswordTextEditingController.text
                                          .trim()) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          changePasswordPressed = false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 15, 10, 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                      ),
                                      child: const Text("Cancel"),
                                    ),
                                  ),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: updatePassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 15, 10, 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(40),
                                        ),
                                      ),
                                      child: const Text("Update Password"),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                            ]),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      changePasswordPressed = true;
                                    });
                                    _oldPasswordFocusNode.requestFocus();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    padding: const EdgeInsets.fromLTRB(
                                        10, 15, 10, 15),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                  ),
                                  child: const Text("Change Password"),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 5, 20),
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
                            Icon(
                              user.vehicleType == "Car"
                                  ? Icons.car_rental
                                  : Icons.motorcycle,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Model: ",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic),
                            ),
                            Expanded(
                              child: updateModelPressed
                                  ? Form(
                                      key: _modelFormKey,
                                      child: TextFormField(
                                        focusNode: _modelFocusNode,
                                        controller:
                                            vehicleModelTextEditingController,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(50),
                                        ],
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          labelStyle:
                                              const TextStyle(fontSize: 18),
                                          suffixIcon: IconButton(
                                            onPressed: updateModel,
                                            icon:
                                                const Icon(Icons.check_circle),
                                          ),
                                        ),
                                        style:
                                            const TextStyle(color: Colors.grey),
                                        autovalidateMode:
                                            AutovalidateMode.disabled,
                                        validator: (value) {
                                          if (value!.length < 5) {
                                            return 'Please enter a valid model!';
                                          }
                                          return null;
                                        },
                                      ))
                                  : Text(
                                      user.vehicleModel ?? '',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                            // const SizedBox(
                            //   width: 10,
                            // ),
                            updateModelPressed
                                ? const SizedBox(
                                    width: 0,
                                  )
                                : IconButton(
                                    onPressed: () async{
                                      if(!(await Utils.checkInternetConnection(context))){
                                        return;
                                      }
                                      setState(() {
                                        updateModelPressed = true;
                                      });
                                      _modelFocusNode.requestFocus();
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),
                          ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 5, 20),
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
                              Icons.color_lens,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Color: ",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic),
                            ),
                            Expanded(
                              child: Text(
                                user.vehicleColor ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            IconButton(
                                    onPressed: () async{
                                      if(!(await Utils.checkInternetConnection(context))){
                                        return;
                                      }
                                      setState(() {
                                        updateColorPressed = true;
                                      });
                                      Utils.openColorPicker(context, user.vehicleType, selectedColor,(Color newColor) {
                                        setState(() {
                                          selectedColor = newColor;
                                          user.vehicleColor = ColorTools.materialName(selectedColor);
                                        });
                                        userRepository.updateCurrentUser(user).then((value) {
                                          Utils.displaySnack("Vehicle Color updated successfully", context);
                                          setState(() {
                                            updateColorPressed = false;
                                          });
                                        }).onError((error, stackTrace) => Utils.displaySnack(
                                            "Error occured: \n ${error.toString()}", context));
                                      });
                                    },
                                    icon: const Icon(Icons.edit),
                                  ),
                          ]),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 5, 20),
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
                              Icons.numbers,
                              color: Colors.white70,
                              size: 40,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            const Text(
                              "Plates: ",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 20,
                                  fontStyle: FontStyle.italic),
                            ),
                            Expanded(
                              child: updatePlatesPressed
                                  ? Form(
                                  key: _platesFormKey,
                                  child: TextFormField(
                                    focusNode: _platesFocusNode,
                                    controller:
                                    vehiclePlatesTextEditingController,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(8),
                                    ],
                                    keyboardType: TextInputType.text,
                                    decoration: InputDecoration(
                                      labelStyle:
                                      const TextStyle(fontSize: 18),
                                      suffixIcon: IconButton(
                                        onPressed: updatePlates,
                                        icon:
                                        const Icon(Icons.check_circle),
                                      ),
                                    ),
                                    style:
                                    const TextStyle(color: Colors.grey),
                                    autovalidateMode:
                                    AutovalidateMode.disabled,
                                    validator: (value) {
                                      RegExp platePattern = RegExp(r"^[A-Z]{3}[0-9]{3}[0-9]?", caseSensitive: false);
                                      if (!platePattern.hasMatch(value!.trim())) {
                                        return "Please enter valid plate info (xxx000(0)).";
                                      }
                                    },
                                  ))
                                  : Text(
                                user.vehiclePlates ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            updatePlatesPressed
                                ? const SizedBox(
                              width: 0,
                            )
                                : IconButton(

                              onPressed: () async{
                                if(!(await Utils.checkInternetConnection(context))){
                                  return;
                                }
                                setState(() {
                                  updatePlatesPressed = true;
                                });
                                _platesFocusNode.requestFocus();
                              },
                              icon: const Icon(Icons.edit),
                            ),
                          ]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}