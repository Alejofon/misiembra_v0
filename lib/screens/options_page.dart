// lib/pages/optionsPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'project_detail_page.dart';
import '../services/api_misiembra_service.dart';
import '../config/api_config.dart';

class OptionsPage extends StatefulWidget {
  final String presupuesto;
  final String area;
  final String unidad;
  final String? tipoTerreno;
  final String departamento;
  final String municipio;
  final double? lat;
  final double? lon;
  final Map<String, dynamic>? proveedoresInsumos;

  const OptionsPage({
    super.key,
    required this.presupuesto,
    required this.area,
    required this.unidad,
    this.tipoTerreno,
    required this.departamento,
    required this.municipio,
    this.lat,
    this.lon,
    this.proveedoresInsumos,
  });

  @override
  State<OptionsPage> createState() => _OptionsPageState();
}

class _OptionsPageState extends State<OptionsPage> {
  bool cargando = true;
  List<String> opciones = [];
  String? error;
  Map<String, dynamic>? datosAnalisis; // Guarda la respuesta completa de la API

  @override
  void initState() {
    super.initState();
    _iniciarProceso();
  }

  // 1. Obtener datos de la API (si hay coordenadas) y luego generar opciones
  // En lib/pages/optionsPage.dart, dentro de _OptionsPageState
  Future<void> _iniciarProceso() async {
    try {
      List<Future> futures = [];

      // 1. Obtener análisis de terreno (si hay coordenadas)
      if (widget.lat != null && widget.lon != null) {
        futures.add(
          ApiMiSiembraService.fetchAnalisisTerreno(
            lat: widget.lat!,
            lon: widget.lon!,
            departamento: widget.departamento,
            municipio: widget.municipio,
          ).then((data) => datosAnalisis = data),
        );

        // 2. Obtener proveedores de insumos (NUEVO)
        futures.add(
          ApiMiSiembraService.buscarInsumos(
            lat: widget.lat!,
            lon: widget.lon!,
          ).then(
            (data) => proveedoresInsumos = data,
          ), // Guardamos los proveedores
        );
      }

      // 3. Esperar a que ambas peticiones terminen
      await Future.wait(futures);

      // 4. Generar las recomendaciones con los datos obtenidos
      await generarOpciones();
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'Error al obtener datos: $e';
      });
    }
  }


  Map<String, dynamic>? proveedoresInsumos;

  // Genera las opciones llamando al backend, que busca candidatos con datos
  // reales (búsqueda web restringida a fuentes agrícolas confiables),
  // calcula la rentabilidad de cada uno con el presupuesto/área reales, y
  // solo devuelve los que efectivamente son viables. Ya no arma ningún
  // prompt aquí ni llama a OpenAI directamente.
  Future<void> generarOpciones() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/opciones-cultivo'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "departamento": widget.departamento,
          "municipio": widget.municipio,
          "lat": widget.lat,
          "lon": widget.lon,
          "presupuesto": widget.presupuesto,
          "area": widget.area,
          "unidad": widget.unidad,
          "tipo_terreno": widget.tipoTerreno,
          "datos_analisis": datosAnalisis,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final lista = (data['opciones'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();

        setState(() {
          opciones = lista;
          cargando = false;
          if (lista.isEmpty) {
            error = data['mensaje'] as String? ??
                'No se encontraron cultivos viables para estos parámetros.';
          }
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'No se pudieron generar recomendaciones: $e';
      });
    }
  }

  // Guarda la selección en historial (sin cambios)
  void _guardarEnHistorial(String cultivoSeleccionado) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> historialActual = prefs.getStringList('historial') ?? [];

    final String nuevaRecomendacion = jsonEncode({
      'fecha': DateTime.now().toIso8601String(),
      'cultivo': cultivoSeleccionado,
      'departamento': widget.departamento,
      'municipio': widget.municipio,
      'presupuesto': widget.presupuesto,
      'area': '${widget.area} ${widget.unidad}',
      'terreno': widget.tipoTerreno ?? 'No especificado',
    });

    historialActual.insert(0, nuevaRecomendacion);
    if (historialActual.length > 20) historialActual.removeLast();
    await prefs.setStringList('historial', historialActual);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opciones de siembra'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(error!),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              cargando = true;
                              error = null;
                              _iniciarProceso();
                            });
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: opciones.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _guardarEnHistorial(opciones[index]);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProjectDetailPage(
                                  cultivo: opciones[index],
                                  zona:
                                      '${widget.departamento} - ${widget.municipio}',
                                  presupuesto: widget.presupuesto,
                                  area: widget.area,
                                  unidad: widget.unidad,
                                  departamento: widget.departamento,
                                  municipio: widget.municipio,
                                  tipoTerreno: widget.tipoTerreno,
                                  datosAnalisis: datosAnalisis,
                                  proveedoresInsumos: proveedoresInsumos,
                                  lat: widget.lat, 
                                  lon: widget.lon,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              opciones[index],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}