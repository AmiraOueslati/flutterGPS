import'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


class NotificationPage extends StatefulWidget {
  @override
  _NotificationPageState createState() => _NotificationPageState();
}
 
class _NotificationPageState extends State<NotificationPage> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
 
  final zoneLatitude = 36.8065; // Latitude de la zone
  final zoneLongitude = 10.1815; // Longitude de la zone
  final zoneRadius = 500.0; // Rayon de la zone en mètres
 
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }
 
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
 
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
 
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
 
  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );
 
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
 
    await flutterLocalNotificationsPlugin.show(
      0,
      'Alerte Zone',
      message,
      platformChannelSpecifics,
    );
  }
 
  Future<void> _checkPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Les services de localisation sont désactivés.');
    }
 
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Les permissions de localisation sont refusées.');
      }
    }
 
    Geolocator.getPositionStream().listen((Position position) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        zoneLatitude,
        zoneLongitude,
      );
 
      if (distance > zoneRadius) {
        _showNotification("L'animal a quitté la zone !");
      }
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exemple de Notification"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _checkPosition();
          },
          child: Text("Activer les Notifications"),
        ),
      ),
    );
  }
}