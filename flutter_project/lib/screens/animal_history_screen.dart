import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;

class AnimalHistoryPage extends StatefulWidget {
  const AnimalHistoryPage({Key? key}) : super(key: key);

  @override
  _AnimalHistoryPageState createState() => _AnimalHistoryPageState();
}

class _AnimalHistoryPageState extends State<AnimalHistoryPage> {
  late Future<List<Map<String, dynamic>>> _historyData;

  @override
  void initState() {
    super.initState();
    _historyData = fetchAllAnimalHistories(); // Appel API pour tous les animaux
  }

  /// Appel API pour récupérer l'historique de tous les animaux
  Future<List<Map<String, dynamic>>> fetchAllAnimalHistories() async {
    const String url = 'http://192.168.1.18:8000/api/animals/history/'; // Remplacez avec votre IP
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.map((item) {
        return {
          'id': item['_id'],
          'name': item['name'],
          'gps_history': item['gps_history'], // Liste des historiques GPS
        };
      }).toList();
    } else {
      throw Exception('Failed to load all animal histories');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Animaux'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Aucune donnée disponible'));
          } else {
            final data = snapshot.data!;
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return ListTile(
                        title: Text("Animal: ${item['name']}"),
                        subtitle: Text("ID: ${item['id']}"),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: _buildCharts(data),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  /// Génère un graphique pour afficher les données GPS de chaque animal
  Widget _buildCharts(List<Map<String, dynamic>> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final animal = data[index];
        final gpsHistory = animal['gps_history'] as List<dynamic>;

        final seriesList = [
          charts.Series<dynamic, DateTime>(
            id: animal['name'],
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            domainFn: (data, _) => DateTime.parse(data['timestamp']),
            measureFn: (data, _) =>
                data['latitude'], // Afficher la latitude sur l'axe Y
            data: gpsHistory,
          ),
        ];

        return Column(
          children: [
            Text("Animal: ${animal['name']}"),
            SizedBox(
              height: 200,
              child: charts.TimeSeriesChart(
                seriesList,
                animate: true,
                dateTimeFactory: const charts.LocalDateTimeFactory(),
                primaryMeasureAxis: const charts.NumericAxisSpec(),
              ),
            ),
          ],
        );
      },
    );
  }
}
