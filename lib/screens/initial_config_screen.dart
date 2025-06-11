// lib/screens/initial_config_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_seeder.dart';
import '../main_screen.dart';

class InitialConfigScreen extends StatefulWidget {
  @override
  _InitialConfigScreenState createState() => _InitialConfigScreenState();
}

class _InitialConfigScreenState extends State<InitialConfigScreen> {
  final TextEditingController _dbUrlController   = TextEditingController();
  final TextEditingController _uidController     = TextEditingController();
  final TextEditingController _tokenController   = TextEditingController();
  bool _isSaving = false, _hasError = false;

  Future<void> _saveAllAndSeed() async {
    setState(() { _isSaving = true; _hasError = false; });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('db_url', _dbUrlController.text.trim());
      await prefs.setString('uid',    _uidController.text.trim());
      await prefs.setString('token',  _tokenController.text.trim());

      // Seed fountains into the user's DB
      await FirebaseSeeder.seedFountains();

      // Go into the main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen()),
      );
    } catch (e) {
      setState(() { _hasError = true; });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _dbUrlController.dispose();
    _uidController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Initial Configuration")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
                "Please enter your Firebase Realtime-DB URL, your user UID, and your OpenWeather API token."
            ),
            SizedBox(height: 16),
            TextField(
              controller: _dbUrlController,
              decoration: InputDecoration(
                labelText: "Database URL",
                errorText: _hasError ? "Invalid or unreachable URL" : null,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _uidController,
              decoration: InputDecoration(
                labelText: "User UID",
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: "Weather API Token",
              ),
            ),
            SizedBox(height: 24),
            _isSaving
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _saveAllAndSeed,
              child: Text("Save & Initialize"),
            ),
          ],
        ),
      ),
    );
  }
}
