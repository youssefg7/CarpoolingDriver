import 'dart:async';
import 'package:carpool_driver_flutter/data/Repositories/UserRepository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {
UserRepository userRepository = UserRepository();

  Future<bool> isDriver() async {
    return await userRepository.getCurrentUser().then((user) {
      print(user.toJSON());
      return user.isDriver;
    });
  }

  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () async {
      if (FirebaseAuth.instance.currentUser !=null){
        bool isDriverRegistered = await isDriver();
        if(!FirebaseAuth.instance.currentUser!.emailVerified){
          Navigator.pushReplacementNamed(context, '/verifyEmail');
        }else{
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
      else{
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
