import 'dart:developer';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

class Utils{
  static Future<bool> checkInternetConnection(BuildContext buildContext) async{
    var result = await Connectivity().checkConnectivity();
    if(result!= ConnectivityResult.mobile && result != ConnectivityResult.wifi){
      displaySnack("Internet connection is not available. Check your connection and try again!", buildContext);
      return false;
    }
    return true;
  }

  static displaySnack(String messageText, BuildContext buildContext){
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(buildContext).showSnackBar(snackBar);
  }

  static displayToast(String messageText, BuildContext buildContext, {Toast? toastLength = Toast.LENGTH_SHORT, ToastGravity? gravity, Color? backgroundColor, Color? textColor, double? fontSize}){
    Fluttertoast.showToast(
      msg: messageText,
      toastLength: toastLength,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static Future<void> openColorPicker(BuildContext context, selectedVehicleType ,Color initialColor,onColorChanged) async {
    bool pickedColor = await ColorPicker(
      color: initialColor,
      enableShadesSelection: false,
      showMaterialName: true,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: false,
      },
      customColorSwatchesAndNames: <ColorSwatch<Object>, String>{
        ColorTools.createPrimarySwatch(Colors.black): 'Black',
        ColorTools.createPrimarySwatch(Colors.white): 'White',
        ColorTools.createPrimarySwatch(Colors.grey): 'Silver',
        Colors.grey: 'Grey',
        Colors.red: 'Red',
        Colors.blue: 'Blue',
        Colors.green: 'Green',
        Colors.yellow: 'Yellow',
        Colors.orange: 'Orange',
        Colors.brown: 'Brown',
        Colors.purple: 'Purple',
        Colors.lime: 'Lime',
        Colors.teal: 'Teal',
        Colors.pink: 'Pink',
        Colors.cyan: 'Cyan',
      },
      onColorChanged:onColorChanged,
      width: 40,
      height: 40,
      borderRadius: 20,
      spacing: 10,
      runSpacing: 10,
      heading: Text('Pick Your $selectedVehicleType Color'),
      wheelDiameter: 200,
      wheelWidth: 20,
    ).showPickerDialog(context);
  }


  static toRadians(double degree){
    return degree * (pi/180);
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    FlutterPhoneDirectCaller.callNumber(phoneNumber);
  }

  static String formatDate(DateTime date){
    return DateFormat('E dd-MM-yyyy').format(date);
  }

}