import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gps_data_model.dart';

class ApiService {
  final String baseUrl = "http://127.0.0.1:8000"; // Remplacez par votre URL

  Future<List<GPSData>> fetchAnimalHistory(int animalId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/history/$animalId/'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((json) => GPSData.fromJson(json)).toList();
    } else {
      throw Exception('Erreur lors du chargement des données');
    }
  }
}
