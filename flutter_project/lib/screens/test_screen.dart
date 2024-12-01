import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:geocoding/geocoding.dart'; // Ajoute cette importation


class RealTimeMapScreen extends StatefulWidget {
  const RealTimeMapScreen({super.key});

  @override
  _RealTimeMapScreenState createState() => _RealTimeMapScreenState();
}

class _RealTimeMapScreenState extends State<RealTimeMapScreen> {
  final _channel = WebSocketChannel.connect(
    Uri.parse('ws://192.168.1.18:8000/ws/track/'), // Replace with WebSocket server URL
  );

  final List<LatLng> animalPositions = []; // Combined list for all animals
  final Map<int, List<LatLng>> animalTracks = {}; // Map for animal ID and positions
  late MapController _mapController;
  final TextEditingController _searchController = TextEditingController();
  LatLng _searchLocation = const LatLng(36.752887, 10.230342); // Default center

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _listenToWebSocket();
  }

  void _listenToWebSocket() {
    _channel.stream.listen(
      (message) {
        print("Message received: $message");
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          if (data.isNotEmpty) {
            final int id = data['id'] as int;
            final LatLng position = LatLng(data['position']['lat'], data['position']['lon']);
            setState(() {
              animalPositions.add(position);
              if (animalTracks[id] == null) {
                animalTracks[id] = [];
              }
              animalTracks[id]!.add(position);
            });
          }
        } catch (e) {
          print("Error processing WebSocket message: $e");
        }
      },
      onError: (error) {
        print("WebSocket error: $error");
      },
    );
  }

void _searchLocationOnMap() async {
  if (_searchController.text.isNotEmpty) {
    try {
      // Utilisation de Nominatim pour obtenir les coordonnées à partir de l'adresse
      List<Location> locations = await locationFromAddress(_searchController.text);
      
      if (locations.isNotEmpty) {
        setState(() {
          // Mise à jour de la localisation recherchée avec les coordonnées obtenues
          _searchLocation = LatLng(locations[0].latitude, locations[0].longitude);
          _mapController.move(_searchLocation, 12.0); // Centre la carte sur la nouvelle localisation
        });
      } else {
        // Si aucune localisation n'est trouvée
        print("Aucune localisation trouvée pour cette adresse.");
      }
    } catch (e) {
      print("Erreur de géocodage: $e");
    }
  }
}

  @override
  void dispose() {
    _channel.sink.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Trajectories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _searchLocationOnMap,
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search location...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
              onSubmitted: (_) => _searchLocationOnMap(),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: FlutterMap(
        mapController: _mapController,
        options: const MapOptions(
         // center: animalPositions.isNotEmpty ? animalPositions.last : _searchLocation, // Default center
          //zoom: 9.0, // Initial zoom level
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          // Markers for all animals
          MarkerLayer(
            markers: animalPositions.map((position) {
              final int id = animalTracks.keys.firstWhere((key) => animalTracks[key]!.contains(position), orElse: () => -1);
              return Marker(
                point: position,
                width: 30.0,
                height: 30.0,
                child: animalTracks[id] != null && animalTracks[id]!.length > 10
                    ? const Icon(Icons.directions_run, color: Colors.green) // Animal en mouvement
                    : const Icon(Icons.location_on, color: Colors.blue), // Animal immobile
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Function to build the drawer menu
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
            leading: const Icon(Icons.add, color: Colors.blue),
            title: const Text('Ajouter un animal'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.list, color: Colors.blue),
            title: const Text('Liste des animaux'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud, color: Colors.blue),
            title: const Text('Météo'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat, color: Colors.blue),
            title: const Text('Chatbot'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.blue),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blue),
            title: const Text('Language'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Colors.blue),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.blue),
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
