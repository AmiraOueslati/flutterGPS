import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/animal.dart';

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  _AddAnimalScreenState createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();

  // Listes des choix pour type et espèce
  final List<String> _animalTypes = ['Chat', 'Chien', 'Mouton'];
  final List<String> _species = ['Mammifère', 'Oiseau', 'Reptile'];
  
  String? _selectedType;
  String? _selectedSpecies;

  Future<void> _saveAnimalProfile() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an animal type')),
        );
        return;
      }

      if (_selectedSpecies == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an animal species')),
        );
        return;
      }

      String id = _idController.text;
      String name = _nameController.text;
      String age = _ageController.text;
      String color = _colorController.text;

      Animal newAnimal = Animal(
        id: id,
        name: name,
        age: age,
        color: color,
        type: _selectedType!,
        species: _selectedSpecies!,  // Ajouter l'espèce
      );

      await _addAnimalToApi(newAnimal);
    }
  }

  Future<void> _addAnimalToApi(Animal animal) async {
    try {
      final url = Uri.parse('http://your-api-url.com/animals/add'); // Remplacez par l'URL de votre API
      final headers = {'Content-Type': 'application/json'};
      final body = jsonEncode(animal.toJson());

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Animal added successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add animal')),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error adding animal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Animal Profile"),
        backgroundColor: Colors.teal[400],
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Sélection du type d'animal
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                  items: _animalTypes
                      .map((type) => DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Animal Type'),
                  validator: (value) => value == null ? 'Please select an animal type' : null,
                ),
                const SizedBox(height: 20),
                // Sélection de l'espèce de l'animal
                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  onChanged: (value) {
                    setState(() {
                      _selectedSpecies = value;
                    });
                  },
                  items: _species
                      .map((species) => DropdownMenuItem<String>(
                            value: species,
                            child: Text(species),
                          ))
                      .toList(),
                  decoration: const InputDecoration(labelText: 'Species'),
                  validator: (value) => value == null ? 'Please select an animal species' : null,
                ),
                const SizedBox(height: 20),
                // Champs de formulaire pour ID, nom, âge, couleur
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(labelText: 'Animal ID'),
                  validator: (value) => value!.isEmpty ? 'Please enter an ID' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Animal Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Animal Age'),
                  validator: (value) => value!.isEmpty ? 'Please enter an age' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(labelText: 'Animal Color'),
                  validator: (value) => value!.isEmpty ? 'Please enter a color' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveAnimalProfile,
                  child: const Text("Save Profile"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
