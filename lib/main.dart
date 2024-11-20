import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Feriados de Chile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FeriadosScreen(),
    );
  }
}

class FeriadosScreen extends StatefulWidget {
  const FeriadosScreen({super.key});

  @override
  _FeriadosScreenState createState() => _FeriadosScreenState();
}

class _FeriadosScreenState extends State<FeriadosScreen> {
  List<Feriado> feriados = [];
  bool isLoading = true;
  Feriado? feriadoMasCercano;
  int currentYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    fetchFeriados(currentYear);
  }

  Future<void> fetchFeriados(int year) async {
    final url = Uri.parse('https://apis.digital.gob.cl/fl/feriados/$year');
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          feriados = data
              .map((json) => Feriado.fromJson(json))
              .toList()
            ..sort((a, b) => a.fecha.compareTo(b.fecha));

          feriadoMasCercano = obtenerFeriadoMasCercano(feriados);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load holidays');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar los feriados: $e')),
      );
    }
  }

  Feriado obtenerFeriadoMasCercano(List<Feriado> feriados) {
    final hoy = DateTime.now();
    return feriados.firstWhere(
          (feriado) => feriado.fecha.isAfter(hoy),
      orElse: () => feriados.last,// Devuelve el último feriado si no hay futuros
    );
  }

  void mostrarDetallesFeriado(BuildContext context, Feriado feriado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(feriado.nombre),
          content: Text(
            'Fecha: ${feriado.fecha.day}/${feriado.fecha.month}/${feriado.fecha.year}\n'
                'Comentarios: ${feriado.comentarios}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
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
        title: const Text('Feriados de Chile'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      currentYear--;
                      fetchFeriados(currentYear);
                    });
                  },
                ),
                Text(
                  '$currentYear',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: currentYear < 2024
                      ? () {
                    setState(() {
                      currentYear++;
                      fetchFeriados(currentYear);
                    });
                  }
                      : null,
                ),
              ],
            ),
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: feriados.length + 1,
              itemBuilder: (context, index) {
                if (index == 0 && feriadoMasCercano != null) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.
                      blueAccent, width: 2),
                    ),
                    child: ListTile(
                      title: Text(
                        'Feriado Más Cercano',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${feriadoMasCercano!.nombre}\n${feriadoMasCercano!.fecha.day}/${feriadoMasCercano!.fecha.month}/${feriadoMasCercano!.fecha.year}',
                      ),
                      onTap: () =>
                          mostrarDetallesFeriado(context, feriadoMasCercano!),
                    ),
                  );
                }

                final feriado = feriados[index - 1]; // Ajustar índice
                return GestureDetector(
                  onTap: () => mostrarDetallesFeriado(context, feriado),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      title: Text(feriado.nombre),
                      subtitle: Text(
                        '${feriado.fecha.day}/${feriado.fecha.month}/${feriado.fecha.year}',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Feriado {
  final String nombre;
  final DateTime fecha;
  final String comentarios;

  Feriado({
    required this.nombre,
    required this.fecha,
    required this.comentarios,
  });

  factory Feriado.fromJson(Map<String, dynamic> json) {
    return Feriado(
      nombre: json['nombre'],
      fecha: DateTime.parse(json['fecha']),
      comentarios: json['comentarios'] ?? 'Sin comentarios disponibles',
    );
  }
}
