import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThirdScreen extends StatefulWidget {
  @override
  _ThirdScreenState createState() => _ThirdScreenState();
}

class _ThirdScreenState extends State<ThirdScreen> {
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lonController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseDatabase? _database;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('db_url');
    if (url != null) {
      setState(() {
        _database = FirebaseDatabase.instanceFor(
          app: Firebase.app(),
          databaseURL: url,
        );
      });
    } else {
      Fluttertoast.showToast(
        msg: "Database URL not found in SharedPreferences.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Fountain'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _latController,
              decoration: InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextFormField(
              controller: _lonController,
              decoration: InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _submitFountain(context, user),
              child: Text('Add Fountain'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFountain(BuildContext context, User? user) {
    final lat = double.tryParse(_latController.text);
    final lon = double.tryParse(_lonController.text);

    if (_database == null) {
      Fluttertoast.showToast(
        msg: "Database not initialized.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    if (lat == null || lon == null) {
      Fluttertoast.showToast(
        msg: "Please enter valid latitude and longitude.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final fountainsRef = _database!.ref().child('fountains');

    fountainsRef.push().set({
      'latitude': lat,
      'longitude': lon
    }).then((_) {
      Fluttertoast.showToast(
        msg: "Fountain added successfully!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      _latController.clear();
      _lonController.clear();
    }).catchError((error) {
      print("Failed to add fountain: $error");
      Fluttertoast.showToast(
        msg: "Error adding fountain.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    });
  }
}
