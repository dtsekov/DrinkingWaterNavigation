// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_seeder.dart';
import '../login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _dbUrlController = TextEditingController();
  final _uidController   = TextEditingController();
  final _tokenController = TextEditingController();

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _dbUrlController.text = prefs.getString('db_url') ?? '';
    _uidController.text   = prefs.getString('uid')    ?? '';
    _tokenController.text = prefs.getString('token')  ?? '';
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('db_url', _dbUrlController.text.trim());
    await prefs.setString('uid',    _uidController.text.trim());
    await prefs.setString('token',  _tokenController.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Settings saved')));
  }

  Future<void> _resedDb() async {
    await _savePrefs();
    await FirebaseSeeder.seedFountains();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Database reseeded')));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
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
      appBar: AppBar(title: Text("Settings")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _dbUrlController,
              decoration: InputDecoration(labelText: 'Database URL'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _uidController,
              decoration: InputDecoration(labelText: 'User UID'),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(labelText: 'Weather API Token'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _savePrefs,
              child: Text('Save Settings'),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _resedDb,
              child: Text('Reseed Database'),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
