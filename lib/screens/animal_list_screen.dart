import 'package:flutter/material.dart';
import '../models/animal.dart';

class AnimalListScreen extends StatelessWidget {
  const AnimalListScreen({super.key});

  static List<Animal> animals = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Animal List"),
      ),
      body: ListView.builder(
        itemCount: animals.length,
        itemBuilder: (context, index) {
          final animal = animals[index];
          return ListTile(
            title: Text(animal.name),
            subtitle: Text("Age: ${animal.age}, Color: ${animal.color}"),
            onTap: () {
              // Action lorsqu'on clique sur un animal
            },
          );
        },
      ),
    );
  }
}
