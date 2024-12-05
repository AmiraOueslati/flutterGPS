import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_project/screens/marker_data.dart';
import 'package:flutter_project/screens/weather_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'Home_screen_animals.dart'; // Assurez-vous d'importer HomeScreen ici
import 'package:http/http.dart' as http;
import 'dart:math' as Math;

class RealTimeMapScreen extends StatefulWidget {
  const RealTimeMapScreen({super.key});

  @override
  _RealTimeMapScreenState createState() => _RealTimeMapScreenState();
}

class _RealTimeMapScreenState extends State<RealTimeMapScreen> {
  var _channel = WebSocketChannel.connect(
    Uri.parse('ws://localhost:3000'), // Remplacer par l'URL de ton serveur WebSocket
  );
  LatLng? _mylocation;
  List<LatLng> mouton1Positions = [];
  List<LatLng> mouton2Positions = [];
  List<LatLng> mouton3Positions = [];
  LatLng? _selectedPosition;
  LatLng? _draggedPosition;
  bool _isDragging = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  double zoneRadius = 500.0; // Default radius in meters
  late MapController _mapController;
  final List<MarkerData> _markerData = [];
  final List<Marker> _markers = [];
  LatLng? zoneCenter; // Center of the zone
  @override
  void initState() {
    super.initState();
    
    _mapController = MapController(); // Initialisation du MapController
    _listenToWebSocket();
  }

/*
  void _listenToWebSocket() {
    _channel.stream.listen(
      (message) {
        print("Message reçu : $message");
        try {
          final data = parseWebSocketMessage(message);

          setState(() {
            if (data['ID'] == 1) {
              mouton1Positions.add(LatLng(data['Lat'], data['Lng']));
            } else if (data['ID'] == 2) {
              mouton2Positions.add(LatLng(data['Lat'], data['Lng']));
            } else if (data['ID'] == 3) {
              mouton3Positions.add(LatLng(data['Lat'], data['Lng']));
            }
          });
        } catch (e) {
          print("Erreur lors du traitement du message WebSocket : $e");
        }
      },
      onError: (error) {
        print("Erreur WebSocket : $error");
      },
    );
  }
*/
LatLng _generateRandomPosition(LatLng currentPosition) {
  if (zoneCenter == null) return currentPosition;

  // Generate a random angle and distance within the zone radius
  double randomAngle = Math.Random().nextDouble() * 2 * Math.pi;
  double randomDistance = Math.Random().nextDouble() * zoneRadius;

  // Calculate the new position
  double newLat = zoneCenter!.latitude +
      (randomDistance / 111320) * Math.cos(randomAngle); // Approximation for latitude
  double newLng = zoneCenter!.longitude +
      (randomDistance / (111320 * Math.cos(zoneCenter!.latitude * Math.pi / 180))) *
          Math.sin(randomAngle); // Approximation for longitude

  return LatLng(newLat, newLng);
}


void _listenToWebSocket() {
  _channel.stream.listen(
    (message) {
      print("Message reçu : $message");
      try {
        final data = parseWebSocketMessage(message);

        setState(() {
          LatLng currentPosition = LatLng(data['Lat'], data['Lng']);

          // If inside the zone, add the new random movement
          if (isInsideZone(currentPosition)) {
            LatLng newPosition = _generateRandomPosition(currentPosition);

            if (data['ID'] == 1) {
              mouton1Positions.add(newPosition);
            } else if (data['ID'] == 2) {
              mouton2Positions.add(newPosition);
            } else if (data['ID'] == 3) {
              mouton3Positions.add(newPosition);
            }
          } else {
            // Ignore positions outside the zone
            print("Position outside the zone. Ignored.");
          }
        });
      } catch (e) {
        print("Erreur lors du traitement du message WebSocket : $e");
      }
    },
    onError: (error) {
      print("Erreur WebSocket : $error");
    },
  );
}

