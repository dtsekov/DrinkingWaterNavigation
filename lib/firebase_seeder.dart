import 'package:flutter/services.dart' show rootBundle;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseSeeder {
  /// Call this once on app startup—after Firebase.initializeApp()
  static Future<void> seedFountains() async {
    final prefs = await SharedPreferences.getInstance();
    final dbUrl = prefs.getString('db_url')!;
    final database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: dbUrl,
    );
    final ref = database.ref().child('fountains');

    // 1) Check if any fountains already exist
    final snapshot = await ref.get();
    if (snapshot.exists && snapshot.children.isNotEmpty) {
      // Already seeded → nothing to do
      return;
    }

    // 2) Load CSV from assets
    final csvString = await rootBundle.loadString('assets/fountain_coordinates.csv');
    final lines = csvString.split('\n');

    // 3) Parse and push each line
    for (final line in lines) {
      final parts = line.trim().split(';');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lon = double.tryParse(parts[1]);
        if (lat != null && lon != null) {
          await ref.push().set({
            'latitude': lat,
            'longitude': lon,
          });
        }
      }
    }
  }
}