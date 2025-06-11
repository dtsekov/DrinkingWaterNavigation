import 'package:drinking_water_navigation/screens/initial_config_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  void _signInWithEmailAndPassword() async {
    try {
      final User? user = (await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      )).user;
      if (user != null) {
        print('Login successful!');
        final prefs = await SharedPreferences.getInstance();
        final dbUrl = prefs.getString('db_url');
        if (dbUrl == null || dbUrl.isEmpty) {
          // First time setup
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => InitialConfigScreen()),
          );
        }
      } else {
        print('Login failed!');
      }
    } catch (e) {
      print(e); // Handle the error
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Iniciar sesión")),
    body: Column(
      children: <Widget>[
        TextField(
          controller: emailController,
          decoration: InputDecoration(labelText: 'Email'),
        ),
        TextField(
          controller: passwordController,
          decoration: InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),
        ElevatedButton(
          onPressed: _signInWithEmailAndPassword,
          child: Text('Login'),
        ),
      ],
    ),
    );
  }
}
