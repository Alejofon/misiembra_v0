// lib/pages/project_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../prompts/project_detail_prompt.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart'; 

class ProjectDetailPage extends StatefulWidget {
  final String cultivo;
  final String zona;
  final String presupuesto;
  final String area;
  final String unidad;
  final String departamento;
  final String municipio;
  final String? tipoTerreno;
  final Map<String, dynamic>? datosAnalisis;
  final Map<String, dynamic>? proveedoresInsumos;
  final double? lat; // ← NUEVO
  final double? lon;

  const ProjectDetailPage({
    super.key,
    required this.cultivo,
    required this.zona,
    required this.presupuesto,
    required this.area,
    required this.unidad,
    required this.departamento,
    required this.municipio,
    this.tipoTerreno,
    this.datosAnalisis,
    this.proveedoresInsumos,
    this.lon,
    this.lat,
  });

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  bool cargando = true;
  String? error;
  Map<String, dynamic>? datosProyecto;

  static const String apiKey = ApiConfig.openAiApiKey;
  @override
  void initState() {
    super.initState();
    _generarPlanDetallado();
  }

  // Prepara los textos con datos de clima/suelo (rendimiento) e insumos (precios)

  String _formatearDatosAnalisis() {
    final buf = StringBuffer();
    if (widget.datosAnalisis == null) return '';
    final data = widget.datosAnalisis!;

    final clima = data['clima']?['data'];
    if (clima != null) {
      buf.writeln(
        'CLIMA: Temp ${clima['current']?['temperature']}°C, Hum ${clima['current']?['humidity']}%, Precip ${clima['daily']?['precipitation_sum']}mm',
      );
    }

    final suelo = data['suelo']?['data'];
    if (suelo != null) {
      buf.writeln(
        'SUELO: pH ${suelo['ph']}, Arcilla ${suelo['clay']}%, Arena ${suelo['sand']}%',
      );
    }

    final insumos = data['insumos']?['data'];
    if (insumos != null) {
      buf.writeln(
        'ÍNDICE INSUMOS: Total ${insumos['indice_total']}, Fertilizantes ${insumos['total_fertilizantes']}, Plaguicidas ${insumos['total_plaguicidas']}',
      );
    }

    final precios = data['precios_mercado']?['por_grupo'];
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

  Future<void> _generarPlanDetallado() async {
    try {
      final datosAnalisis = _formatearDatosAnalisis();

      final prompt = ProjectDetailPrompt.build(
        cultivo: widget.cultivo,
        departamento: widget.departamento,
        municipio: widget.municipio,
        presupuesto: widget.presupuesto,
        area: widget.area,
        unidad: widget.unidad,
        tipoTerreno: widget.tipoTerreno,
        datosAnalisis: datosAnalisis.isNotEmpty ? datosAnalisis : null,
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
          "temperature": 0.5,
          "max_tokens": 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String contenido = data['choices'][0]['message']['content'];
        contenido = contenido.trim();
        if (contenido.startsWith('```json')) {
          contenido = contenido.replaceAll('```json', '').replaceAll('```', '');
        }
        if (contenido.startsWith('```')) {
          contenido = contenido.replaceAll('```', '');
        }

        final Map<String, dynamic> plan = jsonDecode(contenido);
        setState(() {
          datosProyecto = plan;
          cargando = false;
        });
      } else {
        throw Exception('Error ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = 'Error generando el plan: $e';
      });
    }
  }

  // Métodos auxiliares (sin cambios)
  Map<String, dynamic> _safeMap(dynamic value) =>
      value is Map<String, dynamic> ? value : {};
  List<dynamic> _safeList(dynamic value) => value is List<dynamic> ? value : [];
  String _safeString(dynamic value, [String defaultValue = 'No disponible']) {
    if (value == null) return defaultValue;
    if (value is String) return value.isEmpty ? defaultValue : value;
    return value.toString();
  }

  Color _getColorRentabilidad(String nivel) {
    if (nivel == "Alta") return Colors.green;
    if (nivel == "Media") return Colors.orange;
    return Colors.red;
  }

  Color _getColorDificultad(String nivel) {
    if (nivel == "Baja") return Colors.green;
    if (nivel == "Media") return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("📋 Plan: ${widget.cultivo}"),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(error!, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            cargando = true;
                            error = null;
                            _generarPlanDetallado();
                          });
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : DefaultTabController(
                  length: 6,
                  child: Column(
                    children: [
                      Container(
                        color: Colors.green.shade50,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _resumenChip(
                              Icons.trending_up,
                              "Rentabilidad",
                              _safeString(
                                _safeMap(
                                    datosProyecto!['rentabilidad'])['nivel'],
                                'N/A',
                              ),
                              _getColorRentabilidad(
                                _safeString(
                                  _safeMap(
                                      datosProyecto!['rentabilidad'])['nivel'],
                                  '',
                                ),
                              ),
                            ),
                            _resumenChip(
                              Icons.speed,
                              "Dificultad",
                              _safeString(
                                _safeMap(datosProyecto!['dificultad'])['nivel'],
                                'N/A',
                              ),
                              _getColorDificultad(
                                _safeString(
                                  _safeMap(
                                      datosProyecto!['dificultad'])['nivel'],
                                  '',
                                ),
                              ),
                            ),
                            _resumenChip(
                              Icons.timeline,
                              "Cosecha",
                              _safeString(
                                _safeMap(
                                  datosProyecto!['tiempos'],
                                )['cosecha_meses'],
                                'N/A',
                              ),
                              Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const TabBar(
                        isScrollable: true,
                        tabs: [
                          Tab(
                              icon: Icon(Icons.attach_money),
                              text: "Rentabilidad"),
                          Tab(
                              icon: Icon(Icons.calendar_month),
                              text: "Tiempos"),
                          Tab(icon: Icon(Icons.bug_report), text: "Plagas"),
                          Tab(icon: Icon(Icons.store), text: "Mercado"),
                          Tab(
                              icon: Icon(Icons.local_shipping),
                              text: "Proveedores"),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _RentabilidadTab(
                              data: _safeMap(datosProyecto!['rentabilidad']),
                              beneficios:
                                  _safeList(datosProyecto!['beneficios']),
                            ),
                            _TiemposTab(
                                data: _safeMap(datosProyecto!['tiempos'])),
                            _PlagasTab(
                                data: _safeList(datosProyecto!['plagas'])),
                            _MercadoTab(
                                data: _safeMap(datosProyecto!['mercado'])),
                            _ProveedoresTab(
                              proveedoresData: widget.proveedoresInsumos,
                              lat: widget.lat, // <--- añade esto
                              lon: widget.lon, // <--- añade esto
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _resumenChip(IconData icon, String label, String valor, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}



// ====================== PESTAÑAS ======================

class _RentabilidadTab extends StatelessWidget {
  final Map<String, dynamic> data;
  final List<dynamic> beneficios;

  const _RentabilidadTab({required this.data, required this.beneficios});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rentabilidad',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...data.entries.map(
          (entry) => ListTile(
            title: Text(entry.key),
            subtitle: Text(entry.value.toString()),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Beneficios',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...beneficios.map(
          (beneficio) => ListTile(title: Text(beneficio.toString())),
        ),
      ],
    );
  }
}

class _TiemposTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TiemposTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Tiempos',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...data.entries.map(
          (entry) => ListTile(
            title: Text(entry.key),
            subtitle: Text(entry.value.toString()),
          ),
        ),
      ],
    );
  }
}

class _ProveedoresTab extends StatelessWidget {
  final Map<String, dynamic>? proveedoresData;
  final double? lat;
  final double? lon;

  const _ProveedoresTab({
    required this.proveedoresData,
    this.lat,
    this.lon,
  });

  @override
  Widget build(BuildContext context) {
    final bool hayCoordenadas = lat != null && lon != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Botón principal para abrir Google Maps con búsqueda
        if (hayCoordenadas) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.map),
            label: const Text('Buscar insumos en Google Maps'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              final uri = Uri.parse(
                'https://www.google.com/maps/search/insumos+agropecuarios/@$lat,$lon,14z',
              );
              launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Proveedores cercanos encontrados:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],

        // Lista de proveedores (si hay)
        if (proveedoresData == null || proveedoresData!['data'] == null)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Información de proveedores no disponible."),
          )
        else if ((proveedoresData!['data'] as List).isEmpty)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("No se encontraron tiendas cercanas."),
            subtitle:
                Text("Usa el botón de arriba para buscar en Google Maps."),
          )
        else
          ...(proveedoresData!['data'] as List).map((prov) {
            final nombre = prov['nombre'] ?? 'Tienda sin nombre';
            final direccion = prov['direccion'] ?? '';
            final mapsLink = prov['maps_link'] ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.store, color: Colors.green),
                title: Text(nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: direccion.isNotEmpty ? Text(direccion) : null,
                trailing: mapsLink.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.directions, color: Colors.blue),
                        onPressed: () {
                          launchUrl(Uri.parse(mapsLink),
                              mode: LaunchMode.externalApplication);
                        },
                      )
                    : null,
              ),
            );
          }).toList(),
      ],
    );
  }
}


class _PlagasTab extends StatelessWidget {
  final List<dynamic> data;

  const _PlagasTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Plagas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...data.map((plaga) => ListTile(title: Text(plaga.toString()))),
      ],
    );
  }
}

class _MercadoTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MercadoTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Mercado',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...data.entries.map(
          (entry) => ListTile(
            title: Text(entry.key),
            subtitle: Text(entry.value.toString()),
          ),
        ),
      ],
    );
  }
}
