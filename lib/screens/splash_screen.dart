import 'package:flutter/material.dart';
import 'package:logger/logger.dart';



class SplashScreen extends StatelessWidget {

  SplashScreen() {
    print('SplashScreen Constructor');
  }

  @override
  Widget build(BuildContext context) {

    var logger = Logger();
    logger.d("Debug message");
    logger.w("Warning message!");
    logger.e("Error message!!");


    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Text('Welcome to the Home Screen!'),
      ),
    );
  }
}