 List<LatLng> createDottedLine(List<LatLng> positions, double segmentLength) {
    List<LatLng> dottedLine = [];
    for (int i = 0; i < positions.length - 1; i++) {
      LatLng start = positions[i];
      LatLng end = positions[i + 1];

      double totalDistance = Distance().as(LengthUnit.Meter, start, end);
      int numberOfDots = (totalDistance / (segmentLength * 1000)).round();

      for (int j = 0; j <= numberOfDots; j++) {
        double t = j / numberOfDots;
        double lat = start.latitude + (end.latitude - start.latitude) * t;
        double lng = start.longitude + (end.longitude - start.longitude) * t;
        if (j % 2 == 0) { // Add every second point for a dotted effect
          dottedLine.add(LatLng(lat, lng));
        }
      }
    }
    return dottedLine;
  }
 
bool isInsideZone(LatLng position) {
  if (zoneCenter == null) return false;
  double distance = Geolocator.distanceBetween(
    zoneCenter!.latitude,
    zoneCenter!.longitude,
    position.latitude,
    position.longitude,
  );
  return distance <= zoneRadius;
}

  /// Handle map tap to select the zone center
  void _onMapTap(LatLng position) {
    setState(() {
      zoneCenter = position; // Set the center of the zone
    });

    // Show dialog to set radius after selecting the center
    _showRadiusInputDialog();
  }

  /// Show a dialog to input the zone radius
  void _showRadiusInputDialog() {
    final TextEditingController _radiusController =
        TextEditingController(text: zoneRadius.toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Zone Radius'),
          content: TextField(
            controller: _radiusController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter radius in meters',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  zoneRadius = double.tryParse(_radiusController.text) ?? 500.0;
                });
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  } 
 
  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trajectoires en temps réel'),
      ),
      drawer: _buildDrawer(context),
      body:  Stack(
         children: [
        FlutterMap(
        mapController:
            _mapController, // Utilisation du MapController pour contrôler la carte
        options: MapOptions(
          initialCenter: const LatLng(37.2785, 9.8738),
          initialZoom: 13.0,
          onTap: (tapPosition, point) => _onMapTap(point),
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
            subdomains: ['a', 'b', 'c'],
          ),
          if (zoneCenter != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: zoneCenter!, // Use the fixed zone center
                  color: Colors.blue.withOpacity(0.3),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                  radius: zoneRadius, // Radius is in meters
                ),
              ],
            ),

          // Marqueurs pour les moutons
          MarkerLayer(
            markers: [
              if (mouton1Positions.isNotEmpty)
                Marker(
                  point: mouton1Positions.last,
                  width: 30.0,
                  height: 30.0,
                  //child: (ctx) => Image.asset(
                    //'assets/sheep1.png',
                 //   width: 40,
                   // height: 40,
                 // ),
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 30.0),
                ),
              if (mouton2Positions.isNotEmpty)
                Marker(
                  point: mouton2Positions.last,
                  width: 30.0,
                  height: 30.0,
                  child: const Icon(Icons.location_on,
                      color: Colors.blue, size: 30.0),
                ),
              if (mouton3Positions.isNotEmpty)
                Marker(
                  point: mouton3Positions.last,
                  width: 30.0,
                  height: 30.0,
                  child: const Icon(Icons.location_on,
                      color: Colors.green, size: 30.0),
                ),
            ],
          ),
          
          if(_mylocation != null)
              MarkerLayer(markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: _mylocation!,
                  child: const Icon(Icons.location_on,
                  color: Colors.green,
                  size: 40,
                  )
                )
              ]),
          // Polylines pour les trajectoires des moutons
          if (mouton1Positions.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  
                  strokeWidth: 4.0,
                  color: Colors.red,
                  points: createDottedLine(mouton1Positions, 0.0002),
                ),
              ],
            ),
          if (mouton2Positions.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  
                  strokeWidth: 4.0,
                  color: Colors.blue,
                  points: createDottedLine(mouton2Positions, 0.0002),
                ),
              ],
            ),
          if (mouton3Positions.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  
                  strokeWidth: 4.0,
                  color: Colors.green,
                  points: createDottedLine(mouton3Positions, 0.0002),
                ),
              ],
            ),
        ],
        
      ),
      Positioned(
          top: 40,
          left: 15,
          right: 15,
          child: Column(
            children: [
              SizedBox(
                height: 55,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Search Place ..",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide : BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching ? IconButton(onPressed: (){
                      _searchController.clear();
                      setState(() {
                        _isSearching = false;
                        _searchResults = [];
                      });
                    }, icon: const Icon(Icons.clear)):null
                  ),
                  onTap: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
              ),
              if(_isSearching && _searchResults.isNotEmpty)
              Container(
                color: Colors.white,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (ctx, index){
                    final place = _searchResults[index];
                    return ListTile(
                      title: Text(place['display_name'],),
                      onTap: (){
                        double? lat = double.parse(place['lat']);
                        double? lon = double.parse(place['lon']);
                        _moveToLocation(lat,lon);
                      },
                    );
                  },
                  ),
              )
            ],
          ),
        ),
        //add location button
        _isDragging == false ? Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            onPressed: (){
              setState(() {
                _isDragging = true;
              });
            },
            child: const Icon(Icons.add_location),
          ),
        ) : Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            onPressed: (){
              setState(() {
                _isDragging = false;
              });
            },
            child: const Icon(Icons.wrong_location),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                onPressed: _showCurrentLocation,
                child: const Icon(Icons.location_searching_rounded),
          ),
          
            ],
          )
        ),
        _isDragging == false ? Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: (){
              setState(() {
                _isDragging = true;
              });
            },
            child: const Icon(Icons.pets),
          ),
        ) : Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: (){
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
            },
            child: Icon(Icons.pets),
          ),
          ),
         
         ],
      ),
    );
  }

  Future<Position> _determinePosition() async{
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
 
 
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
 
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are denied");
      }
    }
    if (permission == LocationPermission.denied) {
        return Future.error("Location permissions are permanently denied");
    }
    return await Geolocator.getCurrentPosition();
 
  }

  void _showCurrentLocation() async{
    try{
      Position position = await _determinePosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      _mapController.move(currentLatLng, 15.0);
      setState(() {
       
        _mylocation = currentLatLng;
      });
    }catch(e){
      print(e);
    }
  }


  Future<void> _searchPlaces(String query) async {
  if (query.isEmpty) {
    setState(() {
      _searchResults = [];
    });
    return;
  }
 
  try {
    final url = 'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5';
    final response = await http.get(Uri.parse(url));
 
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data.isNotEmpty) {
        setState(() {
          _searchResults = data;
        });
      } else {
        setState(() {
          _searchResults = [];
        });
      }
    } else {
      throw Exception('Failed to load data');
    }
  } catch (e) {
    print('Error during search: $e');
    setState(() {
      _searchResults = [];
    });
  }
}

  void _moveToLocation(double Lat, double Long){
    LatLng location = LatLng(Lat, Long);
    _mapController.move(location, 15.0);
    setState(() {
      _selectedPosition = location;
      _searchResults = [];
      _isSearching = false;
      _searchController.clear();
    });
  }



 
