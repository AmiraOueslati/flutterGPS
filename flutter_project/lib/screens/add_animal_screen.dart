import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';


class AddAnimalScreen extends StatefulWidget {
  @override
  _AddAnimalScreenState createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _nameController = TextEditingController();
  final _speciesController = TextEditingController();
  final _ageController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  Future<void> _addAnimal() async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1/api/animals/'),  // Remplacez par l'URL de votre serveur Django
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _nameController.text,
        'species': _speciesController.text,
        'age': int.parse(_ageController.text),
        'location_lat': double.parse(_latController.text),
        'location_lon': double.parse(_lonController.text),
      }),
    );

    if (response.statusCode == 201) {
      // Animal ajouté avec succès
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Animal ajouté avec succès')));
    } else {
      // Erreur
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors de l\'ajout de l\'animal')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter un Animal")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Nom de l\'animal'),
            ),
            TextField(
              controller: _speciesController,
              decoration: InputDecoration(labelText: 'Espèce'),
            ),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: 'Âge'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _latController,
              decoration: InputDecoration(labelText: 'Latitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            TextField(
              controller: _lonController,
              decoration: InputDecoration(labelText: 'Longitude'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addAnimal,
              child: Text('Ajouter l\'Animal'),
            ),
          ],
        ),
      ),
    );
  }
}
