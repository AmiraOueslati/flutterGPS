import 'dart:convert';

import 'package:flutter_project/screens/marker_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

 
 
 
 
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
 
  @override
  State<MapScreen> createState() => _MapScreenState();
}
 
class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<MarkerData> _markerData = [];
  final List<Marker> _markers = [];
  LatLng? _selectedPosition;
  LatLng? _mylocation;
  LatLng? _draggedPosition;
  bool _isDragging = false;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
 
 
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
 
 
 
 
Future<void> _addMarker(LatLng position, String title, String description) async {
  final user = FirebaseAuth.instance.currentUser;
 
  if (user == null) {
    print("No user logged in. Cannot save marker.");
    return;
  }
 
  // Create a MarkerData instance
  final markerData = MarkerData(
    position: position,
    title: title,
    description: description,
  );
 
  // Save marker data to Firestore
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .add({
      'title': title,
      'description': description,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    });
 
    print("Marker saved to Firestore under user's account");
 
    // Add the marker to the UI immediately
    setState(() {
      _markerData.add(markerData);
      _markers.add(
        Marker(
          point: position,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showMarkerInfo(context, markerData),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  constraints: const BoxConstraints(maxWidth: 80),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.location_on,
                  color: Colors.redAccent,
                  size: 40,
                ),
              ],
            ),
          ),
        ),
      );
    });
  } catch (e) {
    print("Error saving marker to Firestore: $e");
  }
}
 
 
void _deleteMarker(MarkerData markerData) async {
  final user = FirebaseAuth.instance.currentUser;
 
  if (user == null) {
    print("No user logged in. Cannot delete marker.");
    return;
  }
 
  try {
    // Query Firestore to find the marker document to delete
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .where('latitude', isEqualTo: markerData.position.latitude)
        .where('longitude', isEqualTo: markerData.position.longitude)
        .get();
 
    for (var doc in querySnapshot.docs) {
      await doc.reference.delete(); // Delete the document
    }
 
    print("Marker deleted from Firestore.");
  } catch (e) {
    print("Error deleting marker from Firestore: $e");
  }
 
  // Remove the marker from the local state
  setState(() {
    _markerData.remove(markerData);
    _markers.removeWhere((marker) => marker.point == markerData.position);
  });
}
 
 
void _showMarkerInfo(BuildContext context, MarkerData markerData) {
  final TextEditingController titleController =
      TextEditingController(text: markerData.title);
  final TextEditingController descController =
      TextEditingController(text: markerData.description);
 
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text("Marker Info"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row with Close, Save, and Delete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    _editMarker(markerData, titleController.text,
                        descController.text); // Save changes
                    Navigator.pop(context); // Close the dialog after editing
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    _deleteMarker(markerData); // Delete the marker
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 10), // Space between buttons
            // More About button
            ElevatedButton(
              style: ElevatedButton.styleFrom(elevation: 10),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => const CptPage(),
                  ),
                );
              },
              child: const Text("More About"),
            ),
          ],
        ),
      ],
    ),
  );
}
 
void _editMarker(MarkerData markerData, String newTitle, String newDescription) async {
  final user = FirebaseAuth.instance.currentUser;
 
  if (user == null) {
    print("No user logged in. Cannot edit marker.");
    return;
  }
 
  try {
    // Query Firestore to find the marker document to update
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .where('latitude', isEqualTo: markerData.position.latitude)
        .where('longitude', isEqualTo: markerData.position.longitude)
        .get();
 
    for (var doc in querySnapshot.docs) {
      await doc.reference.update({
        'title': newTitle,
        'description': newDescription,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
 
    print("Marker updated in Firestore.");
  } catch (e) {
    print("Error updating marker in Firestore: $e");
  }
 
  // Update the marker in the local state
  setState(() {
    markerData.title = newTitle;
    markerData.description = newDescription;
  });
}
 
 
 
  void _showMarkerDialog(BuildContext context, LatLng position){
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
 
    showDialog(
      context: context,
       builder: (context) => AlertDialog(
        title: const Text('Add Marker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions:[
          TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: (){
              _addMarker(position, titleController.text, descController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
       )
       );
  }
 
 
 
 
// hum.dart
 
void handleMarkerClick(String title, String description) {
  // For example, you could print the title and description to the console
  print("Marker clicked! Title: $title, Description: $description");
 
  // You can add additional logic here, like navigating to a new screen or updating the UI
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
 
@override
void initState() {
  super.initState();
  _loadMarkers(); // Load markers when the screen is initialized
}
 
 
void _loadMarkers() async {
  final user = FirebaseAuth.instance.currentUser;
 
  if (user == null) {
    print("No user logged in. Cannot load markers.");
    return;
  }
 
  try {
    // Fetch markers from Firestore for the current user
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('markers')
        .get();
 
    setState(() {
      _markerData.clear();  // Clear previous markers
      _markers.clear();     // Clear the map markers
 
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final markerData = MarkerData(
          position: LatLng(data['latitude'], data['longitude']),
          title: data['title'],
          description: data['description'],
        );
 
        _markerData.add(markerData);
        _markers.add(
          Marker(
            point: markerData.position,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () => _showMarkerInfo(context, markerData),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    constraints: const BoxConstraints(maxWidth: 80),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      markerData.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
 
    print("Markers loaded for the user");
  } catch (e) {
    print("Error loading markers: $e");
  }
}
 
 
 
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(36.8065, 10.1815), // Coordinates for Tunis, Tunisia
              initialZoom: 13.0,
              onTap: (tapPosition, LatLng) {
                _selectedPosition = LatLng;
                _draggedPosition = _selectedPosition;
 
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              MarkerLayer(markers: _markers),
              if(_isDragging && _draggedPosition != null)
              MarkerLayer(markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: _draggedPosition!,
                  child: const Icon(Icons.location_on,
                  color: Colors.indigo,
                  size: 40,
                  )
                )
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
              ]
              ),
              // Adding PolygonLayer to highlight a zone
           
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
          if(_isDragging)
          Padding(padding: const EdgeInsets.only(top: 20),
           child: FloatingActionButton(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onPressed: (){
              if(_draggedPosition != null){
                _showMarkerDialog(context, _draggedPosition!);
              }
              setState(() {
                _isDragging = false;
                _draggedPosition = null;
              });
            },
            child: const Icon(Icons.check),
            ),
          )
            ],
          )
        ),
        ],
      ),
    );
  }
}