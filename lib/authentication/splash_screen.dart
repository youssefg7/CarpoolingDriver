import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {

  Future<bool> isDriver() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          final user = userDoc.data() as Map<String, dynamic>;
          return user['isDriver'] as bool ?? false;
        }
      } catch (e) {
        print('Error checking user driver status: $e');
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      print("here");
      if (FirebaseAuth.instance.currentUser !=null){
        print("object");
        bool isDriverRegistered = await isDriver();
        print("object");
        if(!FirebaseAuth.instance.currentUser!.emailVerified){
          print("here1");
          Navigator.pushReplacementNamed(context, '/verifyEmail');
        }else if (isDriverRegistered == false){
          print("here2");
          Navigator.pushReplacementNamed(context, '/missingVehicle');
        }else{
          print("here3");
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
      else{
        print("here3");
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        body: Center(
          child: Text(
            "ASUFE \n CARPOOL \n   DRIVERS",
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
    );
  }
}