// hum.dart
 
void handleMarkerClick(String title, String description) {
  // For example, you could print the title and description to the console
  print("Marker clicked! Title: $title, Description: $description");
 
  // You can add additional logic here, like navigating to a new screen or updating the UI
}
 
 
  // Fonction pour parser les messages WebSocket
  Map<String, dynamic> parseWebSocketMessage(String message) {
    try {
      return json.decode(message);
    } catch (e) {
      print('Erreur de décodage du message WebSocket: $e');
      return {};
    }
  }

  // Fonction pour construire le Drawer avec un menu
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add,
                color: Colors.blue), // Icône pour "Ajouter un animal"
            title: const Text('Ajouter un animal'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.list,
                color: Colors.blue), // Icône pour "Liste des animaux"
            title: const Text('Liste des animaux'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud,
                color: Colors.blue), // Icône pour "Météo"
            title: const Text('Météo'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeatherScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat,
                color: Colors.blue), // Icône pour "Chatbot"
            title: const Text('Chatbot'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications,
                color: Colors.blue), // Icône pour "Notifications"
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language,
                color: Colors.blue), // Icône pour "Notifications"
            title: const Text('Language'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings,
                color: Colors.blue), // Icône pour "Paramètres"
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout,
                color: Colors.blue), // Icône pour "Paramètres"
            title: const Text('Deconnecter'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
        
      ),
    );
  }
}

