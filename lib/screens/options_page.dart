// lib/pages/optionsPage.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'project_detail_page.dart';
import '../prompts/options_prompt.dart';
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

  static const String apiKey =
      ApiConfig.openAiApiKey; // ← Usa

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

  // Convierte la respuesta de la API en un texto plano que el prompt entienda
  String _formatearParaPrompt(Map<String, dynamic> apiData) {
    final buf = StringBuffer();

    // Añadir datos del agricultor (esencial para la validación)
    buf.writeln('ÁREA: ${widget.area} ${widget.unidad}');
    buf.writeln('PRESUPUESTO: ${widget.presupuesto} COP');

    final clima = apiData['clima']?['data'];
    if (clima != null) {
      buf.writeln('CLIMA ACTUAL:');
      buf.writeln(
        'Temp: ${clima['current']?['temperature']}°C, Hum: ${clima['current']?['humidity']}%, Precip: ${clima['daily']?['precipitation_sum']}mm, ET0: ${clima['daily']?['evapotranspiration']}mm',
      );
    }

    final suelo = apiData['suelo']?['data'];
    if (suelo != null) {
      buf.writeln(
        'SUELO (0-5cm): pH ${suelo['ph']}, Arcilla ${suelo['clay']}%, Arena ${suelo['sand']}%',
      );
    }

    final insumos = apiData['insumos']?['data'];
    if (insumos != null) {
      buf.writeln(
        'ÍNDICE INSUMOS (base 100): Total ${insumos['indice_total']}, Fertilizantes ${insumos['total_fertilizantes']}, Plaguicidas ${insumos['total_plaguicidas']}',
      );
    }

    final precios = apiData['precios_mercado']?['por_grupo'];
    if (precios != null) {
      buf.writeln('PRECIOS PROMEDIO (COP/kg):');
      precios.forEach((grupo, datos) {
        final stats = datos['estadisticas'];
        if (stats != null && stats['total_productos'] > 0) {
          buf.writeln(
            '- $grupo: prom ${stats['precio_promedio_grupo']}, más caro ${stats['producto_mas_caro']} (${stats['precio_mas_caro']}), más barato ${stats['producto_mas_barato']} (${stats['precio_mas_barato']})',
          );
        }
      });
    }

    return buf.toString();
  }

  // Genera las opciones con el prompt, incluyendo datos reales si existen
  Future<void> generarOpciones() async {
    try {
      String? datosRendimiento;
      if (datosAnalisis != null) {
        datosRendimiento = _formatearParaPrompt(datosAnalisis!);
      }

      final prompt = OptionsPrompt.build(
        departamento: widget.departamento,
        municipio: widget.municipio,
        presupuesto: widget.presupuesto,
        area: widget.area,
        unidad: widget.unidad,
        tipoTerreno: widget.tipoTerreno,
        datosAnalisis: datosRendimiento, // ← antes era "datosRendimiento"
      );

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.3,
          "max_tokens": 150,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final contenido = data['choices'][0]['message']['content'] as String;

        final lista = contenido
            .split('\n')
            .where((linea) => linea.trim().isNotEmpty)
            .map((linea) => linea.trim())
            .toList();

        setState(() {
          opciones = lista.take(5).toList();
          cargando = false;
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
