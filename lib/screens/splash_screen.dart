import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_screen.dart';
import '/db/database_helper.dart';
import 'package:drinking_water_navigation/location.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;





class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<Position>? _positionStreamSubscription;
  DatabaseHelper db = DatabaseHelper.instance;
  Map<String, dynamic>? weatherData;
  bool isLoadingWeather = false;


  final logger = Logger();
  final _uidController = TextEditingController();
  final _tokenController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? uid = prefs.getString('uid');
    String? token = prefs.getString('token');
    String? dbUrl = prefs.getString('db_url');
    logger.d("UID: $uid, Token: $token, DB_URL: $dbUrl");

  }
  Future<void> _showInputDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter UID and Token'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: _uidController,
                  decoration: InputDecoration(hintText: "UID"),
                ),
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(hintText: "Token"),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('uid', _uidController.text);
                await prefs.setString('token', _tokenController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drinking Water Navigation'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Enable location permissions by tapping on the switch button.'),
            Switch(
              value: _positionStreamSubscription != null,
              onChanged: (value) {
                setState(() {
                  if (value) {
                    startTracking();
                  } else {
                    stopTracking();
                  }
                });
              },
            ),

            SizedBox(height: 20),

            // 1) Show loader while fetching
            if (isLoadingWeather) CircularProgressIndicator(),

            // 2) Once we have weatherData, display it all:
            if (!isLoadingWeather
                && weatherData != null
                && weatherData!['list'] != null
                && weatherData!['list'].isNotEmpty)
              Column(
                children: <Widget>[
                  Text(
                    'City: ${weatherData!['list'][0]['name']}',
                    style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),

                  Text(
                    'Country: ${weatherData!['list'][0]['sys']['country']}',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),

                  // Use the global CurrentLocation if you want live coords,
                  // or interpolate the ones you passed in.
                  Text(
                    'Coordinates: '
                        '${CurrentLocation.latitude?.toStringAsFixed(4) ?? '-'}, '
                        '${CurrentLocation.longitude?.toStringAsFixed(4) ?? '-'}',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),

                  Text(
                    'Feels Like: '
                        '${(weatherData!['list'][0]['main']['feels_like'] - 273.15).toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),

                  Text(
                    'Description: '
                        '${weatherData!['list'][0]['weather'][0]['description']}',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),

                  Text(
                    'Temperature: '
                        '${(weatherData!['list'][0]['main']['temp'] - 273.15).toStringAsFixed(1)}°C',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),

                  Text(
                    'Humidity: '
                        '${weatherData!['list'][0]['main']['humidity']}%',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  SizedBox(height: 8.0),

                  Text(
                    'Wind Speed: '
                        '${weatherData!['list'][0]['wind']['speed']} m/s',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  void startTracking() async {
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // Adjust the accuracy as needed
      distanceFilter: 10, // Distance in meters before an update is triggered
    );
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
        db.insertCoordinate(position);
        // Update global location
        setState(() {
          CurrentLocation.enableTracking();
          CurrentLocation.latitude = position.latitude;
          CurrentLocation.longitude = position.longitude;
        });

        // Fetch weather for new location
        await fetchWeather(position.latitude, position.longitude);
      },
    );

  }
  void stopTracking() {
    CurrentLocation.disableTracking();
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
  Future<void> writePositionToFile(Position position) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/gps_coordinates.csv');
    String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await file.writeAsString('${timestamp};${position.latitude};${position.longitude}\n', mode: FileMode.append);
  }

  @override
  void dispose() {
    _uidController.dispose();
    _tokenController.dispose();
    super.dispose();
  }


  Future<void> fetchWeather(double lat, double lon) async {
    setState(() {
      isLoadingWeather = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('token') ?? '';
      if (apiKey.isEmpty) {
        throw Exception('API token not found');
      }

      final url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/find?lat=$lat&lon=$lon&cnt=1&APPID=$apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          weatherData = data;
          isLoadingWeather = false;
        });
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoadingWeather = false;
      });
      print('Error fetching weather: $e');
    }
  }
}




